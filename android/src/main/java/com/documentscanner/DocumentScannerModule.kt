package com.documentscanner

import android.app.Activity
import android.content.Intent
import com.facebook.react.bridge.*
import com.google.mlkit.vision.documentscanner.GmsDocumentScannerOptions
import com.google.mlkit.vision.documentscanner.GmsDocumentScanning
import com.google.mlkit.vision.documentscanner.GmsDocumentScanningResult
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.tasks.await

/**
 * Native module for Document Scanner.
 * Handles the communication between React Native and the Android ML Kit Document Scanner.
 * Implements ActivityEventListener to handle the result of the native scanner activity.
 */
class DocumentScannerModule(reactContext: ReactApplicationContext) :
  NativeDocumentScannerSpec(reactContext), ActivityEventListener {

  private var scanPromise: Promise? = null
  private var currentScanOptions: ScanOptions? = null
  private val scope = CoroutineScope(Dispatchers.Main)
  private val imageProcessor = ImageProcessor(reactContext)

  init {
    reactContext.addActivityEventListener(this)
  }

  override fun getName(): String {
    return NAME
  }

  /**
   * launches the ML Kit Document Scanner activity.
   *
   * @param options Dictionary containing scan configuration (maxPageCount, quality, format, etc.)
   * @param promise React Native promise to resolve with results or reject with error
   */
  override fun scanDocuments(options: ReadableMap?, promise: Promise) {
    val activity: Activity? = reactApplicationContext.currentActivity
    if (activity == null) {
      val error = ScannerError.OperationFailed("Activity doesn't exist")
      promise?.reject(error.code, error.message)
      return
    }

    // Prevent concurrent scans to ensure state integrity
    if (scanPromise != null) {
      val error = ScannerError.OperationFailed("A scan is already in progress")
      promise?.reject(error.code, error.message)
      return
    }

    scanPromise = promise
    
    try {
      // Parse options using strongly-typed helper
      val scanOptions = ScanOptions.from(options)
      currentScanOptions = scanOptions
      Logger.log("Starting scanDocuments with options: MaxPages=${scanOptions.maxPageCount}, Quality=${scanOptions.quality}")

      // Configure GmsDocumentScannerOptions
      // We always request JPEG + PDF to provide maximum flexibility in post-processing,
      // though we currently prioritize JPEG for React Native consumption.
      val scannerOptionsBuilder = GmsDocumentScannerOptions.Builder()
        .setScannerMode(GmsDocumentScannerOptions.SCANNER_MODE_FULL)
        .setResultFormats(GmsDocumentScannerOptions.RESULT_FORMAT_JPEG)
        .setGalleryImportAllowed(true)

      if (scanOptions.maxPageCount > 0) {
        scannerOptionsBuilder.setPageLimit(scanOptions.maxPageCount)
      }

      // Initialize the scanner client
      val scanner = GmsDocumentScanning.getClient(scannerOptionsBuilder.build())
      
      // Launch the scanner intent
      scanner.getStartScanIntent(activity)
        .addOnSuccessListener(activity) { intentSender ->
          try {
            activity.startIntentSenderForResult(intentSender, START_SCAN_REQUEST_CODE, null, 0, 0, 0)
          } catch (e: Exception) {
            val error = ScannerError.OperationFailed("Failed to start scanner activity: ${e.message}")
            Logger.error(error.message, e)
            scanPromise?.reject(error.code, error.message)
            scanPromise = null
          }
        }
        .addOnFailureListener { e ->
          val error = ScannerError.OperationFailed("Failed to launch scanner client: ${e.message}")
          Logger.error(error.message, e)
          scanPromise?.reject(error.code, error.message)
          scanPromise = null
        }

    } catch (e: Exception) {
      // Catch-all for configuration or unexpected runtime errors during setup
      val error = ScannerError.ConfigurationError(e.message ?: "Unknown error")
      Logger.error(error.message, e)
      scanPromise?.reject(error.code, error.message)
      scanPromise = null
    }
  }

  /**
   * Processes existing images (e.g., from Gallery) with the same pipeline as scanned documents.
   * Applying filters, resizing, compression, and OCR.
   *
   * @param options Dictionary containing input images and processing configuration.
   * @param promise React Native promise to resolve with results.
   */
  override fun processDocuments(options: ReadableMap?, promise: Promise) {
    val processOptions = ProcessOptions.from(options)
    
    // Validate inputs immediately
    if (processOptions.images.isEmpty()) {
        val error = ScannerError.ConfigurationError("No images provided to process")
        promise?.reject(error.code, error.message)
        return
    }

    Logger.log("Starting processDocuments with ${processOptions.images.size} images")

    // Launch coroutine for background processing to avoid blocking the UI thread
    scope.launch {
        try {
            val resultsArray = Arguments.createArray()
            // Sequentially process each image
            for (uri in processOptions.images) {
                val result = imageProcessor.process(uri, processOptions)
                resultsArray.pushMap(result)
            }
            promise?.resolve(resultsArray)
        } catch (e: Exception) {
            val error = ScannerError.OperationFailed(e.message ?: "Unknown processing error")
            Logger.error("Error in processDocuments", e)
            promise?.reject(error.code, error.message)
        }
    }
  }

  /**
   * Handles the result from the native scanner activity.
   */
  override fun onActivityResult(activity: Activity, requestCode: Int, resultCode: Int, data: Intent?) {
    if (requestCode == START_SCAN_REQUEST_CODE) {
      if (scanPromise == null) {
          Logger.warn("Received onActivityResult but scanPromise is null. Ignoring.")
          return
      }

      if (resultCode == Activity.RESULT_OK && data != null) {
        val result = GmsDocumentScanningResult.fromActivityResultIntent(data)
        if (result != null) {
            val pages = result.pages
            Logger.log("Scan successful. Received ${pages?.size ?: 0} pages. Starting processing...")
            
            // Offload post-processing (copy to cache, OCR, etc.) to background thread
            scope.launch {
                try {
                    val resultsArray = Arguments.createArray()
                    // Fallback to default options if somehow missing (should not happen in normal flow)
                    val options = currentScanOptions ?: ScanOptions.from(null) 
                    
                    if (pages != null) {
                        for (page in pages) {
                            val uri = page.imageUri.toString()
                            // Pass through the shared ImageProcessor pipeline
                            val processedResult = imageProcessor.process(uri, options)
                            resultsArray.pushMap(processedResult)
                        }
                    }
                    scanPromise?.resolve(resultsArray)
                } catch (e: Exception) {
                    val error = ScannerError.OperationFailed("Post-processing failed: ${e.message}")
                    Logger.error(error.message, e)
                    scanPromise?.reject(error.code, error.message)
                } finally {
                    // Cleanup state
                    scanPromise = null
                    currentScanOptions = null
                }
            }
        } else {
            val error = ScannerError.OperationFailed("Scanning result object was null")
            Logger.error(error.message)
            scanPromise?.reject(error.code, error.message)
            scanPromise = null
            currentScanOptions = null
        }
      } else if (resultCode == Activity.RESULT_CANCELED) {
        val error = ScannerError.Canceled()
        Logger.log("User canceled the scanner UI")
        scanPromise?.reject(error.code, error.message)
        scanPromise = null
        currentScanOptions = null
      } else {
        val error = ScannerError.OperationFailed("Unknown Activity result code: $resultCode")
        Logger.warn(error.message)
        scanPromise?.reject(error.code, error.message)
        scanPromise = null
        currentScanOptions = null
      }
    }
  }

  override fun onNewIntent(intent: Intent) {
    // No-op: We only care about onActivityResult
  }

  companion object {
    const val NAME = "DocumentScanner"
    const val START_SCAN_REQUEST_CODE = 1452
  }
}

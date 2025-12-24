package com.documentscanner

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.ColorMatrix
import android.graphics.ColorMatrixColorFilter
import android.graphics.Matrix
import android.graphics.Paint
import android.net.Uri
import androidx.exifinterface.media.ExifInterface
import android.util.Base64
import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.ReadableMap
import com.facebook.react.bridge.WritableMap
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.io.ByteArrayOutputStream
import java.io.File
import java.io.FileOutputStream
import java.io.InputStream
import java.util.UUID

/**
 * Utility class for image processing operations.
 * Handles loading, rotating, filtering, and running OCR on images.
 * executed on a background IO dispatcher.
 */
class ImageProcessor(private val context: Context) {

    /**
     * Main processing pipeline.
     * 1. Loads the bitmap (handling EXIF rotation).
     * 2. Applies filters (Grayscale, Monochrome).
     * 3. Saves processing result to a temp file (required for OCR/Base64 consistency).
     * 4. Encodes to Base64 (optional).
     * 5. Runs OCR (optional).
     *
     * @param uriStr The source URI of the image (file://, content://, data:...)
     * @param options Processing options (quality, format, filters, etc.)
     * @return WritableMap containing uri, base64, text, blocks, etc.
     */
    suspend fun process(uriStr: String, options: BaseOptions): WritableMap = withContext(Dispatchers.IO) {
        val result = Arguments.createMap()
        result.putString("uri", uriStr) // Default to original URI if something fails

        try {
            val uri = Uri.parse(uriStr)
            var bitmap = loadBitmap(uri) ?: return@withContext result

            // 1. Apply Filters
            val filter = options.filter
            if (filter == "grayscale" || filter == "monochrome") {
                Logger.log("Applying filter: $filter")
                bitmap = applyFilter(bitmap, filter)
            }

            // 2. Save Processed Image
            // We save to the cache directory to ensure we deliver a clean file that matches the requested format/quality.
            val qualityInt = (options.quality * 100).toInt().coerceIn(0, 100)
            
            val format = options.format
            val compressFormat = if (format == "png") Bitmap.CompressFormat.PNG else Bitmap.CompressFormat.JPEG
            
            val newFile = File(context.cacheDir, "scan_${UUID.randomUUID()}.${if (format == "png") "png" else "jpg"}")
            val fos = FileOutputStream(newFile)
            bitmap.compress(compressFormat, qualityInt, fos)
            fos.close()
            
            val newUri = Uri.fromFile(newFile).toString()
            result.putString("uri", newUri)

            // 3. Base64 Generation
            if (options.includeBase64) {
                val byteArrayOutputStream = ByteArrayOutputStream()
                bitmap.compress(compressFormat, qualityInt, byteArrayOutputStream)
                val byteArray = byteArrayOutputStream.toByteArray()
                val base64String = Base64.encodeToString(byteArray, Base64.NO_WRAP)
                result.putString("base64", base64String)
            }

            // 4. Optical Character Recognition (OCR)
            if (options.includeText) {
                Logger.log("Running OCR on processed image")
                val ocrResult = TextRecognizer.processImage(context, Uri.fromFile(newFile))
                result.putString("text", ocrResult.getString("text"))
                if (ocrResult.hasKey("blocks")) {
                    result.putArray("blocks", ocrResult.getArray("blocks"))
                }
            }

        } catch (e: Exception) {
            Logger.error("Failed to process image: $uriStr", e)
             // We swallow the specific image error to allow other images in a batch to proceed,
             // but strictly log it. The result map will contain at least the original URI.
        }
        
        return@withContext result
    }

    /**
     * Loads a Bitmap from a URI, handling various schemes and correcting orientation.
     * Supports: content://, file://, data:image/base64
     */
    private fun loadBitmap(uri: Uri): Bitmap? {
         try {
             // Handle data URI (Base64)
             if (uri.scheme == "data") {
                 val base64Data = uri.toString().substringAfter(",")
                 val decodedBytes = Base64.decode(base64Data, Base64.DEFAULT)
                 return BitmapFactory.decodeByteArray(decodedBytes, 0, decodedBytes.size)
             }

             // Handle Content/File URIs
             var inputStream: InputStream? = context.contentResolver.openInputStream(uri)
             val originalBitmap = BitmapFactory.decodeStream(inputStream)
             inputStream?.close()

             if (originalBitmap == null) {
                 Logger.warn("Failed to decode bitmap from $uri")
                 return null
             }

             // Read EXIF to determine orientation
             // This is critical for images from Gallery or Camera which might use orientation tags
             inputStream = context.contentResolver.openInputStream(uri)
             if (inputStream == null) return originalBitmap

             try {
                val exif = ExifInterface(inputStream)
                val orientation = exif.getAttributeInt(ExifInterface.TAG_ORIENTATION, ExifInterface.ORIENTATION_NORMAL)
                inputStream.close()
                return rotateBitmap(originalBitmap, orientation)
             } catch (e: Exception) {
                // If EXIF fails (e.g. some streams don't support it), fail safe and return original
                Logger.warn("Failed to read EXIF for rotation: ${e.message}")
                return originalBitmap
             }
         } catch (e: Exception) {
             Logger.error("Error loading bitmap", e)
             return null
         }
    }

    /**
     * Rotates a bitmap based on EXIF orientation.
     */
    private fun rotateBitmap(bitmap: Bitmap, orientation: Int): Bitmap {
        val matrix = Matrix()
        when (orientation) {
            ExifInterface.ORIENTATION_ROTATE_90 -> matrix.postRotate(90f)
            ExifInterface.ORIENTATION_ROTATE_180 -> matrix.postRotate(180f)
            ExifInterface.ORIENTATION_ROTATE_270 -> matrix.postRotate(270f)
            else -> return bitmap
        }
        return Bitmap.createBitmap(bitmap, 0, 0, bitmap.width, bitmap.height, matrix, true)
    }

    /**
     * Applies color filters to the bitmap.
     * Supports "grayscale" and "monochrome" (high contrast).
     */
    private fun applyFilter(src: Bitmap, filterType: String?): Bitmap {
        val width = src.width
        val height = src.height
        val dest = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(dest)
        val paint = Paint()
        
        // 0-saturation matrix for Grayscale
        val colorMatrix = ColorMatrix()
        colorMatrix.setSaturation(0f)
        
        if (filterType == "monochrome") {
             // For monochrome, we apply high contrast on top of grayscale
             // This simulates a "scanned document" look
             val contrast = ColorMatrix()
             val scale = 1.3f
             val translate = (-.5f * scale + .5f) * 255f
             contrast.set(floatArrayOf(
                 scale, 0f, 0f, 0f, translate,
                 0f, scale, 0f, 0f, translate,
                 0f, 0f, scale, 0f, translate,
                 0f, 0f, 0f, 1f, 0f
             ))
             colorMatrix.postConcat(contrast)
        }

        val filter = ColorMatrixColorFilter(colorMatrix)
        paint.colorFilter = filter
        canvas.drawBitmap(src, 0f, 0f, paint)
        return dest
    }
}

package com.documentscanner

import android.content.Context
import android.net.Uri
import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.WritableMap
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.text.TextRecognition
import com.google.mlkit.vision.text.latin.TextRecognizerOptions
import kotlinx.coroutines.tasks.await

/**
 * Utility class for performing Optical Character Recognition (OCR) using ML Kit.
 * Extracts text and bounding boxes from images.
 *
 * Acts as a Facade delegating to versioned implementations:
 * - TextRecognizerV1 (Raw)
 * - TextRecognizerV2 (Heuristic)
 */
class TextRecognizer {
    companion object {

        /**
         * Processes an image and extracts text blocks based on the requested version.
         *
         * @param context Application context
         * @param uri URI of the image to process from disk
         * @param version OCR engine version (1 = Raw ML Kit, 2 = Layout Heuristics)
         * @return WritableMap containing "text" and "blocks"
         */
        suspend fun processImage(context: Context, uri: Uri, version: Int): WritableMap {
            try {
                val image = InputImage.fromFilePath(context, uri)
                val imagePixelWidth = image.width.toDouble()
                val imagePixelHeight = image.height.toDouble()

                val recognizer = TextRecognition.getClient(TextRecognizerOptions.DEFAULT_OPTIONS)
                val visionText = recognizer.process(image).await()

                return if (version == 1) {
                    TextRecognizerV1.process(visionText, imagePixelWidth, imagePixelHeight)
                } else {
                    TextRecognizerV2.process(visionText, imagePixelWidth, imagePixelHeight)
                }

            } catch (e: Exception) {
                e.printStackTrace()
                Logger.error("OCR processing failed: ${e.message}", e)
                val emptyMap = Arguments.createMap()
                emptyMap.putString("text", "")
                emptyMap.putArray("blocks", Arguments.createArray())
                return emptyMap
            }
        }
    }
}

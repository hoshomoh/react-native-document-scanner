package com.documentscanner

import android.content.Context
import android.graphics.Rect
import android.net.Uri
import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.WritableArray
import com.facebook.react.bridge.WritableMap
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.text.TextRecognition
import com.google.mlkit.vision.text.latin.TextRecognizerOptions
import kotlinx.coroutines.tasks.await
import java.io.IOException

/**
 * Utility class for performing Optical Character Recognition (OCR) using ML Kit.
 * Extracts text and bounding boxes from images.
 */
class TextRecognizer {
    companion object {
        
        /**
         * Processes an image and extracts text blocks.
         *
         * @param context Application context
         * @param uri URI of the image to process
         * @return WritableMap containing "text" (raw string) and "blocks" (array of text blocks with frames)
         */
        suspend fun processImage(context: Context, uri: Uri): WritableMap {
            val resultMap = Arguments.createMap()
            try {
                val image = InputImage.fromFilePath(context, uri)
                // Get image dimensions for coordinate normalization
                val width = image.width
                val height = image.height
                
                // Using Latin script recognizer as default (ML Kit V2)
                val recognizer = TextRecognition.getClient(TextRecognizerOptions.DEFAULT_OPTIONS)
                val visionText = recognizer.process(image).await()

                resultMap.putString("text", visionText.text)

                val blocksArray = Arguments.createArray()
                visionText.textBlocks.forEach { block ->
                    val blockMap = Arguments.createMap()
                    blockMap.putString("text", block.text)
                    
                    val frameMap = Arguments.createMap()
                    val box = block.boundingBox ?: Rect(0,0,0,0)
                    
                    // Normalize coordinates (0-1) based on image dimensions
                    // this ensures compatibility with React Native layout systems which might scale the image
                    frameMap.putDouble("x", box.left.toDouble() / width)
                    frameMap.putDouble("y", box.top.toDouble() / height)
                    frameMap.putDouble("width", box.width().toDouble() / width)
                    frameMap.putDouble("height", box.height().toDouble() / height)
                    
                    blockMap.putMap("frame", frameMap)
                    blocksArray.pushMap(blockMap)
                }
                resultMap.putArray("blocks", blocksArray)

            } catch (e: Exception) {
                e.printStackTrace()
                // Return empty text on failure rather than failing the whole process
                // This is a design choice: Partial failure (OCR) shouldn't block the main scanning result.
                resultMap.putString("text", "")
                resultMap.putArray("blocks", Arguments.createArray())
            }
            return resultMap
        }
    }
}

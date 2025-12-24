package com.documentscanner

import android.content.Context
import android.graphics.Rect
import android.net.Uri
import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.WritableMap
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.text.Text
import com.google.mlkit.vision.text.TextRecognition
import com.google.mlkit.vision.text.latin.TextRecognizerOptions
import kotlinx.coroutines.tasks.await
import kotlin.math.abs
import kotlin.math.max
import kotlin.math.min

/**
 * Utility class for performing Optical Character Recognition (OCR) using ML Kit.
 * Extracts text and bounding boxes from images.
 *
 * This implementation uses a layout preservation heuristic:
 * 1. Sort text elements by Y position (top-to-bottom).
 * 2. Group elements into "lines" based on vertical overlap.
 * 3. Sort each line by X position (left-to-right) and add proportional spacing.
 */
class TextRecognizer {
    companion object {
        
        /**
         * Internal data class representing a text element with its bounding box and confidence.
         */
        private data class TextElement(
            val text: String,
            val left: Double,
            val top: Double,
            val width: Double,
            val height: Double,
            val confidence: Double
        )

        /**
         * Processes an image and extracts text blocks with layout preservation.
         *
         * @param context Application context
         * @param uri URI of the image to process
         * @return WritableMap containing "text" (layout-preserved string) and "blocks" (array of text blocks with frames)
         */
        suspend fun processImage(context: Context, uri: Uri): WritableMap {
            val resultMap = Arguments.createMap()
            try {
                val image = InputImage.fromFilePath(context, uri)
                val imageWidth = image.width.toDouble()
                val imageHeight = image.height.toDouble()
                
                val recognizer = TextRecognition.getClient(TextRecognizerOptions.DEFAULT_OPTIONS)
                val visionText = recognizer.process(image).await()

                // ---------------------------------------------------------
                // Step 1: Extract all text elements (lines from ML Kit)
                // ML Kit's Text.Line is roughly equivalent to Vision's observation
                // ---------------------------------------------------------
                val allElements = mutableListOf<TextElement>()
                
                for (block in visionText.textBlocks) {
                    for (line in block.lines) {
                        val box = line.boundingBox ?: continue
                        // Normalize coordinates to 0-1 range
                        // ML Kit provides confidence at the Element level, we average for line-level
                        val lineConfidence = if (line.elements.isNotEmpty()) {
                            line.elements.map { it.confidence.toDouble() }.average()
                        } else {
                            1.0 // Default to 1.0 if no elements
                        }
                        allElements.add(TextElement(
                            text = line.text,
                            left = box.left.toDouble() / imageWidth,
                            top = box.top.toDouble() / imageHeight,
                            width = box.width().toDouble() / imageWidth,
                            height = box.height().toDouble() / imageHeight,
                            confidence = lineConfidence
                        ))
                    }
                }

                // ---------------------------------------------------------
                // Step 2: Group elements into rows based on vertical overlap
                // ---------------------------------------------------------
                // Sort by Y ascending (top-to-bottom in Android coordinate space where 0 is top)
                val sortedElements = allElements.sortedBy { it.top }
                
                val lines = mutableListOf<MutableList<TextElement>>()
                
                for (element in sortedElements) {
                    var added = false
                    for (line in lines) {
                        val ref = line.firstOrNull() ?: continue
                        
                        // Calculate vertical centers
                        val center1 = ref.top + ref.height / 2
                        val center2 = element.top + element.height / 2
                        val heightAvg = (ref.height + element.height) / 2
                        
                        // HEURISTIC: If centers are within threshold, consider them the same line
                        if (abs(center1 - center2) < heightAvg / OCRConfiguration.VERTICAL_MERGE_DIVISOR) {
                            line.add(element)
                            added = true
                            break
                        }
                    }
                    if (!added) {
                        lines.add(mutableListOf(element))
                    }
                }

                // ---------------------------------------------------------
                // Step 3: Reconstruct text with column spacing
                // ---------------------------------------------------------
                val structuredText = StringBuilder()
                
                for (line in lines) {
                    // Sort elements within line by X (left-to-right)
                    val sortedLine = line.sortedBy { it.left }
                    
                    val lineString = StringBuilder()
                    var lastXEnd = 0.0
                    
                    for (element in sortedLine) {
                        val xStart = element.left
                        val gap = xStart - lastXEnd
                        
                        // HEURISTIC: If gap > threshold, insert proportional spaces
                        if (gap > OCRConfiguration.HORIZONTAL_SPACING_THRESHOLD && lineString.isNotEmpty()) {
                            val spaces = max(1, (gap * OCRConfiguration.SPACE_SCALING_FACTOR).toInt())
                            val cappedSpaces = min(spaces, OCRConfiguration.MAX_SPACES)
                            lineString.append(" ".repeat(cappedSpaces))
                        }
                        
                        lineString.append(element.text)
                        lastXEnd = xStart + element.width
                    }
                    structuredText.append(lineString).append("\n")
                }
                
                resultMap.putString("text", structuredText.toString())

                // ---------------------------------------------------------
                // Step 4: Build blocks array for metadata (unchanged logic)
                // ---------------------------------------------------------
                val blocksArray = Arguments.createArray()
                visionText.textBlocks.forEach { block ->
                    val blockMap = Arguments.createMap()
                    blockMap.putString("text", block.text)
                    
                    val frameMap = Arguments.createMap()
                    val box = block.boundingBox ?: Rect(0,0,0,0)
                    
                    frameMap.putDouble("x", box.left.toDouble() / imageWidth)
                    frameMap.putDouble("y", box.top.toDouble() / imageHeight)
                    frameMap.putDouble("width", box.width().toDouble() / imageWidth)
                    frameMap.putDouble("height", box.height().toDouble() / imageHeight)
                    
                    blockMap.putMap("frame", frameMap)
                    
                    // Calculate average confidence from all elements in the block
                    val allElements = block.lines.flatMap { it.elements }
                    if (allElements.isNotEmpty()) {
                        val avgConfidence = allElements.map { it.confidence.toDouble() }.average()
                        blockMap.putDouble("confidence", avgConfidence)
                    }
                    
                    blocksArray.pushMap(blockMap)
                }
                resultMap.putArray("blocks", blocksArray)

            } catch (e: Exception) {
                e.printStackTrace()
                Logger.error("OCR processing failed: ${e.message}", e)
                resultMap.putString("text", "")
                resultMap.putArray("blocks", Arguments.createArray())
            }
            return resultMap
        }
    }
}

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
                        
                        /*
                         * HEURISTIC: Vertical Overlap & Height Similarity
                         *
                         * Research: O'Gorman (1993) Docstrum & Breuel (2002).
                         * We use geometric clustering based on vertical overlap.
                         */
                        
                        val y1_bottom = ref.top + ref.height
                        val y1_top = ref.top
                        
                        val y2_bottom = element.top + element.height
                        val y2_top = element.top
                        
                        // Note: In Android (ML Kit), coordinates are usually top-left origin. 
                        // So top is smaller than bottom.
                        // Overlap calculation:
                        val intersectionTop = max(y1_top, y2_top)
                        val intersectionBottom = min(y1_bottom, y2_bottom)
                        val intersectionHeight = max(0.0, intersectionBottom - intersectionTop)
                        
                        val minHeight = min(ref.height, element.height)
                        val maxHeight = max(ref.height, element.height)
                        
                        /*
                         * Condition 1: Significant Vertical Overlap (> 50% of the smaller height)
                         * Ensures items are on the same "visual line".
                         */
                        val isVerticallyAligned = (intersectionHeight / minHeight) > 0.5
                        
                        /*
                         * Condition 2: Height Similarity (> 50% ratio)
                         * Prevents merging distinct semantic references like small footer text with large headers.
                         */
                        val isSimilarHeight = (minHeight / maxHeight) > 0.5
                        
                        if (isVerticallyAligned && isSimilarHeight) {
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
                    
                    // Calculate average height of the line
                    val avgLineHeight = if (line.isNotEmpty()) line.map { it.height }.average() else 0.0
                    
                    val lineString = StringBuilder()
                    var lastXEnd = 0.0
                    
                    for ((index, element) in sortedLine.withIndex()) {
                        val xStart = element.left
                        
                        if (index > 0) {
                            val gap = xStart - lastXEnd
                            
                            /*
                             * HEURISTIC: Adaptive Horizontal Spacing
                             * Research: Kshetry (2021) - Adaptive thresholding.
                             * Use line height as proxy for em-space.
                             */
                            if (gap > (avgLineHeight * 0.5)) {
                                /*
                                 * Scale spaces.
                                 * Assume 1 "space" char is ~0.3 of height.
                                 */
                                val estimatedSpaceWidth = avgLineHeight * 0.3
                                val spaces = max(1, (gap / estimatedSpaceWidth).toInt())
                                val cappedSpaces = min(spaces, OCRConfiguration.MAX_SPACES)
                                lineString.append(" ".repeat(cappedSpaces))
                            } else if (gap > 0) {
                                lineString.append(" ")
                            }
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

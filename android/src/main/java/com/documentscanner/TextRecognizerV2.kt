package com.documentscanner

import android.graphics.Rect
import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.WritableMap
import com.google.mlkit.vision.text.Text
import kotlin.math.abs
import kotlin.math.max
import kotlin.math.min

/**
 * Version 2: Heuristic Enhanced (Line Clustering for Layout Preservation)
 */
class TextRecognizerV2 {

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

    companion object {
        /**
         * Performs heuristic-enhanced text recognition with layout preservation.
         * Matches horizontally aligned word-level elements into logical lines.
         *
         * @param visionText The raw result from ML Kit.
         * @param imagePixelWidth Original image width in pixels.
         * @param imagePixelHeight Original image height in pixels.
         * @return WritableMap with "text" (structured) and "blocks" (metadata).
         */
        fun process(visionText: Text, imagePixelWidth: Double, imagePixelHeight: Double): WritableMap {
            val resultMap = Arguments.createMap()

            // Step 1: Extract generic "TextElement" from ML Kit's word-level elements
            val allElements = mutableListOf<TextElement>()

            // Flatten to word level (line.elements) for better granular clustering
            for (block in visionText.textBlocks) {
                for (line in block.lines) {
                    for (element in line.elements) {
                        val box = element.boundingBox ?: continue
                        allElements.add(TextElement(
                            text = element.text,
                            left = safeNormalize(box.left.toDouble(), imagePixelWidth),
                            top = safeNormalize(box.top.toDouble(), imagePixelHeight),
                            width = safeNormalize(box.width().toDouble(), imagePixelWidth),
                            height = safeNormalize(box.height().toDouble(), imagePixelHeight),
                            confidence = element.confidence.toDouble() // Element level confidence
                        ))
                    }
                }
            }

            // Step 2: Group elements into Lines using LineCluster Strategy
            class LineCluster(firstElement: TextElement) {
                val elements = mutableListOf(firstElement)
                val heights = mutableListOf(firstElement.height)

                // Union Bounding Box state
                var uLeft = firstElement.left
                var uTop = firstElement.top
                var uRight = firstElement.left + firstElement.width
                var uBottom = firstElement.top + firstElement.height

                fun medianHeight(): Double {
                    if (heights.isEmpty()) return 0.0
                    val sorted = heights.sorted()
                    val mid = sorted.size / 2
                    return if (sorted.size % 2 == 0) {
                        (sorted[mid - 1] + sorted[mid]) / 2.0
                    } else {
                        sorted[mid]
                    }
                }

                val height: Double get() = uBottom - uTop
                val midY: Double get() = uTop + (height / 2.0)

                fun add(element: TextElement) {
                    elements.add(element)
                    heights.add(element.height)

                    // Update union box
                    uLeft = min(uLeft, element.left)
                    uTop = min(uTop, element.top)
                    uRight = max(uRight, element.left + element.width)
                    uBottom = max(uBottom, element.top + element.height)
                }
            }

            // Sort by Top (Y) ascending
            val sortedElements = allElements.sortedBy { it.top + (it.height / 2.0) } // Sort by midY
            val clusters = mutableListOf<LineCluster>()

            for (element in sortedElements) {
                val elHeight = element.height
                val elMidY = element.top + (elHeight / 2.0)

                var bestClusterIndex: Int? = null
                var bestOverlapRatio = 0.0
                var bestCenterDist = Double.MAX_VALUE

                for ((index, cluster) in clusters.withIndex()) {

                    // 1. Height Similarity Check
                    val minH = min(cluster.height, elHeight)
                    val maxH = max(cluster.height, elHeight)
                    if ((minH / maxH) < OCRConfiguration.HEIGHT_COMPATIBILITY_THRESHOLD) continue

                    // 2. Overlap & Centerline
                    // Intersection
                    val intTop = max(cluster.uTop, element.top)
                    val intBottom = min(cluster.uBottom, element.top + element.height)
                    val intHeight = max(0.0, intBottom - intTop)

                    val overlapRatio = intHeight / minH

                    val centerDist = abs(cluster.midY - elMidY)
                    val typicalHeight = max(cluster.medianHeight(), elHeight)

                    val isOverlapGood = overlapRatio >= OCRConfiguration.OVERLAP_RATIO_THRESHOLD
                    val isCenterClose = centerDist <= (OCRConfiguration.CENTERLINE_DISTANCE_FACTOR * typicalHeight)

                    if (isOverlapGood || isCenterClose) {
                        // 3. Adaptive Cluster Growth Constraint
                        // Check Horizontal Overlap
                        val clusterRight = cluster.uRight
                        val elementRight = element.left + element.width
                        val intersectX = max(0.0, min(clusterRight, elementRight) - max(cluster.uLeft, element.left))
                        val isStacked = intersectX > 0

                        // Adaptive Limit: stacked vs skewed
                        val growthLimit = if (isStacked) OCRConfiguration.STACKED_GROWTH_LIMIT else OCRConfiguration.SKEWED_GROWTH_LIMIT

                        // Calculate hypothetical new union height
                        val newTop = min(cluster.uTop, element.top)
                        val newBottom = max(cluster.uBottom, element.top + element.height)
                        val newHeight = newBottom - newTop

                        if (newHeight <= (growthLimit * typicalHeight)) {
                            // Score match
                            if (overlapRatio > bestOverlapRatio) {
                                bestOverlapRatio = overlapRatio
                                bestCenterDist = centerDist
                                bestClusterIndex = index
                            } else if (abs(overlapRatio - bestOverlapRatio) < 0.01 && centerDist < bestCenterDist) {
                                bestCenterDist = centerDist
                                bestClusterIndex = index
                            }
                        }
                    }
                }

                if (bestClusterIndex != null) {
                    clusters[bestClusterIndex].add(element)
                } else {
                    clusters.add(LineCluster(element))
                }
            }

            // Sort clusters top-to-bottom
            clusters.sortBy { it.midY }

            // Step 3: Reconstruct text with adaptive column spacing
            val structuredText = StringBuilder()

            for (cluster in clusters) {
                // Sort elements Left-to-Right for reading order
                val lineElements = cluster.elements.sortedBy { it.left }
                val medianH = cluster.medianHeight()

                val lineString = StringBuilder()
                var lastXEnd = 0.0

                for ((index, element) in lineElements.withIndex()) {
                    val xStart = element.left

                    if (index > 0) {
                        val gap = xStart - lastXEnd

                        // Apply spacing heuristics defined in OCRConfiguration
                        if (gap > (medianH * OCRConfiguration.ADAPTIVE_SPACING_FACTOR)) {
                            val spaceWidth = medianH * OCRConfiguration.SPACE_WIDTH_FACTOR
                            val spaces = max(1, (gap / spaceWidth).toInt())
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

            // Step 4: Build blocks array for metadata (unchanged logic)
            val blocksArray = Arguments.createArray()
            visionText.textBlocks.forEach { block ->
                val blockMap = Arguments.createMap()
                blockMap.putString("text", block.text)

                val frameMap = Arguments.createMap()
                val box = block.boundingBox ?: Rect(0,0,0,0)

                frameMap.putDouble("x", safeNormalize(box.left.toDouble(), imagePixelWidth))
                frameMap.putDouble("y", safeNormalize(box.top.toDouble(), imagePixelHeight))
                frameMap.putDouble("width", safeNormalize(box.width().toDouble(), imagePixelWidth))
                frameMap.putDouble("height", safeNormalize(box.height().toDouble(), imagePixelHeight))

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

            return resultMap
        }

        /**
         * Safely normalizes a pixel value by dividing by the dimension.
         * Returns 0.0 if the dimension is zero or negative to avoid divide-by-zero.
         */
        private fun safeNormalize(value: Double, dimension: Double): Double {
            return if (dimension > 0) value / dimension else 0.0
        }
    }
}

package com.documentscanner

import android.graphics.Rect
import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.WritableMap
import com.google.mlkit.vision.text.Text

/**
 * Version 1: Raw Output (Standard ML Kit Behavior)
 */
class TextRecognizerV1 {
    companion object {
        /**
         * Performs raw text recognition using ML Kit's default block grouping.
         * 
         * @param visionText The raw result from ML Kit.
         * @param imagePixelWidth Original image width in pixels.
         * @param imagePixelHeight Original image height in pixels.
         * @return WritableMap with "text" and "blocks".
         */
        fun process(visionText: Text, imagePixelWidth: Double, imagePixelHeight: Double): WritableMap {
            val resultMap = Arguments.createMap()
            
            // Raw text from ML Kit (usually groups blocks heuristically by itself)
            resultMap.putString("text", visionText.text)
            
            // Standard Blocks Array
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

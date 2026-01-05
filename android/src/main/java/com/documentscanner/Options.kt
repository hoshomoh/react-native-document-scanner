package com.documentscanner

import com.facebook.react.bridge.ReadableMap

/**
 * Base options shared by both Scan and Process operations.
 * Allows parsing common properties from a React Native ReadableMap.
 */
abstract class BaseOptions(
    val quality: Double,
    val format: String,
    val filter: String,
    val includeBase64: Boolean,
    val includeText: Boolean,
    val textVersion: Int
) {
    /**
     * Secondary constructor to parse common options from a dictionary.
     * Delegates to the primary constructor with validated values.
     */
    constructor(options: ReadableMap?, defaultIncludeText: Boolean) : this(
        quality = parseQuality(options),
        format = parseFormat(options),
        filter = parseFilter(options),
        includeBase64 = parseBoolean(options, "includeBase64", false),
        includeText = parseBoolean(options, "includeText", defaultIncludeText),
        textVersion = parseTextVersion(options)
    )

    companion object {
        /** Validates and returns the compression quality [0.1, 1.0]. */
        private fun parseQuality(options: ReadableMap?): Double {
            val value = if (options?.hasKey("quality") == true) options.getDouble("quality") else 1.0
            return value.coerceIn(0.1, 1.0)
        }

        /** Whitelists and returns the output image format. */
        private fun parseFormat(options: ReadableMap?): String {
            val value = options?.getString("format") ?: "jpg"
            return if (value == "png") "png" else "jpg"
        }

        /** Whitelists and returns the post-processing filter. */
        private fun parseFilter(options: ReadableMap?): String {
            val value = options?.getString("filter") ?: "color"
            val validFilters = listOf("color", "grayscale", "monochrome", "denoise", "sharpen", "ocrOptimized")
            return if (validFilters.contains(value)) value else "color"
        }

        /** Safely parses a boolean value with a default fallback. */
        private fun parseBoolean(options: ReadableMap?, key: String, default: Boolean): Boolean {
            return if (options?.hasKey(key) == true) options.getBoolean(key) else default
        }

        /** Validates and returns the OCR engine version [1, 2]. */
        private fun parseTextVersion(options: ReadableMap?): Int {
            val value = if (options?.hasKey("textVersion") == true) options.getInt("textVersion") else 2
            return if (value == 1) 1 else 2
        }
    }
}

/**
 * Strongly-typed options for the scanDocuments() method.
 */
class ScanOptions(options: ReadableMap?, fallbackPageCount: Int) : BaseOptions(options, false) {
    /** Maximum pages to scan, clamped to [0, 100]. */
    val maxPageCount: Int = parseMaxPages(options, fallbackPageCount)

    companion object {
        fun from(options: ReadableMap?): ScanOptions = ScanOptions(options, 0)

        private fun parseMaxPages(options: ReadableMap?, fallback: Int): Int {
            val value = if (options?.hasKey("maxPageCount") == true) options.getInt("maxPageCount") else fallback
            return value.coerceIn(0, 100)
        }
    }
}

/**
 * Strongly-typed options for the processDocuments() method.
 */
class ProcessOptions(options: ReadableMap?) : BaseOptions(options, true) {
    /** List of image URIs or Base64 strings to process. */
    val images: List<String> = parseImages(options)

    companion object {
        fun from(options: ReadableMap?): ProcessOptions = ProcessOptions(options)

        private fun parseImages(options: ReadableMap?): List<String> {
            val images = mutableListOf<String>()
            if (options?.hasKey("images") == true) {
                val array = options.getArray("images")
                if (array != null) {
                    for (i in 0 until array.size()) {
                        array.getString(i)?.let { images.add(it) }
                    }
                }
            }
            return images
        }
    }
}

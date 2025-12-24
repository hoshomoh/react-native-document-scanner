package com.documentscanner

import com.facebook.react.bridge.ReadableMap

/**
 * Base options shared by both Scan and Process operations.
 * Contains configuration for image output and OCR processing.
 *
 * @property quality JPEG compression quality (0.0-1.0). Default: 1.0.
 * @property format Output format ("jpg" or "png"). Default: "jpg".
 * @property filter Post-processing filter ("color", "grayscale", "monochrome", "denoise", "sharpen", "ocrOptimized").
 * @property includeBase64 Whether to include base64-encoded image in result. Default: false.
 * @property includeText Whether to perform OCR and include text/blocks in result. Default: false.
 */
abstract class BaseOptions(
    val quality: Double,
    val format: String,
    val filter: String,
    val includeBase64: Boolean,
    val includeText: Boolean
)

/**
 * Strongly-typed options for the scanDocuments() method.
 * Extends BaseOptions with scan-specific configuration.
 *
 * @property maxPageCount Maximum number of pages to scan. 0 = unlimited (platform default).
 */
class ScanOptions(
    val maxPageCount: Int,
    quality: Double,
    format: String,
    filter: String,
    includeBase64: Boolean,
    includeText: Boolean
) : BaseOptions(quality, format, filter, includeBase64, includeText) {
    
    companion object {
        /**
         * Parses a ReadableMap from React Native into a ScanOptions instance.
         * Applies sensible defaults for any missing properties.
         *
         * @param options The ReadableMap from JavaScript, or null for all defaults.
         * @return A fully-populated ScanOptions instance.
         */
        fun from(options: ReadableMap?): ScanOptions {
            return ScanOptions(
                maxPageCount = if (options?.hasKey("maxPageCount") == true) options.getInt("maxPageCount") else 0,
                quality = if (options?.hasKey("quality") == true) options.getDouble("quality") else 1.0,
                format = if (options?.hasKey("format") == true) options.getString("format") ?: "jpg" else "jpg",
                filter = if (options?.hasKey("filter") == true) options.getString("filter") ?: "color" else "color",
                includeBase64 = if (options?.hasKey("includeBase64") == true) options.getBoolean("includeBase64") else false,
                includeText = if (options?.hasKey("includeText") == true) options.getBoolean("includeText") else false
            )
        }
    }
}

/**
 * Strongly-typed options for the processDocuments() method.
 * Extends BaseOptions with a list of image sources to process.
 *
 * @property images List of image sources (file URIs, content URIs, or base64 strings).
 */
class ProcessOptions(
    val images: List<String>,
    quality: Double,
    format: String,
    filter: String,
    includeBase64: Boolean,
    includeText: Boolean
) : BaseOptions(quality, format, filter, includeBase64, includeText) {

    companion object {
        /**
         * Parses a ReadableMap from React Native into a ProcessOptions instance.
         * Applies sensible defaults for any missing properties.
         * Note: includeText defaults to true for process operations (common use case).
         *
         * @param options The ReadableMap from JavaScript, or null for all defaults.
         * @return A fully-populated ProcessOptions instance.
         */
        fun from(options: ReadableMap?): ProcessOptions {
            val imagesList = ArrayList<String>()
            if (options?.hasKey("images") == true) {
                val array = options.getArray("images")
                if (array != null) {
                    for (i in 0 until array.size()) {
                        val str = array.getString(i)
                        if (str != null) {
                            imagesList.add(str)
                        }
                    }
                }
            }

            return ProcessOptions(
                images = imagesList,
                quality = if (options?.hasKey("quality") == true) options.getDouble("quality") else 1.0,
                format = if (options?.hasKey("format") == true) options.getString("format") ?: "jpg" else "jpg",
                filter = if (options?.hasKey("filter") == true) options.getString("filter") ?: "color" else "color",
                includeBase64 = if (options?.hasKey("includeBase64") == true) options.getBoolean("includeBase64") else false,
                includeText = if (options?.hasKey("includeText") == true) options.getBoolean("includeText") else true // Default true for process
            )
        }
    }
}

package com.documentscanner

import com.facebook.react.bridge.ReadableMap

/**
 * Base options shared by both Scan and Process operations.
 */
abstract class BaseOptions(
    val quality: Double,
    val format: String,
    val filter: String,
    val includeBase64: Boolean,
    val includeText: Boolean
)

/**
 * Strongly-typed options for scanDocuments.
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
 * Strongly-typed options for processDocuments.
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

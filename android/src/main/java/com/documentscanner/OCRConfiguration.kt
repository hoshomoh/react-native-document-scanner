package com.documentscanner

/**
 * Configuration constants for the OCR engine.
 * Tuning these values affects how the TextRecognizer reconstructs layout from raw text blocks.
 */
object OCRConfiguration {
    
    // --- V2 Clustering Heuristics ---
    
    /**
     * Height Compatibility Threshold.
     * Blocks must have similar heights to be clustered.
     * Formula: minH / maxH >= threshold
     */
    const val HEIGHT_COMPATIBILITY_THRESHOLD: Double = 0.40
    
    /**
     * Overlap Ratio Threshold.
     * Vertical intersection divided by min height.
     */
    const val OVERLAP_RATIO_THRESHOLD: Double = 0.50
    
    /**
     * Centerline Distance Factor.
     * Max allowed vertical distance between centers as a factor of typical line height.
     */
    const val CENTERLINE_DISTANCE_FACTOR: Double = 0.70
    
    /**
     * Adaptive Cluster Growth Limits.
     * Prevents lines from becoming too tall after merging blocks.
     */
    const val STACKED_GROWTH_LIMIT: Double = 1.2
    const val SKEWED_GROWTH_LIMIT: Double = 2.0
    
    // --- Spacing & Reconstruction ---
    
    /**
     * Adaptive Spacing Factor.
     * Gap width relative to median height to trigger extra spaces.
     */
    const val ADAPTIVE_SPACING_FACTOR: Double = 0.5
    
    /**
     * Space Width Factor.
     * Determines the "width" of a single space character relative to median height.
     */
    const val SPACE_WIDTH_FACTOR: Double = 0.3
    
    /**
     * Maximum Spaces Cap.
     * Limits the number of consecutive spaces inserted.
     */
    const val MAX_SPACES: Int = 10
}

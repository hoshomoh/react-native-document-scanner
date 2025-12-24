package com.documentscanner

/**
 * Configuration constants for the OCR engine.
 * Tuning these values affects how the TextRecognizer reconstructs layout from raw text blocks.
 */
object OCRConfiguration {
    
    /**
     * Vertical Line Merging Threshold (Divisor).
     *
     * Determines how close two text blocks must be vertically to be considered on the "same line".
     * Formula: `abs(center1 - center2) < (averageHeight / verticalMergeDivisor)`
     *
     * - Default: 2.0 (Half the average height).
     * - Effect:
     *   - Lower value (e.g., 1.5): Stricter. Blocks must be very aligned to merge.
     *   - Higher value (e.g., 3.0): Looser. Blocks with slight vertical offsets will merge.
     */
    const val VERTICAL_MERGE_DIVISOR: Double = 2.0
    
    /**
     * Horizontal Spacing Threshold (Percentage).
     *
     * The minimum gap between words (normalized width 0.0-1.0) to insert extra spacing.
     * This mimics "tab" or column separation.
     *
     * - Default: 0.02 (2% of the image width).
     * - Effect:
     *   - Lower value (e.g., 0.01): Sensitive. Will insert spaces between closely kerning words.
     *   - Higher value (e.g., 0.05): Robust. Only large gaps (like columns) get extra spaces.
     */
    const val HORIZONTAL_SPACING_THRESHOLD: Double = 0.02
    
    /**
     * Space Scaling Factor.
     *
     * Converts the normalized gap width (0.0-1.0) into a number of space characters (" ").
     * Formula: `numberOfSpaces = Int(gap * spaceScalingFactor)`
     *
     * - Default: 50.
     * - Effect:
     *   - Lower value (e.g., 30): Compact. Large gaps result in fewer spaces.
     *   - Higher value (e.g., 100): Wide. Gaps are dramatically emphasized with many spaces.
     */
    const val SPACE_SCALING_FACTOR: Double = 50.0
    
    /**
     * Maximum Spaces Cap.
     *
     * Limits the number of consecutive spaces inserted to prevent huge gaps from breaking UI or text editors.
     *
     * - Default: 10.
     * - Effect: Prevents a single line from having 50+ spaces if the gap is very large.
     */
    const val MAX_SPACES: Int = 10
}

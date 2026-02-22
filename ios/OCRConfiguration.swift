import Foundation

/**
 Configuration constants for the OCR engine.
 Tuning these values affects how the `TextRecognizer` reconstructs layout from raw text blocks.
 */
public enum OCRConfiguration {
  
    /* ----------------------------------------------------------------------- */
    /* V2 Clustering Heuristics                                                */
    /* ----------------------------------------------------------------------- */
    
    /**
     Height Compatibility Threshold.
     Blocks must have similar heights to be clustered.
     Formula: minH / maxH >= threshold
     */
    public static let heightCompatibilityThreshold: Double = 0.40
    
    /**
     Overlap Ratio Threshold.
     Vertical intersection divided by min height.
     */
    public static let overlapRatioThreshold: Double = 0.50
    
    /**
     Centerline Distance Factor.
     Max allowed vertical distance between centers as a factor of typical line height.
     */
    public static let centerlineDistanceFactor: Double = 0.70
    
    /**
     Adaptive Cluster Growth Limits.
     Prevents lines from becoming too tall after merging blocks.
     */
    public static let stackedGrowthLimit: Double = 1.2
    public static let skewedGrowthLimit: Double = 2.0
    
    /* ----------------------------------------------------------------------- */
    /* Spacing & Reconstruction                                                */
    /* ----------------------------------------------------------------------- */
    
    /**
     Adaptive Spacing Factor.
     Gap width relative to median height to trigger extra spaces.
     */
    public static let adaptiveSpacingFactor: Double = 1.0
    
    /**
     Space Width Factor.
     Determines the "width" of a single space character relative to median height.
     */
    public static let spaceWidthFactor: Double = 0.3
    
    /**
     Maximum Spaces Cap.
     Limits the number of consecutive spaces inserted.
     */
    public static let maxSpaces: Int = 10
}

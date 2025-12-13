import Foundation
import UIKit

/**
 Strongly-typed representation of scan options.
 Parses the raw dictionary from React Native and provides defaults.
 */
public struct ScanOptions {
    public let maxPageCount: Int
    public let quality: CGFloat
    public let format: String
    public let filter: String
    public let includeBase64: Bool
    public let includeText: Bool
    
    /**
     Initializes ScanOptions from a raw dictionary.
     - Parameters:
       - dictionary: The options dictionary from React Native.
       - fallbackPageCount: Default page count if not specified (usually from the scan).
     */
    public init(from dictionary: [String: Any]?, fallbackPageCount: Int) {
        self.maxPageCount = dictionary?["maxPageCount"] as? Int ?? fallbackPageCount
        self.quality = dictionary?["quality"] as? CGFloat ?? 1.0
        self.format = dictionary?["format"] as? String ?? "jpg"
        self.filter = dictionary?["filter"] as? String ?? "color"
        self.includeBase64 = dictionary?["includeBase64"] as? Bool ?? false
        self.includeText = dictionary?["includeText"] as? Bool ?? false
    }
    
    /** Converts to ImageProcessingOptions for the shared pipeline. */
    public func toImageProcessingOptions() -> ImageProcessingOptions {
        return ImageProcessingOptions(
            quality: quality,
            format: format,
            filter: filter,
            includeBase64: includeBase64,
            includeText: includeText
        )
    }
}


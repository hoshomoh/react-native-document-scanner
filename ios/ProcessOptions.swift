import Foundation
import UIKit

/**
 Strongly-typed representation of process options.
 Parses the raw dictionary from React Native for processDocuments.
 */
public struct ProcessOptions {
    public let images: [String]
    public let quality: CGFloat
    public let format: String
    public let filter: String
    public let includeBase64: Bool
    public let includeText: Bool
    
    /**
     Initializes ProcessOptions from a raw dictionary.
     - Parameter dictionary: The options dictionary from React Native.
     - Returns: nil if 'images' array is missing.
     */
    public init?(from dictionary: [String: Any]?) {
        guard let dict = dictionary,
              let images = dict["images"] as? [String] else {
            return nil
        }
        
        self.images = images
        self.quality = dict["quality"] as? CGFloat ?? 1.0
        self.format = dict["format"] as? String ?? "jpg"
        self.filter = dict["filter"] as? String ?? "color"
        self.includeBase64 = dict["includeBase64"] as? Bool ?? false
        self.includeText = dict["includeText"] as? Bool ?? true /* Default true for processing */
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

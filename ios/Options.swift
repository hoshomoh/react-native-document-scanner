import Foundation
import UIKit

/**
 Base options shared by both Scan and Process operations.
 Contains configuration for image output and OCR processing.
 */
public class BaseOptions {
    public let quality: CGFloat
    public let format: String
    public let filter: String
    public let includeBase64: Bool
    public let includeText: Bool
    public let textVersion: Int

    init(quality: CGFloat, format: String, filter: String, includeBase64: Bool, includeText: Bool, textVersion: Int) {
        self.quality = quality
        self.format = format
        self.filter = filter
        self.includeBase64 = includeBase64
        self.includeText = includeText
        self.textVersion = textVersion
    }

    /**
     Reads an integer option from the bridge dictionary.
     Covers NSNumber, Int, and Double — all three bridging representations that can appear
     depending on whether the call comes through the old bridge or JSI (new arch).
     */
    static func intOption(from dictionary: [String: Any]?, key: String, fallback: Int) -> Int {
        guard let raw = dictionary?[key] else { return fallback }
        if let n = raw as? NSNumber { return n.intValue }
        if let i = raw as? Int { return i }
        if let d = raw as? Double { return Int(d) }
        return fallback
    }

    /**
     Convenience initializer to parse common options from a dictionary.
     - Parameters:
       - dictionary: Raw options dictionary.
       - defaultIncludeText: Default value for includeText (Scan defaults to false, Process to true).
     */
    init(from dictionary: [String: Any]?, defaultIncludeText: Bool) {
        /* Quality: Clamp [0.1, 1.0] */
        let q = dictionary?["quality"] as? CGFloat ?? 1.0
        self.quality = max(0.1, min(1.0, q))

        /* Format: whitelist [jpg, png] */
        let f = dictionary?["format"] as? String ?? "jpg"
        self.format = (f == "png") ? "png" : "jpg"

        /* Filter: whitelist supported types */
        let filterInput = dictionary?["filter"] as? String ?? "color"
        let validFilters = ["color", "grayscale", "monochrome", "denoise", "sharpen", "ocrOptimized"]
        self.filter = validFilters.contains(filterInput) ? filterInput : "color"

        self.includeBase64 = dictionary?["includeBase64"] as? Bool ?? false
        self.includeText = dictionary?["includeText"] as? Bool ?? defaultIncludeText

        /* Text Version: allow [1, 2]. */
        let rawVersion = BaseOptions.intOption(from: dictionary, key: "textVersion", fallback: 2)
        self.textVersion = (rawVersion == 1) ? 1 : 2
    }
}

/**
 Strongly-typed representation of scan options.
 Parses the raw dictionary from React Native and provides defaults.
 */
public class ScanOptions: BaseOptions {
    public let maxPageCount: Int

    /**
     Initializes ScanOptions from a raw dictionary.
     - Parameters:
       - dictionary: The options dictionary from React Native.
       - fallbackPageCount: Default page count if not specified.
     */
    public init(from dictionary: [String: Any]?, fallbackPageCount: Int) {
        /* Max Page Count: Clamp [0, 100]. 0 = unlimited. */
        let rawMax = BaseOptions.intOption(from: dictionary, key: "maxPageCount", fallback: fallbackPageCount)
        self.maxPageCount = max(0, min(100, rawMax))

        super.init(from: dictionary, defaultIncludeText: false)
    }
}

/**
 Strongly-typed representation of process options.
 Parses the raw dictionary from React Native for processDocuments.
 */
public class ProcessOptions: BaseOptions {
    public let images: [String]

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
        super.init(from: dictionary, defaultIncludeText: true)
    }
}

import Foundation

/** Represents the geometric bounds of a text block in normalized coordinates (0.0 - 1.0). */
public struct Frame: Encodable {
    /// Horizontal position of the top-left corner.
    public let x: Double
    /// Vertical position of the top-left corner.
    public let y: Double
    /// Width of the bounding box.
    public let width: Double
    /// Height of the bounding box.
    public let height: Double
}

/** Represents a recognized block of text with its position and confidence level. */
public struct TextBlock: Encodable {
    /// The recognized text string.
    public let text: String
    /// The bounding box of the text.
    public let frame: Frame
    /// The confidence level of the recognition (0.0 - 1.0).
    public let confidence: Double?
}

/** Represents the final result of a scanned page. */
public struct ScanResult: Encodable {
    public let uri: String?
    public let base64: String?
    public let text: String?
    public let blocks: [TextBlock]?
    
    /** Converts the struct to a Dictionary for React Native bridge. */
    public var dictionary: [String: Any] {
        var dict: [String: Any] = [:]
        
        if let uri = uri { dict["uri"] = uri }
        if let base64 = base64 { dict["base64"] = base64 }
        if let text = text { dict["text"] = text }
        
        if let blocks = blocks {
            /* Manually map blocks to ensure correct structure. */
            dict["blocks"] = blocks.map { block in
                var blockDict: [String: Any] = [
                    "text": block.text,
                    "frame": [
                        "x": block.frame.x,
                        "y": block.frame.y,
                        "width": block.frame.width,
                        "height": block.frame.height
                    ]
                ]
                if let confidence = block.confidence {
                    blockDict["confidence"] = confidence
                }
                return blockDict
            }
        }
        
        return dict
    }
}

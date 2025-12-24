import Foundation

/** Represents the geometric bounds of a text block. */
public struct Frame: Encodable {
    public let x: Double
    public let y: Double
    public let width: Double
    public let height: Double
}

/** Represents a recognized block of text. */
public struct TextBlock: Encodable {
    public let text: String
    public let frame: Frame
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

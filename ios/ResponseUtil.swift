import Foundation
import UIKit

/** Utility class for constructing the response objects for React Native. */
public class ResponseUtil {
    
    /**
     Constructs the ScanResult struct.
     - Parameters:
       - uri: The local file path.
       - text: Optional OCR text.
       - blocks: Optional OCR blocks.
       - base64: Optional Base64 string.
     - Returns: A `ScanResult` struct.
     */
    public static func buildResult(uri: String?, base64: String?, text: String?, blocks: [TextBlock]?, metadata: ScanMetadata) -> ScanResult {
        return ScanResult(
            uri: uri,
            base64: base64,
            text: text,
            blocks: blocks,
            metadata: metadata
        )
    }
}

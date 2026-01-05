import Foundation
import UIKit

/**
 Centralized image processing pipeline.
 Shared by scanDocuments and processDocuments to avoid code duplication.
 */
public class ImageProcessor {
    
    /**
     Processes a single image through the full pipeline.
     - Parameters:
       - image: The UIImage to process.
       - options: Processing configuration (BaseOptions).
     - Returns: A ScanResult containing the processed data.
     */
    public static func process(_ image: UIImage, options: BaseOptions) -> ScanResult {
        /* 1. Apply Filter */
        let filteredImage = ImageUtil.applyFilter(image, filterType: options.filter) ?? image
        
        /* 2. Save to File */
        var uri: String?
        do {
            uri = try ImageUtil.saveImage(filteredImage, quality: options.quality, format: options.format)
        } catch {
            Logger.error("Error saving image: \(error.localizedDescription)")
        }
        
        /* 3. Generate Base64 (if requested) */
        var base64: String?
        if options.includeBase64 {
            base64 = ImageUtil.base64(from: filteredImage, format: options.format, quality: options.quality)
        }
        
        /* 4. Perform OCR (if requested) */
        var text: String?
        var blocks: [TextBlock]?
        if options.includeText {
            if let ocrResult = TextRecognizer.recognizeText(from: filteredImage, version: options.textVersion) {
                text = ocrResult.text
                blocks = ocrResult.blocks
            }
        }
        
        /* 5. Build Result */
        return ResponseUtil.buildResult(
            uri: uri,
            base64: base64,
            text: text,
            blocks: blocks
        )
    }
    
    /**
     Processes an array of images.
     - Parameters:
       - images: Array of UIImage objects.
       - options: Processing configuration.
     - Returns: Array of ScanResult.
     */
    public static func processAll(_ images: [UIImage], options: BaseOptions) -> [ScanResult] {
        return images.map { process($0, options: options) }
    }
}

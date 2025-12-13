import Foundation
import UIKit

/**
 Options for processing a single image.
 Used internally by both scanDocuments and processDocuments.
 */
public struct ImageProcessingOptions {
    public let quality: CGFloat
    public let format: String
    public let filter: String
    public let includeBase64: Bool
    public let includeText: Bool
    
    public init(quality: CGFloat = 1.0, format: String = "jpg", filter: String = "color", includeBase64: Bool = false, includeText: Bool = false) {
        self.quality = quality
        self.format = format
        self.filter = filter
        self.includeBase64 = includeBase64
        self.includeText = includeText
    }
}

/**
 Centralized image processing pipeline.
 Shared by scanDocuments and processDocuments to avoid code duplication.
 */
public class ImageProcessor {
    
    /**
     Processes a single image through the full pipeline.
     - Parameters:
       - image: The UIImage to process.
       - options: Processing configuration.
     - Returns: A ScanResult containing the processed data.
     */
    public static func process(_ image: UIImage, options: ImageProcessingOptions) -> ScanResult {
        /* 1. Apply Filter */
        let filteredImage = ImageUtil.applyFilter(image, filterType: options.filter) ?? image
        
        /* 2. Save to File */
        var uri: String?
        do {
            uri = try ImageUtil.saveImage(filteredImage, quality: options.quality, format: options.format)
        } catch {
            Logger.error(LogMessages.errorSaving(error))
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
            if let ocrResult = TextRecognizer.recognizeText(from: filteredImage) {
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
    public static func processAll(_ images: [UIImage], options: ImageProcessingOptions) -> [ScanResult] {
        return images.map { process($0, options: options) }
    }
}

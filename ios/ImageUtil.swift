import Foundation
import UIKit
import CoreImage

/**
 Utility class for image operations.
 Handles filtering, encoding, and file system operations.
 */
public class ImageUtil {
    
    /* ----------------------------------------------------------------------- */
    /* Loading                                                                 */
    /* ----------------------------------------------------------------------- */
    
    /**
     Loads a UIImage from a source string.
     - Parameter source: Can be a file URI, data URI, or raw base64 string.
     - Returns: The loaded UIImage, or nil if loading fails.
     */
    public static func loadImage(from source: String) -> UIImage? {
        /* File URL (file:// or absolute path) */
        if source.hasPrefix("file://") || source.hasPrefix("/") {
            let path = source.hasPrefix("file://") ? String(source.dropFirst(7)) : source
            return UIImage(contentsOfFile: path)
        }
        
        /* Data URI (e.g., data:image/png;base64,...) */
        if source.hasPrefix("data:") {
            if let commaIndex = source.firstIndex(of: ",") {
                let base64String = String(source[source.index(after: commaIndex)...])
                if let data = Data(base64Encoded: base64String) {
                    return UIImage(data: data)
                }
            }
            return nil
        }
        
        /* Raw base64 string */
        if let data = Data(base64Encoded: source) {
            return UIImage(data: data)
        }
        
        Logger.warn("Could not load image from source: \(source.prefix(50))...")
        return nil
    }
    
    /* ----------------------------------------------------------------------- */
    /* Filtering                                                               */
    /* ----------------------------------------------------------------------- */
    
    /**
     Applies a CoreImage filter to the image.
     - Parameters:
       - image: The input UIImage.
       - filterType: The filter name ('grayscale', 'monochrome').
     - Returns: The filtered UIImage, or nil if filtering fails.
     */
    public static func applyFilter(_ image: UIImage, filterType: String) -> UIImage? {
        if filterType == "color" { return image }
        
        guard let ciImage = CIImage(image: image) else { return nil }
        
        var outputImage: CIImage?
        
        if filterType == "grayscale" {
            if let filter = CIFilter(name: "CIPhotoEffectMono") {
                filter.setValue(ciImage, forKey: kCIInputImageKey)
                outputImage = filter.outputImage
            }
        } else if filterType == "monochrome" {
            if let filter = CIFilter(name: "CIPhotoEffectNoir") {
                filter.setValue(ciImage, forKey: kCIInputImageKey)
                outputImage = filter.outputImage
            }
        } else if filterType == "denoise" {
            /* CINoiseReduction reduces image noise, improving OCR on noisy photos */
            if let filter = CIFilter(name: "CINoiseReduction") {
                filter.setValue(ciImage, forKey: kCIInputImageKey)
                filter.setValue(0.02, forKey: "inputNoiseLevel")
                filter.setValue(0.4, forKey: "inputSharpness")
                outputImage = filter.outputImage
            }
        } else if filterType == "sharpen" {
            /* CISharpenLuminance enhances edge clarity for blurry text */
            if let filter = CIFilter(name: "CISharpenLuminance") {
                filter.setValue(ciImage, forKey: kCIInputImageKey)
                filter.setValue(0.8, forKey: kCIInputSharpnessKey)
                outputImage = filter.outputImage
            }
        }
        
        guard let finalCIImage = outputImage else { return nil }
        
        let context = CIContext(options: nil)
        if let cgImage = context.createCGImage(finalCIImage, from: finalCIImage.extent) {
            return UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
        }
        
        return nil
    }
    
    /* ----------------------------------------------------------------------- */
    /* Encoding                                                                */
    /* ----------------------------------------------------------------------- */
    
    /**
     Converts an image to Base64 string.
     - Parameters:
       - image: The image to encode.
       - format: "jpg" or "png".
       - quality: Compression quality for JPEG.
     - Returns: Base64 encoded string, or nil if encoding fails.
     */
    public static func base64(from image: UIImage, format: String, quality: CGFloat) -> String? {
        let data = imageData(from: image, format: format, quality: quality)
        return data?.base64EncodedString()
    }
    
    /* ----------------------------------------------------------------------- */
    /* File Operations                                                         */
    /* ----------------------------------------------------------------------- */
    
    /**
     Generates a unique file path in the temporary directory.
     - Parameter format: The file extension (e.g., "jpg", "png").
     - Returns: A unique URL.
     */
    public static func createTempFileURL(format: String) -> URL {
        let fileManager = FileManager.default
        let tempDir = fileManager.temporaryDirectory
        let uuid = UUID().uuidString
        let fileName = "\(uuid).\(format)"
        return tempDir.appendingPathComponent(fileName)
    }
    
    /**
     Saves a UIImage to the file system.
     - Parameters:
       - image: The image to save.
       - quality: Compression quality (0.0 - 1.0).
       - format: "jpg" or "png".
     - Returns: The absolute path string of the saved file.
     */
    public static func saveImage(_ image: UIImage, quality: CGFloat, format: String) throws -> String {
        let fileURL = createTempFileURL(format: format)
        
        guard let data = imageData(from: image, format: format, quality: quality) else {
            throw ScannerError.operationFailed("Could not generate data for image.")
        }
        
        do {
            try data.write(to: fileURL)
            return fileURL.absoluteString
        } catch {
            throw ScannerError.operationFailed(error.localizedDescription)
        }
    }
    
    /* ----------------------------------------------------------------------- */
    /* Private Helpers                                                         */
    /* ----------------------------------------------------------------------- */
    
    /**
     Converts a UIImage to Data in the specified format.
     - Parameters:
       - image: The image to convert.
       - format: "jpg" or "png".
       - quality: Compression quality for JPEG.
     - Returns: Image data, or nil if conversion fails.
     */
    private static func imageData(from image: UIImage, format: String, quality: CGFloat) -> Data? {
        if format == "png" {
            return image.pngData()
        } else {
            return image.jpegData(compressionQuality: quality)
        }
    }
}

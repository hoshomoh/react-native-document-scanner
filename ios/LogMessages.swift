import Foundation

/**
 Centralized storage for log messages.
 This avoids hardcoded strings scattered throughout the codebase.
 */
enum LogMessages {
    static let missingCGImage = "Could not retrieve CGImage from input."
    static let noTextFound = "No text found in image."
    
    static func errorSaving(_ error: Error) -> String {
        return "Error saving image: \(error.localizedDescription)"
    }
    
    static func recognitionFailed(_ error: Error) -> String {
        return "Text recognition request failed: \(error.localizedDescription)"
    }
}

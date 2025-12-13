import Foundation

/** Custom error types for the Document Scanner. */
enum ScannerError: Error {
    case notSupported
    case uiError(String)
    case scanError(String)
    case canceled
    case fileSystemError(String)
    case filterError(String)
    case invalidOptions(String)
    case noValidImages
}

extension ScannerError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .notSupported:
            return "Device does not support document scanning."
        case .uiError(let msg):
            return "UI Error: \(msg)"
        case .scanError(let msg):
            return "Scan Failed: \(msg)"
        case .canceled:
            return "User canceled the scan."
        case .fileSystemError(let msg):
            return "File System Error: \(msg)"
        case .filterError(let msg):
            return "Filter Error: \(msg)"
        case .invalidOptions(let msg):
            return "Invalid Options: \(msg)"
        case .noValidImages:
            return "Could not load any valid images from the provided sources."
        }
    }
}


import Foundation

/**
 * Custom error types for the Document Scanner.
 * Used for communicating structured failure states back to the React Native bridge.
 */
enum ScannerError: Error {
    /// Device hardware or OS version is unsupported.
    case notSupported
    /// Invalid configuration or missing options.
    case configurationError(String)
    /// A runtime failure occurred during processing.
    case operationFailed(String)
    /// The user cancelled the scanning process.
    case canceled
}

extension ScannerError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .notSupported:
            return "Device does not support document scanning."
        case .configurationError(let msg):
            return "Configuration Error: \(msg)"
        case .operationFailed(let msg):
            return "Operation Failed: \(msg)"
        case .canceled:
            return "User canceled the scan."
        }
    }
}



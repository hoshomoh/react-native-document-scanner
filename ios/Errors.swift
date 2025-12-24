import Foundation

/** Custom error types for the Document Scanner. */
enum ScannerError: Error {
    case notSupported
    case configurationError(String)
    case operationFailed(String)
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



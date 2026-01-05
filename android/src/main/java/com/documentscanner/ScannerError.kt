package com.documentscanner

/**
 * Represents structured errors returned to the React Native layer.
 */
sealed class ScannerError(val code: String, val message: String) {
    /** The device hardware or OS version does not support scanning. */
    class NotSupported : ScannerError("NOT_SUPPORTED", "Device does not support document scanning")
    
    /** The provided options were invalid or missing required fields. */
    class ConfigurationError(detail: String) : ScannerError("CONFIGURATION_ERROR", "Configuration Error: $detail")
    
    /** A runtime error occurred during scanning or processing. */
    class OperationFailed(detail: String) : ScannerError("OPERATION_FAILED", "Operation Failed: $detail")
    
    /** The user manually cancelled the scanner interface. */
    class Canceled : ScannerError("CANCELED", "User canceled the scan")
}

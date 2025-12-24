package com.documentscanner

sealed class ScannerError(val code: String, val message: String) {
    class NotSupported : ScannerError("NOT_SUPPORTED", "Device does not support document scanning")
    class ConfigurationError(detail: String) : ScannerError("CONFIGURATION_ERROR", "Configuration Error: $detail")
    class OperationFailed(detail: String) : ScannerError("OPERATION_FAILED", "Operation Failed: $detail")
    class Canceled : ScannerError("CANCELED", "User canceled the scan")
}

import Foundation

/**
 A centralized logging utility for the Document Scanner.
 Use this instead of `print` to ensure consistent formatting and easy disabling of logs in production.
 */
public class Logger {
    private static let prefix = "[DocumentScanner]"
    
    /**
     Logs an informational message.
     - Parameter message: The message string.
     */
    public static func info(_ message: String) {
        print("\(prefix) ℹ️ Info: \(message)")
    }
    
    /**
     Logs a warning message.
     - Parameter message: The message string.
     */
    public static func warn(_ message: String) {
        print("\(prefix) ⚠️ Warning: \(message)")
    }
    
    /**
     Logs an error message.
     - Parameter message: The message string.
     */
    public static func error(_ message: String) {
        print("\(prefix) ❌ Error: \(message)")
    }
    
    /**
     Logs a debug message.
     - Parameter message: The message string.
     */
    public static func debug(_ message: String) {
        #if DEBUG
        print("\(prefix) 🐛 Debug: \(message)")
        #endif
    }
}

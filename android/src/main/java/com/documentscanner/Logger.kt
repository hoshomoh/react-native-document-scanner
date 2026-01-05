package com.documentscanner

import android.util.Log

/**
 * Centralized logging utility for the Document Scanner.
 * Uses Android's native Log system with a consistent tag and visual indicators.
 */
object Logger {
    private const val TAG = "DocumentScanner"

    /**
     * Logs an informational message.
     */
    fun log(message: String) {
        Log.d(TAG, "ℹ️ $message")
    }

    /**
     * Logs a warning message.
     */
    fun warn(message: String) {
        Log.w(TAG, "⚠️ $message")
    }

    /**
     * Logs an error message with an optional exception.
     */
    fun error(message: String, throwable: Throwable? = null) {
        if (throwable != null) {
            Log.e(TAG, "❌ $message", throwable)
        } else {
            Log.e(TAG, "❌ $message")
        }
    }
}

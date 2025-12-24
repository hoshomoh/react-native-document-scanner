package com.documentscanner

import android.util.Log

object Logger {
    private const val TAG = "DocumentScanner"

    fun log(message: String) {
        Log.d(TAG, "ℹ️ $message")
    }

    fun warn(message: String) {
        Log.w(TAG, "⚠️ $message")
    }

    fun error(message: String, throwable: Throwable? = null) {
        if (throwable != null) {
            Log.e(TAG, "❌ $message", throwable)
        } else {
            Log.e(TAG, "❌ $message")
        }
    }
}

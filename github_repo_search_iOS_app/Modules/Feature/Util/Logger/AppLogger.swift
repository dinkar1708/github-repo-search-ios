//
//  AppLogger.swift
//  github_repo_search_iOS_app
//
//  Structured logging using OSLog (WWDC 2024 best practice)
//  Replaces print() statements with production-ready logging
//

import OSLog

/**
 Centralized logging utility using OSLog
 Based on WWDC 2024 recommendations for structured logging

 Usage:
 ```
 AppLogger.network.info("API request started")
 AppLogger.network.error("API failed: \(error.localizedDescription)")
 ```
 */
enum AppLogger {

    // MARK: - Log Categories

    /// Networking and API related logs
    static let network = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.app.github", category: "networking")

    /// ViewModel state and business logic
    static let viewModel = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.app.github", category: "viewModel")

    /// Data persistence and favorites
    static let persistence = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.app.github", category: "persistence")

    /// UI interactions and view lifecycle
    static let ui = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.app.github", category: "ui")

    /// General application logs
    static let app = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.app.github", category: "app")

    // MARK: - Helper Methods

    /// Log network request with privacy protection
    static func logRequest(url: String, method: String) {
        network.info("🌐 \(method) request to \(url, privacy: .public)")
    }

    /// Log network response with status code
    static func logResponse(url: String, statusCode: Int) {
        if (200...299).contains(statusCode) {
            network.info("✅ Response from \(url, privacy: .public) - Status: \(statusCode)")
        } else {
            network.error("❌ Response from \(url, privacy: .public) - Status: \(statusCode)")
        }
    }

    /// Log API error with details
    static func logError(_ error: Error, context: String = "") {
        network.error("❌ Error: \(error.localizedDescription) | Context: \(context)")
    }

    /// Log retry attempt
    static func logRetry(attempt: Int, maxRetries: Int) {
        network.warning("🔄 Retry attempt \(attempt) of \(maxRetries)")
    }

    /// Log ViewModel state change
    static func logStateChange(viewModel: String, state: String) {
        self.viewModel.debug("🔄 \(viewModel) state changed to: \(state)")
    }

    /// Log data persistence operation
    static func logPersistence(operation: String, success: Bool) {
        if success {
            persistence.info("💾 \(operation) - Success")
        } else {
            persistence.error("💾 \(operation) - Failed")
        }
    }
}

// MARK: - Privacy Extensions

extension Logger {
    /// Log with automatic privacy redaction for sensitive data
    func logSensitive(_ message: String) {
        self.info("\(message, privacy: .private)")
    }

    /// Log with public visibility (safe for sharing)
    func logPublic(_ message: String) {
        self.info("\(message, privacy: .public)")
    }
}

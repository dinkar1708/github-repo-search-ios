//
//  Logger+Extensions.swift
//  github_repo_search_iOS_app
//
//  Created for structured logging with OSLog
//

import Foundation
import OSLog

// MARK: - Log Category Enum

/// Enum defining all logging categories in the app
/// Makes logging type-safe and prevents typos
enum LogCategory: String, CaseIterable {
    case networking = "networking"
    case viewModel = "viewModel"
    case cache = "cache"
    case favorites = "favorites"
    case analytics = "analytics"
    case ui = "ui"
    case app = "app"
    case storage = "storage"
    case repository = "repository"

    /// Human-readable description of the category
    var description: String {
        switch self {
        case .networking: return "Networking and API calls"
        case .viewModel: return "ViewModels and business logic"
        case .cache: return "Caching operations"
        case .favorites: return "Favorites management"
        case .analytics: return "Analytics and tracking"
        case .ui: return "UI events and interactions"
        case .app: return "App lifecycle events"
        case .storage: return "Storage and persistence"
        case .repository: return "Repository layer"
        }
    }
}

// MARK: - Logger Extension

extension Logger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.app.github"

    /// Create a logger for a specific category
    /// - Parameter category: The logging category
    /// - Returns: Configured logger
    static func make(category: LogCategory) -> Logger {
        Logger(subsystem: subsystem, category: category.rawValue)
    }

    // MARK: - Convenience Loggers

    /// Logger for networking and API calls
    static let networking = Logger.make(category: .networking)

    /// Logger for ViewModels and business logic
    static let viewModel = Logger.make(category: .viewModel)

    /// Logger for caching operations
    static let cache = Logger.make(category: .cache)

    /// Logger for favorites and data persistence
    static let favorites = Logger.make(category: .favorites)

    /// Logger for analytics and tracking
    static let analytics = Logger.make(category: .analytics)

    /// Logger for UI events
    static let ui = Logger.make(category: .ui)

    /// Logger for general app lifecycle
    static let app = Logger.make(category: .app)

    /// Logger for storage operations
    static let storage = Logger.make(category: .storage)

    /// Logger for repository layer
    static let repository = Logger.make(category: .repository)
}

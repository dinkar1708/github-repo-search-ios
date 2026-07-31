//
//  AnalyticsService.swift
//  github_repo_search_iOS_app
//
//  Created for analytics tracking abstraction
//

import Foundation
import OSLog

// MARK: - Protocol

/// Service for tracking user analytics and events
protocol AnalyticsService: Sendable {
    func track(event: AnalyticsEvent)
    func setUserProperty(key: String, value: String)
    func setScreen(name: String)
}

// MARK: - Analytics Events

enum AnalyticsEvent: Sendable {
    case searchPerformed(query: String, resultCount: Int)
    case repositoryViewed(name: String, owner: String)
    case userProfileViewed(username: String)
    case favoriteAdded(type: AnalyticsFavoriteType)
    case favoriteRemoved(type: AnalyticsFavoriteType)
    case tabChanged(tab: String)
    case settingsChanged(setting: String, value: String)

    var name: String {
        switch self {
        case .searchPerformed: return "search_performed"
        case .repositoryViewed: return "repository_viewed"
        case .userProfileViewed: return "user_profile_viewed"
        case .favoriteAdded: return "favorite_added"
        case .favoriteRemoved: return "favorite_removed"
        case .tabChanged: return "tab_changed"
        case .settingsChanged: return "settings_changed"
        }
    }

    var parameters: [String: Any] {
        switch self {
        case .searchPerformed(let query, let count):
            return ["query": query, "result_count": count]
        case .repositoryViewed(let name, let owner):
            return ["repository_name": name, "owner": owner]
        case .userProfileViewed(let username):
            return ["username": username]
        case .favoriteAdded(let type):
            return ["favorite_type": type.rawValue]
        case .favoriteRemoved(let type):
            return ["favorite_type": type.rawValue]
        case .tabChanged(let tab):
            return ["tab_name": tab]
        case .settingsChanged(let setting, let value):
            return ["setting": setting, "value": value]
        }
    }
}

enum AnalyticsFavoriteType: String, Sendable {
    case user
    case repository
}

// MARK: - Default Implementation

final class DefaultAnalyticsService: AnalyticsService {
    private let logger = Logger.analytics

    func track(event: AnalyticsEvent) {
        logger.info("📊 \(event.name): \(String(describing: event.parameters))")

        // TODO: Integrate with Firebase Analytics, Mixpanel, or other service
        // Example:
        // Analytics.logEvent(event.name, parameters: event.parameters)
    }

    func setUserProperty(key: String, value: String) {
        logger.info("👤 User property set: \(key) = \(value, privacy: .private)")

        // TODO: Integrate with analytics service
        // Example:
        // Analytics.setUserProperty(value, forName: key)
    }

    func setScreen(name: String) {
        logger.info("📱 Screen viewed: \(name)")

        // TODO: Integrate with analytics service
        // Example:
        // Analytics.logEvent(AnalyticsEventScreenView, parameters: [
        //     AnalyticsParameterScreenName: name
        // ])
    }
}

// MARK: - Mock Implementation for Tests

final class MockAnalyticsService: AnalyticsService {
    var trackedEvents: [AnalyticsEvent] = []
    var userProperties: [String: String] = [:]
    var screenViews: [String] = []

    func track(event: AnalyticsEvent) {
        trackedEvents.append(event)
    }

    func setUserProperty(key: String, value: String) {
        userProperties[key] = value
    }

    func setScreen(name: String) {
        screenViews.append(name)
    }

    func reset() {
        trackedEvents.removeAll()
        userProperties.removeAll()
        screenViews.removeAll()
    }
}

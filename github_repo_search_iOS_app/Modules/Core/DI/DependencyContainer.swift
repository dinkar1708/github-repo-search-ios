//
//  DependencyContainer.swift
//  github_repo_search_iOS_app
//
//  Created for dependency injection infrastructure
//

import Foundation

/// Lightweight dependency injection container
/// Provides compile-time safe dependency resolution using property wrappers
@MainActor
final class DependencyContainer: @unchecked Sendable {
    static var shared = DependencyContainer()

    // MARK: - Repositories
    let githubRepository: GithubRepository
    let favoritesRepository: FavoritesRepository

    // MARK: - Services
    let cacheService: CacheService
    let analyticsService: AnalyticsService

    // MARK: - Initialization

    private init(
        githubRepository: GithubRepository? = nil,
        favoritesRepository: FavoritesRepository? = nil,
        cacheService: CacheService? = nil,
        analyticsService: AnalyticsService? = nil
    ) {
        self.githubRepository = githubRepository ?? DefaultGithubRepository()
        self.favoritesRepository = favoritesRepository ?? KeychainFavoritesRepository()
        self.cacheService = cacheService ?? DefaultCacheService()
        self.analyticsService = analyticsService ?? DefaultAnalyticsService()
    }

    // MARK: - Test Configuration

    /// Creates a test container with mock dependencies
    static func test(
        githubRepository: GithubRepository? = nil,
        favoritesRepository: FavoritesRepository? = nil,
        cacheService: CacheService? = nil,
        analyticsService: AnalyticsService? = nil
    ) -> DependencyContainer {
        DependencyContainer(
            githubRepository: githubRepository,
            favoritesRepository: favoritesRepository,
            cacheService: cacheService,
            analyticsService: analyticsService
        )
    }
}

// MARK: - Property Wrapper for Dependency Injection

/// Property wrapper for injecting dependencies from the container
/// Usage: @Injected(\.githubRepository) private var repository
@propertyWrapper
struct Injected<T> {
    private let keyPath: KeyPath<DependencyContainer, T>

    @MainActor
    public var wrappedValue: T {
        DependencyContainer.shared[keyPath: keyPath]
    }

    public init(_ keyPath: KeyPath<DependencyContainer, T>) {
        self.keyPath = keyPath
    }
}

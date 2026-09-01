//
//  UserSearchViewModel.swift
//  github_repo_search_iOS_app
//
//  Created for User Search feature (Feature 1.2)
//

import Foundation
import Observation
import OSLog

@Observable
@MainActor
final class UserSearchViewModel {
    private let repository: GithubRepository
    private let analytics: AnalyticsService
    private let cache: CacheService

    private let logger = Logger.viewModel

    var users: [User] = []
    var isLoading = false
    var errorMessage: String?
    var searchText = ""
    var currentPage = 1
    var hasMorePages = true

    private var searchTask: Task<Void, Never>?

    init(
        repository: GithubRepository? = nil,
        analytics: AnalyticsService? = nil,
        cache: CacheService? = nil
    ) {
        self.repository = repository ?? DependencyContainer.shared.githubRepository
        self.analytics = analytics ?? DependencyContainer.shared.analyticsService
        self.cache = cache ?? DependencyContainer.shared.cacheService
    }

    func searchUsers() {
        searchTask?.cancel()

        // Require minimum 2 characters
        guard !searchText.isEmpty, searchText.count >= 2 else {
            users = []
            currentPage = 1
            hasMorePages = true
            errorMessage = nil
            return
        }

        searchTask = Task {
            // Debounce: wait 800ms before searching
            try? await Task.sleep(for: .milliseconds(800))

            // Check if task was cancelled during sleep
            guard !Task.isCancelled else { return }

            // Reset state for new search
            isLoading = true
            errorMessage = nil
            currentPage = 1

            logger.info("Searching users for query: '\(self.searchText, privacy: .public)'")

            do {
                // Check cache first
                let cacheKey = "users:\(searchText):page:\(currentPage)"
                if let cached: SearchUser = cache.get(key: cacheKey) {
                    logger.debug("Cache hit for user search")
                    users = cached.items
                    hasMorePages = cached.items.count == 30
                    isLoading = false
                    return
                }

                let response = try await repository.searchUsers(
                    query: searchText,
                    perPage: 30,
                    page: currentPage
                )

                // Check if cancelled after API call
                guard !Task.isCancelled else {
                    isLoading = false
                    return
                }

                // Cache the response
                cache.set(response, for: cacheKey, ttl: 300)

                // Track analytics
                analytics.track(event: .searchPerformed(query: searchText, resultCount: response.totalCount))

                users = response.items
                hasMorePages = response.items.count == 30
                isLoading = false

                logger.info("User search completed: \(response.items.count) users found")
            } catch let error as ApiResponseError {
                guard !Task.isCancelled else {
                    isLoading = false
                    return
                }
                let networkError = NetworkError.from(error)
                logger.error("User search error: \(networkError.userMessage)")
                errorMessage = networkError.userMessage
                users = []
                isLoading = false
            } catch {
                // Only show error if task wasn't cancelled
                guard !Task.isCancelled else {
                    isLoading = false
                    return
                }
                logger.error("Unexpected user search error: \(error.localizedDescription)")
                errorMessage = error.localizedDescription
                users = []
                isLoading = false
            }
        }
    }

    func loadMoreUsers() {
        guard !isLoading, hasMorePages, !searchText.isEmpty else { return }

        Task {
            isLoading = true
            currentPage += 1

            logger.info("Loading more users, page: \(self.currentPage)")

            do {
                let cacheKey = "users:\(searchText):page:\(currentPage)"
                if let cached: SearchUser = cache.get(key: cacheKey) {
                    users.append(contentsOf: cached.items)
                    hasMorePages = cached.items.count == 30
                    isLoading = false
                    return
                }

                let response = try await repository.searchUsers(
                    query: searchText,
                    perPage: 30,
                    page: currentPage
                )

                cache.set(response, for: cacheKey, ttl: 300)

                users.append(contentsOf: response.items)
                hasMorePages = response.items.count == 30
            } catch let error as ApiResponseError {
                let networkError = NetworkError.from(error)
                logger.error("Load more error: \(networkError.userMessage)")
                errorMessage = networkError.userMessage
                currentPage -= 1
            } catch {
                logger.error("Unexpected load more error: \(error.localizedDescription)")
                errorMessage = error.localizedDescription
                currentPage -= 1
            }

            isLoading = false
        }
    }

    func refresh() {
        searchUsers()
    }
}

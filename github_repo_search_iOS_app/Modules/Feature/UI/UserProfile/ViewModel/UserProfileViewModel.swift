//
//  UserProfileViewModel.swift
//  github_repo_search_iOS_app
//
//  Created for User Profile feature (Feature 1.3)
//

import Foundation
import Observation
import OSLog

@Observable
@MainActor
final class UserProfileViewModel {
    @ObservationIgnored @Injected(\.githubRepository) private var repository
    @ObservationIgnored @Injected(\.analyticsService) private var analytics
    @ObservationIgnored @Injected(\.cacheService) private var cache

    private let logger = Logger.viewModel

    var userProfile: UserProfile?
    var userRepositories: [UserRepository] = []
    var isLoading = false
    var isLoadingMore = false
    var errorMessage: String?
    var showForksOnly = false

    private var currentPage = 1
    private let perPage = 30
    private var hasMoreData = true

    init() { }

    var filteredRepositories: [UserRepository] {
        if showForksOnly {
            return userRepositories.filter { $0.fork }
        }
        return userRepositories
    }

    func loadUserProfile(username: String) async {
        isLoading = true
        errorMessage = nil
        currentPage = 1
        hasMoreData = true

        logger.info("Loading user profile for: \(username, privacy: .public)")

        // Track analytics
        analytics.track(event: .userProfileViewed(username: username))

        do {
            // Check cache for profile
            let profileCacheKey = "profile:\(username)"
            let reposCacheKey = "repos:\(username):page:1"

            let profile: UserProfile
            if let cachedProfile: UserProfile = cache.get(key: profileCacheKey) {
                logger.debug("Cache hit for user profile")
                profile = cachedProfile
            } else {
                profile = try await repository.getUserProfile(username: username)
                cache.set(profile, for: profileCacheKey, ttl: 900) // 15 min
            }

            // Check cache for repos
            let repos: [UserRepository]
            if let cachedRepos: [UserRepository] = cache.get(key: reposCacheKey) {
                logger.debug("Cache hit for user repositories")
                repos = cachedRepos
            } else {
                repos = try await repository.getUserRepositories(username: username, perPage: perPage, page: currentPage)
                // TODO: Cache repos (requires UserRepository to be Encodable)
                // cache.set(repos, for: reposCacheKey, ttl: 900) // 15 min
            }

            userProfile = profile
            userRepositories = repos
            hasMoreData = repos.count >= perPage
            currentPage = 2

            logger.info("User profile loaded: \(repos.count) repositories")
        } catch let error as ApiResponseError {
            let networkError = NetworkError.from(error)
            logger.error("Load user profile error: \(networkError.userMessage)")
            errorMessage = networkError.userMessage
        } catch {
            logger.error("Unexpected load user profile error: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func refresh(username: String) async {
        await loadUserProfile(username: username)
    }

    func toggleForksFilter() {
        showForksOnly.toggle()
    }

    // MARK: - Pagination
    func loadMoreRepositoriesIfNeeded(username: String, currentItem: UserRepository) async {
        guard !isLoadingMore && hasMoreData else { return }

        // Trigger load more when user reaches 5 items from the end
        let thresholdIndex = userRepositories.count - 5
        if let index = userRepositories.firstIndex(where: { $0.id == currentItem.id }),
           index >= thresholdIndex {
            await loadMoreRepositories(username: username)
        }
    }

    private func loadMoreRepositories(username: String) async {
        guard !isLoadingMore && hasMoreData else { return }

        isLoadingMore = true

        logger.info("Loading more repositories, page: \(self.currentPage)")

        do {
            let cacheKey = "repos:\(username):page:\(currentPage)"
            let repos: [UserRepository]

            if let cached: [UserRepository] = cache.get(key: cacheKey) {
                logger.debug("Cache hit for repositories page \(self.currentPage)")
                repos = cached
            } else {
                repos = try await repository.getUserRepositories(username: username, perPage: perPage, page: currentPage)
                // TODO: Cache repos (requires UserRepository to be Encodable)
                // cache.set(repos, for: cacheKey, ttl: 900) // 15 min
            }

            userRepositories.append(contentsOf: repos)
            hasMoreData = repos.count >= perPage
            currentPage += 1
        } catch let error as ApiResponseError {
            let networkError = NetworkError.from(error)
            logger.error("Load more repositories error: \(networkError.userMessage)")
            errorMessage = networkError.userMessage
        } catch {
            logger.error("Unexpected load more error: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }

        isLoadingMore = false
    }
}

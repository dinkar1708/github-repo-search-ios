//
//  UserProfileViewModel.swift
//  github_repo_search_iOS_app
//
//  Created for User Profile feature (Feature 1.3)
//

import Foundation
import Observation

@Observable
@MainActor
final class UserProfileViewModel {
    private let repository: GithubRepository
    var userProfile: UserProfile?
    var userRepositories: [UserRepository] = []
    var isLoading = false
    var isLoadingMore = false
    var errorMessage: String?
    var showForksOnly = false

    private var currentPage = 1
    private let perPage = 30
    private var hasMoreData = true

    init(repository: GithubRepository = DefaultGithubRepository()) {
        self.repository = repository
    }

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

        do {
            async let profile = repository.getUserProfile(username: username)
            let repos = try await repository.getUserRepositories(username: username, perPage: perPage, page: currentPage)

            userProfile = try await profile
            userRepositories = repos
            hasMoreData = repos.count >= perPage
            currentPage = 2
        } catch {
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

        do {
            let repos = try await repository.getUserRepositories(username: username, perPage: perPage, page: currentPage)
            userRepositories.append(contentsOf: repos)
            hasMoreData = repos.count >= perPage
            currentPage += 1
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoadingMore = false
    }
}

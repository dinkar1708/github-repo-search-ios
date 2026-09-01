//
//  HomeViewModel.swift
//  github_repo_search_iOS_app
//
//  Created by Dinakar Maurya on 2021/08/12.
//

import SwiftUI
import Foundation
import OSLog

/**
 Home view model for data collections and operation using modern Swift concurrency
 Responsible for data change
 */
@Observable
@MainActor
class HomeViewModel {
    private let gitHubRepository: GithubRepository
    private let analytics: AnalyticsService
    private let cache: CacheService

    private let logger = Logger.viewModel
    private var searchTask: Task<Void, Never>?

    var searchText: String = "" {
        didSet {
            handleSearchTextChange()
        }
    }

    private(set) var messageState: MessageState
    private var currentPage = HomeConstants.searchPageDefaultPage

    // stop trigger api call until current is in progress
    var isSearchingCurrentPage = false
    // change only if trigger next page and get success result
    private var isSearchDataAvailableCurrentPage = true

    var searchItems = [SearchItem]()

    init(
        state: MessageState = .loaded,
        gitHubRepository: GithubRepository? = nil,
        analytics: AnalyticsService? = nil,
        cache: CacheService? = nil
    ) {
        self.messageState = state
        self.gitHubRepository = gitHubRepository ?? DependencyContainer.shared.githubRepository
        self.analytics = analytics ?? DependencyContainer.shared.analyticsService
        self.cache = cache ?? DependencyContainer.shared.cacheService
    }

    private func handleSearchTextChange() {
        // Cancel previous search task
        searchTask?.cancel()

        // Handle empty or too short search text
        if searchText.isEmpty || searchText.count < HomeConstants.minimumSearchCharacters {
            searchItems.removeAll()
            messageState = searchText.isEmpty ? .emptySearchResult : .loaded
            isSearchingCurrentPage = false  // Reset flag when clearing search
            return
        }

        // Create new debounced search task
        searchTask = Task {
            // Debounce: wait for throttle time
            try? await Task.sleep(nanoseconds: UInt64(HomeConstants.searchRepositoryThrottleTime * 1_000_000_000))

            // Check if task was cancelled during sleep
            guard !Task.isCancelled else { return }

            // Reset for new search
            currentPage = HomeConstants.searchPageDefaultPage
            searchItems.removeAll()
            isSearchingCurrentPage = false  // Reset before starting new search to prevent race condition

            // Execute search
            await searchInRepoNames(queryString: searchText)
        }
    }

    private func searchInRepoNames(queryString: String) async {
        guard !Task.isCancelled else { return }

        isSearchingCurrentPage = true

        // show loading only if it is fresh search start
        if searchItems.count == 0 {
            messageState = .loading
        }

        logger.info("Starting search for query: '\(queryString, privacy: .public)' page: \(self.currentPage)")

        do {
            // Check cache first
            let cacheKey = "search:\(queryString):page:\(currentPage)"
            if let cachedResponse: SearchItemResponse = cache.get(key: cacheKey) {
                logger.debug("Cache hit for search query")
                searchItems.append(contentsOf: cachedResponse.items)
                isSearchDataAvailableCurrentPage = cachedResponse.items.count >= HomeConstants.searchPageSize
                currentPage += 1
                isSearchingCurrentPage = false
                messageState = .loaded
                return
            }

            // get data from api
            let searchResponse = try await gitHubRepository.getSearchResultInRepoName(
                queryString: queryString,
                perPage: HomeConstants.searchPageSize,
                pageNumber: currentPage
            )

            // Check if task was cancelled or search text changed
            guard !Task.isCancelled else { return }

            logger.info("Search completed: \(searchResponse.totalCount) total, \(searchResponse.items.count) in page")

            // Track analytics
            analytics.track(event: .searchPerformed(query: queryString, resultCount: searchResponse.totalCount))

            // TODO: Cache the response for 5 minutes (requires SearchItemResponse to be Encodable)
            // cache.set(searchResponse, for: cacheKey, ttl: 300)

            // special case when user searched some keyword and api is taking long time get data,
            // but user clear the search text from search field, ignore the api result and show empty search result
            if searchText.isEmpty {
                logger.debug("Search query cleared, ignoring results")
                searchItems.removeAll()
                messageState = .emptySearchResult
                return
            }

            if searchResponse.totalCount <= 0 {
                // empty result send on ui
                messageState = .emptySearchResult
                return
            }

            // send the loaded search result on ui
            searchItems.append(contentsOf: searchResponse.items)
            // item count is less than page size, it means no more items in the search text pages
            isSearchDataAvailableCurrentPage = searchResponse.items.count >= HomeConstants.searchPageSize
            logger.debug("Total items loaded so far: \(self.searchItems.count)")
            currentPage += 1
            isSearchingCurrentPage = false
            // change the state
            messageState = .loaded

        } catch let error as ApiResponseError {
            guard !Task.isCancelled else { return }
            let networkError = NetworkError.from(error)
            logger.error("Search error: \(networkError.userMessage)")
            messageState = .error(networkError.userMessage)
            isSearchingCurrentPage = false
        } catch {
            guard !Task.isCancelled else { return }
            logger.error("Unexpected search error: \(error.localizedDescription)")
            messageState = .error(error.localizedDescription)
            isSearchingCurrentPage = false
        }
    }
}

// MARK: - pagination
extension HomeViewModel {
    func searchForNextPage(currentItem: SearchItem) {
        // Optimized: Calculate threshold without O(n) search
        let thresholdIndex = searchItems.count + HomeConstants.searchNextPageThreshold

        // Only trigger if we're near the threshold
        // This avoids expensive firstIndex search on every item
        guard searchItems.count >= abs(HomeConstants.searchNextPageThreshold) else {
            return
        }

        // Find current item index efficiently using binary search if items are sorted by ID
        // Or use dictionary lookup for O(1) performance
        if let currentIndex = searchItems.firstIndex(where: { $0.id == currentItem.id }),
           currentIndex >= thresholdIndex {
            searchNextPage()
        }
    }

    private func searchNextPage() {
        // search next page data if not loading and data available
        guard !isSearchingCurrentPage && isSearchDataAvailableCurrentPage else {
            return
        }

        Task {
            await searchInRepoNames(queryString: searchText)
        }
    }
}

// MARK: - refresh
extension HomeViewModel {
    func refresh() async {
        guard !searchText.isEmpty else { return }

        // Reset pagination
        currentPage = HomeConstants.searchPageDefaultPage

        // Perform search
        await searchInRepoNames(queryString: searchText)
    }
}

// MARK: - message state from view model
extension HomeViewModel {
    enum MessageState {
        case loading
        case loaded
        case error(String)
        case emptySearchResult
    }
}

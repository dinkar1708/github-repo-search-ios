//
//  HomeViewModel.swift
//  github_repo_search_iOS_app
//
//  Created by Dinakar Maurya on 2021/08/12.
//

import SwiftUI
import Foundation

/**
 Home view model for data collections and operation using modern Swift concurrency
 Responsible for data change
 */
@Observable
@MainActor
class HomeViewModel {
    private let gitHubRepository = DefaultGithubRepository()
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

    init(state: MessageState = .loaded) {
        // initialize state - start with loaded (empty) instead of loading
        messageState = state
    }

    private func handleSearchTextChange() {
        // Cancel previous search task
        searchTask?.cancel()

        // Handle empty or too short search text
        if searchText.isEmpty || searchText.count < HomeConstants.minimumSearchCharacters {
            searchItems.removeAll()
            messageState = searchText.isEmpty ? .emptySearchResult : .loaded
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

        print("searchInRepoNames() for search query \(searchText) for page \(currentPage)")

        do {
            // get data from api
            let searchResponse = try await gitHubRepository.getSearchResultInRepoName(
                queryString: queryString,
                perPage: HomeConstants.searchPageSize,
                pageNumber: currentPage
            )

            // Check if task was cancelled or search text changed
            guard !Task.isCancelled else { return }

            print("searchInRepoNames() Total search results count \(searchResponse.totalCount)")
            print("searchInRepoNames() current page results count \(searchResponse.items.count)")

            // special case when user searched some keyword and api is taking long time get data,
            // but user clear the search text from search field, ignore the api result and show empty search result
            if searchText.isEmpty {
                print("searchInRepoNames() search query is empty ignore result.....")
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
            print("searchInRepoNames()  total count so far \(searchItems.count)")
            currentPage += 1
            isSearchingCurrentPage = false
            // change the state
            messageState = .loaded

        } catch let error as ApiResponseError {
            guard !Task.isCancelled else { return }
            print(error.message)
            print("searchInRepoNames() error \(error.message)")
            messageState = .error(error.message)
            isSearchingCurrentPage = false
        } catch {
            guard !Task.isCancelled else { return }
            print("searchInRepoNames() error \(error.localizedDescription)")
            messageState = .error(error.localizedDescription)
            isSearchingCurrentPage = false
        }
    }
}

// MARK: - pagination
extension HomeViewModel {
    func searchForNextPage(currentItem: SearchItem) {
        // search for the next page data if can search
        let thresholdIndex = searchItems.index(searchItems.endIndex, offsetBy: HomeConstants.searchNextPageThreshold)
        if searchItems.firstIndex(where: { $0.id == currentItem.id }) == thresholdIndex {
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

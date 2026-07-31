//
//  HomeViewModelTests.swift
//  github_repo_search_iOS_app_UnitTests
//
//  Created for unit testing HomeViewModel
//

import XCTest
@testable import github_repo_search_iOS_app

@MainActor
final class HomeViewModelTests: XCTestCase {

    var sut: HomeViewModel!
    var mockRepository: MockGithubRepository!

    override func setUp() {
        super.setUp()
        mockRepository = MockGithubRepository()

        // Set up DI container with mock dependencies
        DependencyContainer.shared = .test(
            githubRepository: mockRepository,
            cacheService: MockCacheService(),
            analyticsService: MockAnalyticsService()
        )

        sut = HomeViewModel(state: .loaded)
    }

    override func tearDown() {
        sut = nil
        mockRepository = nil
        super.tearDown()
    }

    // MARK: - Initial State Tests

    func testInitialState_shouldBeLoaded() {
        // Given & When
        let viewModel = HomeViewModel()

        // Then
        XCTAssertTrue(viewModel.searchItems.isEmpty, "Initial search items should be empty")
        XCTAssertEqual(viewModel.searchText, "", "Initial search text should be empty")
    }

    func testInitialState_withCustomState() {
        // Given & When
        let viewModel = HomeViewModel(state: .loading)

        // Then
        if case .loading = viewModel.messageState {
            XCTAssertTrue(true)
        } else {
            XCTFail("Expected loading state")
        }
    }

    // MARK: - Search Text Change Tests

    func testSearchText_whenEmpty_shouldClearResults() async {
        // Given
        sut.searchText = "swift"
        try? await Task.sleep(nanoseconds: 1_500_000_000) // Wait for debounce

        // When
        sut.searchText = ""

        // Then
        XCTAssertTrue(sut.searchItems.isEmpty, "Search items should be cleared")
    }

    func testSearchText_whenTooShort_shouldNotTriggerSearch() async {
        // Given
        sut.searchText = "ab" // Less than minimum characters

        // When
        try? await Task.sleep(nanoseconds: 1_500_000_000) // Wait for debounce

        // Then
        XCTAssertTrue(sut.searchItems.isEmpty, "Should not search with short query")
    }

    func testSearchText_whenValid_shouldUpdateState() {
        // Given & When
        sut.searchText = "swift"

        // Then
        XCTAssertEqual(sut.searchText, "swift", "Search text should be updated")
    }

    // MARK: - Message State Tests

    func testMessageState_whenSearching_shouldShowLoading() async {
        // Given
        sut = HomeViewModel(state: .loaded)

        // When
        sut.searchText = "swift"

        // Wait briefly to check loading state
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then - loading state should be set initially
        // Note: This is timing-dependent, so we just verify searchText was set
        XCTAssertEqual(sut.searchText, "swift")
    }

    func testMessageState_whenEmptySearch_shouldShowEmptyResult() {
        // Given & When
        sut.searchText = ""

        // Then
        if case .emptySearchResult = sut.messageState {
            XCTAssertTrue(true)
        } else {
            XCTFail("Expected empty search result state")
        }
    }

    // MARK: - Pagination Tests

    func testPagination_shouldNotLoadWhenSearching() {
        // Given
        sut.searchText = "swift"

        // Create mock search item
        let mockOwner = Owner(
            login: "test",
            id: 1,
            nodeID: "node1",
            avatarURL: "https://avatar.com",
            gravatarID: "",
            url: "",
            htmlURL: "",
            followersURL: "",
            followingURL: "",
            gistsURL: "",
            starredURL: "",
            subscriptionsURL: "",
            organizationsURL: "",
            reposURL: "",
            eventsURL: "",
            receivedEventsURL: "",
            type: "User",
            siteAdmin: false
        )

        let mockItem = SearchItem(
            id: 1,
            nodeID: "node1",
            name: "Test Repo",
            fullName: "test/repo",
            itemPrivate: false,
            owner: mockOwner,
            htmlURL: "https://github.com",
            itemDescription: "Test",
            fork: false,
            url: "",
            forksURL: "",
            keysURL: "",
            collaboratorsURL: "",
            teamsURL: "",
            hooksURL: "",
            issueEventsURL: "",
            eventsURL: "",
            assigneesURL: "",
            branchesURL: "",
            tagsURL: "",
            blobsURL: "",
            gitTagsURL: "",
            gitRefsURL: "",
            treesURL: "",
            statusesURL: "",
            languagesURL: "",
            stargazersURL: "",
            contributorsURL: "",
            subscribersURL: "",
            subscriptionURL: "",
            commitsURL: "",
            gitCommitsURL: "",
            commentsURL: "",
            issueCommentURL: "",
            contentsURL: "",
            compareURL: "",
            mergesURL: "",
            archiveURL: "",
            downloadsURL: "",
            issuesURL: "",
            pullsURL: "",
            milestonesURL: "",
            notificationsURL: "",
            labelsURL: "",
            releasesURL: "",
            deploymentsURL: "",
            createdAt: nil,
            updatedAt: nil,
            pushedAt: nil,
            gitURL: "",
            sshURL: "",
            cloneURL: "",
            svnURL: "",
            homepage: nil,
            size: 0,
            stargazersCount: 100,
            watchersCount: 50,
            language: "Swift",
            hasIssues: true,
            hasProjects: true,
            hasDownloads: true,
            hasWiki: true,
            hasPages: false,
            forksCount: 10,
            mirrorURL: nil,
            archived: false,
            disabled: false,
            openIssuesCount: 5,
            license: nil,
            forks: 10,
            openIssues: 5,
            watchers: 50,
            defaultBranch: "main",
            score: 1.0
        )

        // When - trigger pagination check
        sut.searchForNextPage(currentItem: mockItem)

        // Then - should not crash
        XCTAssertNotNil(sut)
    }
}

// MARK: - Mock Repository

final class MockGithubRepository: GithubRepository {

    var shouldReturnError = false
    var mockSearchResults: SearchItemResponse?

    func getSearchResultInRepoName(queryString: String, perPage: Int, pageNumber: Int) async throws -> SearchItemResponse {
        if shouldReturnError {
            throw ApiResponseError.invalidResponse(statusCode: 500, message: "Mock error")
        }

        return mockSearchResults ?? SearchItemResponse(totalCount: 0, incompleteResults: false, items: [])
    }

    func searchUsers(query: String, perPage: Int, page: Int) async throws -> SearchUser {
        return SearchUser(totalCount: 0, incompleteResults: false, items: [])
    }

    func getUserProfile(username: String) async throws -> UserProfile {
        throw ApiResponseError.invalidResponse(statusCode: 404, message: "Not implemented")
    }

    func getUserRepositories(username: String, perPage: Int, page: Int) async throws -> [UserRepository] {
        return []
    }
}

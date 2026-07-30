//
//  UserProfileViewModelTests.swift
//  github_repo_search_iOS_app_UnitTests
//
//  Created for unit testing UserProfileViewModel
//

import XCTest
@testable import github_repo_search_iOS_app

@MainActor
final class UserProfileViewModelTests: XCTestCase {

    var sut: UserProfileViewModel!
    var mockRepository: MockUserProfileRepository!

    override func setUp() {
        super.setUp()
        mockRepository = MockUserProfileRepository()
        sut = UserProfileViewModel(repository: mockRepository)
    }

    override func tearDown() {
        sut = nil
        mockRepository = nil
        super.tearDown()
    }

    // MARK: - Initial State Tests

    func testInitialState_shouldBeEmpty() {
        // Then
        XCTAssertNil(sut.userProfile, "Initial user profile should be nil")
        XCTAssertTrue(sut.userRepositories.isEmpty, "Initial repositories should be empty")
        XCTAssertFalse(sut.isLoading, "Should not be loading initially")
        XCTAssertNil(sut.errorMessage, "Should have no error initially")
        XCTAssertFalse(sut.showForksOnly, "Should not filter forks initially")
    }

    // MARK: - Load User Profile Tests

    func testLoadUserProfile_withSuccess_shouldUpdateProfile() async {
        // Given
        let mockProfile = UserProfile(
            login: "testuser",
            id: 123,
            nodeId: "node123",
            avatarUrl: "https://avatar.com/test",
            gravatarId: "",
            url: "https://api.github.com/users/testuser",
            htmlUrl: "https://github.com/testuser",
            followersUrl: "",
            followingUrl: "",
            gistsUrl: "",
            starredUrl: "",
            subscriptionsUrl: "",
            organizationsUrl: "",
            reposUrl: "",
            eventsUrl: "",
            receivedEventsUrl: "",
            type: "User",
            siteAdmin: false,
            name: "Test User",
            company: nil,
            blog: "",
            location: nil,
            email: nil,
            hireable: nil,
            bio: "Test bio",
            twitterUsername: nil,
            publicRepos: 10,
            publicGists: 5,
            followers: 100,
            following: 50,
            createdAt: "2020-01-01T00:00:00Z",
            updatedAt: "2023-01-01T00:00:00Z"
        )

        mockRepository.mockUserProfile = mockProfile
        mockRepository.mockUserRepositories = []

        // When
        await sut.loadUserProfile(username: "testuser")

        // Then
        XCTAssertNotNil(sut.userProfile, "User profile should be loaded")
        XCTAssertEqual(sut.userProfile?.login, "testuser", "Username should match")
        XCTAssertEqual(sut.userProfile?.name, "Test User", "Name should match")
        XCTAssertFalse(sut.isLoading, "Should not be loading after completion")
        XCTAssertNil(sut.errorMessage, "Should have no error on success")
    }

    func testLoadUserProfile_withError_shouldSetErrorMessage() async {
        // Given
        mockRepository.shouldReturnError = true

        // When
        await sut.loadUserProfile(username: "testuser")

        // Then
        XCTAssertNil(sut.userProfile, "User profile should be nil on error")
        XCTAssertNotNil(sut.errorMessage, "Error message should be set")
        XCTAssertFalse(sut.isLoading, "Should not be loading after error")
    }

    func testLoadUserProfile_shouldLoadRepositories() async {
        // Given
        let mockProfile = UserProfile(
            login: "testuser",
            id: 123,
            nodeId: "node123",
            avatarUrl: "https://avatar.com/test",
            gravatarId: "",
            url: "https://api.github.com/users/testuser",
            htmlUrl: "https://github.com/testuser",
            followersUrl: "",
            followingUrl: "",
            gistsUrl: "",
            starredUrl: "",
            subscriptionsUrl: "",
            organizationsUrl: "",
            reposUrl: "",
            eventsUrl: "",
            receivedEventsUrl: "",
            type: "User",
            siteAdmin: false,
            name: "Test User",
            company: nil,
            blog: "",
            location: nil,
            email: nil,
            hireable: nil,
            bio: "Test bio",
            twitterUsername: nil,
            publicRepos: 2,
            publicGists: 0,
            followers: 10,
            following: 5,
            createdAt: "2020-01-01T00:00:00Z",
            updatedAt: "2023-01-01T00:00:00Z"
        )

        let mockRepo1 = UserRepository(
            id: 1,
            nodeId: "node1",
            name: "repo1",
            fullName: "testuser/repo1",
            private: false,
            description: "Test repo 1",
            fork: false,
            htmlUrl: "https://github.com/testuser/repo1",
            url: "https://api.github.com/repos/testuser/repo1",
            language: "Swift",
            stargazersCount: 10,
            watchersCount: 5,
            forksCount: 2,
            openIssuesCount: 1,
            createdAt: "2020-01-01T00:00:00Z",
            updatedAt: "2023-01-01T00:00:00Z",
            pushedAt: "2023-01-01T00:00:00Z"
        )

        mockRepository.mockUserProfile = mockProfile
        mockRepository.mockUserRepositories = [mockRepo1]

        // When
        await sut.loadUserProfile(username: "testuser")

        // Then
        XCTAssertEqual(sut.userRepositories.count, 1, "Should load repositories")
        XCTAssertEqual(sut.userRepositories.first?.name, "repo1", "Repository name should match")
    }

    // MARK: - Fork Filter Tests

    func testFilteredRepositories_withoutForksFilter_shouldReturnAll() async {
        // Given
        let mockProfile = createMockProfile()
        let repo1 = createMockRepository(id: 1, name: "repo1", fork: false)
        let repo2 = createMockRepository(id: 2, name: "repo2", fork: true)

        mockRepository.mockUserProfile = mockProfile
        mockRepository.mockUserRepositories = [repo1, repo2]

        await sut.loadUserProfile(username: "testuser")

        // When
        let filtered = sut.filteredRepositories

        // Then
        XCTAssertEqual(filtered.count, 2, "Should return all repositories when filter is off")
    }

    func testFilteredRepositories_withForksFilter_shouldReturnOnlyForks() async {
        // Given
        let mockProfile = createMockProfile()
        let repo1 = createMockRepository(id: 1, name: "repo1", fork: false)
        let repo2 = createMockRepository(id: 2, name: "repo2", fork: true)

        mockRepository.mockUserProfile = mockProfile
        mockRepository.mockUserRepositories = [repo1, repo2]

        await sut.loadUserProfile(username: "testuser")

        // When
        sut.showForksOnly = true
        let filtered = sut.filteredRepositories

        // Then
        XCTAssertEqual(filtered.count, 1, "Should return only forked repositories")
        XCTAssertTrue(filtered.first?.fork ?? false, "Returned repository should be a fork")
    }

    func testToggleForksFilter_shouldChangeState() {
        // Given
        let initialState = sut.showForksOnly

        // When
        sut.toggleForksFilter()

        // Then
        XCTAssertNotEqual(sut.showForksOnly, initialState, "Filter state should toggle")
    }

    // MARK: - Refresh Tests

    func testRefresh_shouldReloadProfile() async {
        // Given
        let mockProfile = createMockProfile()
        mockRepository.mockUserProfile = mockProfile
        mockRepository.mockUserRepositories = []

        await sut.loadUserProfile(username: "testuser")
        XCTAssertNotNil(sut.userProfile)

        // When
        await sut.refresh(username: "testuser")

        // Then
        XCTAssertNotNil(sut.userProfile, "Profile should still be loaded after refresh")
    }

    // MARK: - Helper Methods

    private func createMockProfile() -> UserProfile {
        return UserProfile(
            login: "testuser",
            id: 123,
            nodeId: "node123",
            avatarUrl: "https://avatar.com/test",
            gravatarId: "",
            url: "https://api.github.com/users/testuser",
            htmlUrl: "https://github.com/testuser",
            followersUrl: "",
            followingUrl: "",
            gistsUrl: "",
            starredUrl: "",
            subscriptionsUrl: "",
            organizationsUrl: "",
            reposUrl: "",
            eventsUrl: "",
            receivedEventsUrl: "",
            type: "User",
            siteAdmin: false,
            name: "Test User",
            company: nil,
            blog: "",
            location: nil,
            email: nil,
            hireable: nil,
            bio: "Test bio",
            twitterUsername: nil,
            publicRepos: 10,
            publicGists: 5,
            followers: 100,
            following: 50,
            createdAt: "2020-01-01T00:00:00Z",
            updatedAt: "2023-01-01T00:00:00Z"
        )
    }

    private func createMockRepository(id: Int, name: String, fork: Bool) -> UserRepository {
        return UserRepository(
            id: id,
            nodeId: "node\(id)",
            name: name,
            fullName: "testuser/\(name)",
            private: false,
            description: "Test repo",
            fork: fork,
            htmlUrl: "https://github.com/testuser/\(name)",
            url: "https://api.github.com/repos/testuser/\(name)",
            language: "Swift",
            stargazersCount: 10,
            watchersCount: 5,
            forksCount: 2,
            openIssuesCount: 1,
            createdAt: "2020-01-01T00:00:00Z",
            updatedAt: "2023-01-01T00:00:00Z",
            pushedAt: "2023-01-01T00:00:00Z"
        )
    }
}

// MARK: - Mock Repository

final class MockUserProfileRepository: GithubRepository {

    var shouldReturnError = false
    var mockUserProfile: UserProfile?
    var mockUserRepositories: [UserRepository] = []

    func getSearchResultInRepoName(queryString: String, perPage: Int, pageNumber: Int) async throws -> SearchItemResponse {
        return SearchItemResponse(totalCount: 0, incompleteResults: false, items: [])
    }

    func searchUsers(query: String, perPage: Int, page: Int) async throws -> SearchUser {
        return SearchUser(totalCount: 0, incompleteResults: false, items: [])
    }

    func getUserProfile(username: String) async throws -> UserProfile {
        if shouldReturnError {
            throw ApiResponseError.invalidResponse(statusCode: 404, message: "User not found")
        }

        guard let profile = mockUserProfile else {
            throw ApiResponseError.invalidResponse(statusCode: 404, message: "Mock profile not set")
        }

        return profile
    }

    func getUserRepositories(username: String, perPage: Int, page: Int) async throws -> [UserRepository] {
        if shouldReturnError {
            throw ApiResponseError.invalidResponse(statusCode: 500, message: "Error fetching repositories")
        }

        return mockUserRepositories
    }
}

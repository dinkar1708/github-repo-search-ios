//
//  UserProfileViewModelTests.swift
//  github_repo_search_iOS_app_UnitTests
//
//  Classic XCTest implementation for UserProfileViewModel
//

import XCTest
@testable import github_repo_search_iOS_app

@MainActor
final class UserProfileViewModelTests: XCTestCase {

    var sut: UserProfileViewModel!
    var mockRepository: MockGithubRepository!

    override func setUp() {
        super.setUp()
        mockRepository = MockGithubRepository()
        DependencyContainer.shared = .test(
            githubRepository: mockRepository,
            cacheService: MockCacheService(),
            analyticsService: MockAnalyticsService()
        )
        sut = UserProfileViewModel()
    }

    override func tearDown() {
        sut = nil
        mockRepository = nil
        super.tearDown()
    }

    // MARK: - Initial State Tests

    func testInitialState_shouldBeEmpty() {
        XCTAssertNil(sut.userProfile, "Initial user profile should be nil")
        XCTAssertTrue(sut.userRepositories.isEmpty, "Initial repositories should be empty")
        XCTAssertFalse(sut.isLoading, "Should not be loading initially")
        XCTAssertNil(sut.errorMessage, "Should have no error initially")
        XCTAssertFalse(sut.showForksOnly, "Should not filter forks initially")
    }

    // MARK: - Fork Filter Tests

    func testFilteredRepositories_withoutForksFilter_shouldReturnAll() {
        // Given
        let repo1 = createMockUserRepository(id: 1, name: "repo1", fork: false)
        let repo2 = createMockUserRepository(id: 2, name: "repo2", fork: true)
        sut.userRepositories = [repo1, repo2]
        sut.showForksOnly = false

        // When
        let filtered = sut.filteredRepositories

        // Then
        XCTAssertEqual(filtered.count, 2, "Should return all repositories when filter is off")
    }

    func testFilteredRepositories_withForksFilter_shouldReturnOnlyForks() {
        // Given
        let repo1 = createMockUserRepository(id: 1, name: "repo1", fork: false)
        let repo2 = createMockUserRepository(id: 2, name: "repo2", fork: true)
        sut.userRepositories = [repo1, repo2]

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

    // MARK: - Helper Methods

    private func createMockUserProfile(id: Int = 123, login: String = "testuser") -> UserProfile {
        return UserProfile(
            id: id,
            login: login,
            avatarUrl: "https://avatar.com/test",
            htmlUrl: "https://github.com/\(login)",
            type: "User",
            name: "Test User",
            company: "Apple",
            blog: "https://apple.com",
            location: "Cupertino",
            email: "test@apple.com",
            bio: "iOS Developer",
            publicRepos: 10,
            publicGists: 2,
            followers: 100,
            following: 50,
            createdAt: "2020-01-01T00:00:00Z",
            updatedAt: "2023-01-01T00:00:00Z"
        )
    }

    private func createMockUserRepository(id: Int, name: String, fork: Bool) -> UserRepository {
        let mockOwner = Owner(
            login: "testuser",
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

        return UserRepository(
            id: id,
            name: name,
            fullName: "testuser/\(name)",
            owner: mockOwner,
            htmlUrl: "https://github.com/testuser/\(name)",
            description: "Test repo",
            fork: fork,
            createdAt: "2020-01-01T00:00:00Z",
            updatedAt: "2023-01-01T00:00:00Z",
            pushedAt: "2023-01-01T00:00:00Z",
            stargazersCount: 10,
            watchersCount: 5,
            forksCount: 2,
            language: "Swift",
            defaultBranch: "main"
        )
    }
}

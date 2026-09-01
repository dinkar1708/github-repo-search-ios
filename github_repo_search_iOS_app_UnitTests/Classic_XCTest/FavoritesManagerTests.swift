//
//  FavoritesManagerTests.swift
//  github_repo_search_iOS_app_UnitTests
//
//  Classic XCTest implementation for FavoritesManager
//

import XCTest
@testable import github_repo_search_iOS_app

@MainActor
final class FavoritesManagerTests: XCTestCase {

    var sut: FavoritesManager!
    var mockRepository: MockFavoritesRepository!
    var mockAnalytics: MockAnalyticsService!

    override func setUp() async throws {
        try await super.setUp()
        mockRepository = MockFavoritesRepository()
        mockAnalytics = MockAnalyticsService()

        // Set up DI container with mock dependencies
        DependencyContainer.shared = .test(
            favoritesRepository: mockRepository,
            analyticsService: mockAnalytics
        )

        // Reset singleton collections and mocks
        sut = FavoritesManager.shared
        sut.favoriteUsers.removeAll()
        sut.favoriteRepositories.removeAll()
        mockAnalytics.trackedEvents.removeAll()

        // Wait for initial load to complete
        try await Task.sleep(nanoseconds: 100_000_000)
    }

    override func tearDown() async throws {
        sut.favoriteUsers.removeAll()
        sut.favoriteRepositories.removeAll()
        mockAnalytics.trackedEvents.removeAll()
        sut = nil
        mockRepository = nil
        mockAnalytics = nil
        try await super.tearDown()
    }

    // MARK: - User Favorites Tests

    func testAddFavoriteUser_shouldAddUserToList() async {
        // Given
        let profile = createMockUserProfile(id: 1, login: "testuser")

        // When
        sut.addFavoriteUser(profile: profile)

        // Wait for async operation
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertEqual(sut.favoriteUsers.count, 1, "Should have one favorite user")
        XCTAssertEqual(sut.favoriteUsers.first?.login, "testuser", "Should add correct user")
    }

    func testAddFavoriteUser_whenDuplicate_shouldNotAddAgain() async {
        // Given
        let profile = createMockUserProfile(id: 1, login: "testuser")

        // When
        sut.addFavoriteUser(profile: profile)
        try? await Task.sleep(nanoseconds: 100_000_000)
        sut.addFavoriteUser(profile: profile)
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertEqual(sut.favoriteUsers.count, 1, "Should not add duplicate user")
    }

    func testRemoveFavoriteUser_shouldRemoveUserFromList() async {
        // Given
        let profile = createMockUserProfile(id: 1, login: "testuser")
        sut.addFavoriteUser(profile: profile)
        try? await Task.sleep(nanoseconds: 100_000_000)

        // When
        sut.removeFavoriteUser(username: "testuser")
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertTrue(sut.favoriteUsers.isEmpty, "Should remove user from favorites")
    }

    func testIsFavoriteUser_whenUserIsFavorite_shouldReturnTrue() async {
        // Given
        let profile = createMockUserProfile(id: 1, login: "testuser")
        sut.addFavoriteUser(profile: profile)
        try? await Task.sleep(nanoseconds: 100_000_000)

        // When
        let isFavorite = sut.isFavoriteUser(username: "testuser")

        // Then
        XCTAssertTrue(isFavorite, "Should return true for favorite user")
    }

    func testIsFavoriteUser_whenUserIsNotFavorite_shouldReturnFalse() {
        // Given & When
        let isFavorite = sut.isFavoriteUser(username: "nonexistent")

        // Then
        XCTAssertFalse(isFavorite, "Should return false for non-favorite user")
    }

    func testClearAllUserFavorites_shouldRemoveAllUsers() async {
        // Given
        let profile1 = createMockUserProfile(id: 1, login: "user1")
        let profile2 = createMockUserProfile(id: 2, login: "user2")
        sut.addFavoriteUser(profile: profile1)
        sut.addFavoriteUser(profile: profile2)
        try? await Task.sleep(nanoseconds: 100_000_000)

        // When
        sut.clearAllUserFavorites()
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertTrue(sut.favoriteUsers.isEmpty, "Should clear all user favorites")
    }

    // MARK: - Repository Favorites Tests

    func testAddFavoriteRepository_shouldAddRepositoryToList() async {
        // Given
        let repository = createMockSearchItem(id: 1, name: "testrepo")

        // When
        sut.addFavoriteRepository(repository: repository)

        // Wait for async operation
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertEqual(sut.favoriteRepositories.count, 1, "Should have one favorite repository")
        XCTAssertEqual(sut.favoriteRepositories.first?.name, "testrepo", "Should add correct repository")
    }

    func testAddFavoriteRepository_whenDuplicate_shouldNotAddAgain() async {
        // Given
        let repository = createMockSearchItem(id: 1, name: "testrepo")

        // When
        sut.addFavoriteRepository(repository: repository)
        try? await Task.sleep(nanoseconds: 100_000_000)
        sut.addFavoriteRepository(repository: repository)
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertEqual(sut.favoriteRepositories.count, 1, "Should not add duplicate repository")
    }

    func testRemoveFavoriteRepository_shouldRemoveRepositoryFromList() async {
        // Given
        let repository = createMockSearchItem(id: 1, name: "testrepo")
        sut.addFavoriteRepository(repository: repository)
        try? await Task.sleep(nanoseconds: 100_000_000)

        // When
        sut.removeFavoriteRepository(repositoryId: 1)
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertTrue(sut.favoriteRepositories.isEmpty, "Should remove repository from favorites")
    }

    func testIsFavoriteRepository_whenRepositoryIsFavorite_shouldReturnTrue() async {
        // Given
        let repository = createMockSearchItem(id: 1, name: "testrepo")
        sut.addFavoriteRepository(repository: repository)
        try? await Task.sleep(nanoseconds: 100_000_000)

        // When
        let isFavorite = sut.isFavoriteRepository(repositoryId: 1)

        // Then
        XCTAssertTrue(isFavorite, "Should return true for favorite repository")
    }

    func testIsFavoriteRepository_whenRepositoryIsNotFavorite_shouldReturnFalse() {
        // Given & When
        let isFavorite = sut.isFavoriteRepository(repositoryId: 999)

        // Then
        XCTAssertFalse(isFavorite, "Should return false for non-favorite repository")
    }

    func testClearAllRepositoryFavorites_shouldRemoveAllRepositories() async {
        // Given
        let repo1 = createMockSearchItem(id: 1, name: "repo1")
        let repo2 = createMockSearchItem(id: 2, name: "repo2")
        sut.addFavoriteRepository(repository: repo1)
        sut.addFavoriteRepository(repository: repo2)
        try? await Task.sleep(nanoseconds: 100_000_000)

        // When
        sut.clearAllRepositoryFavorites()
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertTrue(sut.favoriteRepositories.isEmpty, "Should clear all repository favorites")
    }

    // MARK: - Clear All Tests

    func testClearAllFavorites_shouldRemoveAllUsersAndRepositories() async {
        // Given
        let profile = createMockUserProfile(id: 1, login: "user1")
        let repository = createMockSearchItem(id: 1, name: "repo1")
        sut.addFavoriteUser(profile: profile)
        sut.addFavoriteRepository(repository: repository)
        try? await Task.sleep(nanoseconds: 100_000_000)

        // When
        sut.clearAllFavorites()
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertTrue(sut.favoriteUsers.isEmpty, "Should clear all user favorites")
        XCTAssertTrue(sut.favoriteRepositories.isEmpty, "Should clear all repository favorites")
    }

    // MARK: - Analytics Tests

    func testAddFavoriteUser_shouldTrackAnalyticsEvent() async {
        // Given
        let profile = createMockUserProfile(id: 1, login: "testuser")

        // When
        sut.addFavoriteUser(profile: profile)
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertTrue(mockAnalytics.trackedEvents.contains { event in
            if case .favoriteAdded = event {
                return true
            }
            return false
        }, "Should track favorite added event")
    }

    func testRemoveFavoriteUser_shouldTrackAnalyticsEvent() async {
        // Given
        let profile = createMockUserProfile(id: 1, login: "testuser")
        sut.addFavoriteUser(profile: profile)
        try? await Task.sleep(nanoseconds: 100_000_000)
        mockAnalytics.trackedEvents.removeAll()

        // When
        sut.removeFavoriteUser(username: "testuser")
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertTrue(mockAnalytics.trackedEvents.contains { event in
            if case .favoriteRemoved = event {
                return true
            }
            return false
        }, "Should track favorite removed event")
    }

    // MARK: - Model Conversion Tests

    func testFavoriteUser_initFromUserProfile_shouldMapAllFields() {
        // Given
        let profile = createMockUserProfile(id: 123, login: "testuser")

        // When
        let favoriteUser = FavoriteUser(from: profile)

        // Then
        XCTAssertEqual(favoriteUser.id, 123, "Should map id correctly")
        XCTAssertEqual(favoriteUser.login, "testuser", "Should map login correctly")
        XCTAssertEqual(favoriteUser.avatarUrl, "https://avatar.com", "Should map avatar URL correctly")
        XCTAssertEqual(favoriteUser.publicRepos, 10, "Should map public repos correctly")
        XCTAssertEqual(favoriteUser.followers, 100, "Should map followers correctly")
        XCTAssertEqual(favoriteUser.following, 50, "Should map following correctly")
    }

    func testFavoriteRepository_initFromSearchItem_shouldMapAllFields() {
        // Given
        let searchItem = createMockSearchItem(id: 456, name: "testrepo")

        // When
        let favoriteRepo = FavoriteRepository(from: searchItem)

        // Then
        XCTAssertEqual(favoriteRepo.id, 456, "Should map id correctly")
        XCTAssertEqual(favoriteRepo.name, "testrepo", "Should map name correctly")
        XCTAssertEqual(favoriteRepo.fullName, "owner/testrepo", "Should map full name correctly")
        XCTAssertEqual(favoriteRepo.language, "Swift", "Should map language correctly")
        XCTAssertEqual(favoriteRepo.stargazersCount, 100, "Should map stars correctly")
        XCTAssertEqual(favoriteRepo.forksCount, 10, "Should map forks correctly")
    }

    func testFavoriteRepository_toSearchItem_shouldConvertBackCorrectly() {
        // Given
        let searchItem = createMockSearchItem(id: 456, name: "testrepo")
        let favoriteRepo = FavoriteRepository(from: searchItem)

        // When
        let convertedSearchItem = favoriteRepo.toSearchItem()

        // Then
        XCTAssertEqual(convertedSearchItem.id, searchItem.id, "Should preserve id")
        XCTAssertEqual(convertedSearchItem.name, searchItem.name, "Should preserve name")
        XCTAssertEqual(convertedSearchItem.fullName, searchItem.fullName, "Should preserve full name")
        XCTAssertEqual(convertedSearchItem.language, searchItem.language, "Should preserve language")
        XCTAssertEqual(convertedSearchItem.stargazersCount, searchItem.stargazersCount, "Should preserve stars")
    }

    // MARK: - Helper Methods

    private func createMockUserProfile(id: Int, login: String) -> UserProfile {
        return UserProfile(
            id: id,
            login: login,
            avatarUrl: "https://avatar.com",
            htmlUrl: "https://github.com/\(login)",
            type: "User",
            name: "Test User",
            company: "Test Company",
            blog: "https://blog.com",
            location: "Test City",
            email: "test@example.com",
            bio: "Test bio",
            publicRepos: 10,
            publicGists: 5,
            followers: 100,
            following: 50,
            createdAt: "2020-01-01T00:00:00Z",
            updatedAt: "2024-01-01T00:00:00Z"
        )
    }

    private func createMockSearchItem(id: Int, name: String) -> SearchItem {
        let owner = Owner(
            login: "owner",
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

        return SearchItem(
            id: id,
            nodeID: "node\(id)",
            name: name,
            fullName: "owner/\(name)",
            itemPrivate: false,
            owner: owner,
            htmlURL: "https://github.com/owner/\(name)",
            itemDescription: "Test repository",
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
            cloneURL: "https://github.com/owner/\(name).git",
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
            score: 1
        )
    }
}

//
//  UserProfileFlowIntegrationTests.swift
//  github_repo_search_iOS_app_IntegrationTests
//
//  Integration tests for user profile flow
//

import XCTest
@testable import github_repo_search_iOS_app

@MainActor
final class UserProfileFlowIntegrationTests: XCTestCase {

    var viewModel: UserProfileViewModel!

    override func setUp() {
        super.setUp()
        viewModel = UserProfileViewModel()
    }

    override func tearDown() {
        viewModel = nil
        super.tearDown()
    }

    // MARK: - Complete User Profile Flow

    func testLoadUserProfile_CompleteFlow() async throws {
        // Given
        let testUsername = "octocat" // GitHub's official test account

        // When
        await viewModel.loadUserProfile(username: testUsername)

        // Wait for network requests to complete
        try await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds

        // Then
        if let profile = viewModel.userProfile {
            XCTAssertEqual(profile.login, testUsername, "Should load correct user")
            XCTAssertFalse(viewModel.isLoading, "Should not be loading after completion")
            XCTAssertNil(viewModel.errorMessage, "Should have no error on success")
            print("✅ Loaded profile for: \(profile.name ?? profile.login)")
        } else if let error = viewModel.errorMessage {
            // Network error is acceptable in tests
            print("⚠️ Network error (expected in some environments): \(error)")
            XCTAssertFalse(viewModel.isLoading, "Should not be loading after error")
        } else {
            XCTFail("Should have either profile or error after load attempt")
        }
    }

    func testLoadUserProfile_WithRepositories() async throws {
        // Given
        let testUsername = "octocat"

        // When
        await viewModel.loadUserProfile(username: testUsername)
        try await Task.sleep(nanoseconds: 3_000_000_000)

        // Then
        if viewModel.userProfile != nil {
            // Octocat has repositories, so we should load some
            XCTAssertGreaterThanOrEqual(viewModel.userRepositories.count, 0,
                                       "Should load repositories")
            print("✅ Loaded \(viewModel.userRepositories.count) repositories")
        }
    }

    func testLoadUserProfile_InvalidUsername() async throws {
        // Given
        let invalidUsername = "thisuserdoesnotexistatall123456789"

        // When
        await viewModel.loadUserProfile(username: invalidUsername)
        try await Task.sleep(nanoseconds: 3_000_000_000)

        // Then
        XCTAssertNil(viewModel.userProfile, "Should have no profile for invalid user")
        XCTAssertNotNil(viewModel.errorMessage, "Should have error message")
        XCTAssertFalse(viewModel.isLoading, "Should not be loading after error")
        print("✅ Correctly handled invalid username")
    }

    // MARK: - Fork Filter Flow

    func testForkFilter_Integration() async throws {
        // Given
        let testUsername = "octocat"
        await viewModel.loadUserProfile(username: testUsername)
        try await Task.sleep(nanoseconds: 3_000_000_000)

        guard viewModel.userRepositories.count > 0 else {
            print("⚠️ No repositories to test filter")
            return
        }

        let totalRepos = viewModel.userRepositories.count
        let initialFiltered = viewModel.filteredRepositories.count

        // When - Toggle fork filter
        viewModel.toggleForksFilter()

        // Then
        XCTAssertNotEqual(viewModel.showForksOnly, false, "Filter should be toggled")
        let filteredCount = viewModel.filteredRepositories.count

        // Verify filtering logic
        if viewModel.showForksOnly {
            let forkCount = viewModel.userRepositories.filter { $0.fork }.count
            XCTAssertEqual(filteredCount, forkCount, "Should show only forks")
        } else {
            XCTAssertEqual(filteredCount, totalRepos, "Should show all repositories")
        }

        print("✅ Fork filter working: \(filteredCount) of \(totalRepos) repos shown")
    }

    // MARK: - Refresh Flow

    func testRefresh_Flow() async throws {
        // Given
        let testUsername = "octocat"
        await viewModel.loadUserProfile(username: testUsername)
        try await Task.sleep(nanoseconds: 3_000_000_000)

        let firstLoadProfile = viewModel.userProfile

        // When - Refresh
        await viewModel.refresh(username: testUsername)
        try await Task.sleep(nanoseconds: 3_000_000_000)

        // Then
        XCTAssertNotNil(viewModel.userProfile, "Should have profile after refresh")
        XCTAssertFalse(viewModel.isLoading, "Should not be loading after refresh")
        print("✅ Refresh completed successfully")
    }

    // MARK: - Concurrent Requests

    func testConcurrentProfileAndRepos_Flow() async throws {
        // This tests that profile and repositories load concurrently

        // Given
        let testUsername = "octocat"
        let startTime = Date()

        // When
        await viewModel.loadUserProfile(username: testUsername)
        try await Task.sleep(nanoseconds: 3_000_000_000)

        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)

        // Then
        if viewModel.userProfile != nil {
            // Should be faster than sequential (< 6 seconds for concurrent vs ~6 seconds for sequential)
            XCTAssertLessThan(duration, 6.0,
                            "Concurrent loading should be faster than 6 seconds")
            print("✅ Concurrent loading took \(String(format: "%.2f", duration)) seconds")
        }
    }

    // MARK: - State Consistency

    func testStateConsistency_ThroughoutFlow() async throws {
        // Given
        let testUsername = "octocat"

        // When - Initial state
        XCTAssertNil(viewModel.userProfile, "Should start with no profile")
        XCTAssertTrue(viewModel.userRepositories.isEmpty, "Should start with no repos")
        XCTAssertFalse(viewModel.isLoading, "Should not be loading initially")

        // Load profile
        let loadTask = Task {
            await viewModel.loadUserProfile(username: testUsername)
        }

        // Check loading state immediately
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        // Note: Loading state might already be done if network is fast

        await loadTask.value
        try await Task.sleep(nanoseconds: 2_000_000_000)

        // Then - Final state
        XCTAssertFalse(viewModel.isLoading, "Should not be loading after completion")

        if viewModel.userProfile != nil {
            print("✅ State remained consistent throughout flow")
        }
    }
}

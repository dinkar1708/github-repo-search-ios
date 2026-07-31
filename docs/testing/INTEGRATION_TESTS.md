# Integration Tests

## Overview
Integration tests verify that multiple components work together correctly.

## Current Status

- Total: 0 integration tests
- Status: Not yet implemented
- Recommended: 5-10 integration tests

## What Are Integration Tests?

Integration tests sit between unit tests and UI tests:

- **Unit Tests:** Test single component in isolation
- **Integration Tests:** Test multiple components together
- **UI Tests:** Test complete user flows through UI

## Example Integration Test

```swift
func testSearchRepositoriesIntegration() async throws {
    // Tests: ApiClient + GithubRepository + HomeViewModel
    let viewModel = HomeViewModel()

    viewModel.searchText = "swift"
    await viewModel.performSearch()

    XCTAssertTrue(viewModel.repositories.count > 0)
    XCTAssertNil(viewModel.errorMessage)
    XCTAssertFalse(viewModel.isLoading)
}
```

This tests:
- ViewModel logic
- Repository data fetching
- API client networking
- All working together

## Recommended Integration Tests

### 1. Search Flow Integration

**Components:** HomeViewModel + GithubRepository + ApiClient

```swift
@MainActor
func testHomeViewModelSearchIntegration() async throws {
    // Arrange
    let viewModel = HomeViewModel()

    // Act
    viewModel.searchText = "swift"
    await viewModel.performSearch()

    // Assert
    XCTAssertFalse(viewModel.isLoading, "Loading should finish")
    XCTAssertNil(viewModel.errorMessage, "Should not have error")
    XCTAssertTrue(viewModel.repositories.count > 0, "Should have results")

    // Verify data structure
    let firstRepo = viewModel.repositories.first
    XCTAssertNotNil(firstRepo?.name)
    XCTAssertNotNil(firstRepo?.owner)
}
```

### 2. User Search Integration

**Components:** UserSearchViewModel + GithubRepository + ApiClient

```swift
@MainActor
func testUserSearchIntegration() async throws {
    let viewModel = UserSearchViewModel()

    viewModel.searchText = "torvalds"
    await viewModel.searchUsers()

    XCTAssertFalse(viewModel.isLoading)
    XCTAssertNil(viewModel.errorMessage)
    XCTAssertTrue(viewModel.users.count > 0)

    let firstUser = viewModel.users.first
    XCTAssertNotNil(firstUser?.login)
    XCTAssertNotNil(firstUser?.avatarUrl)
}
```

### 3. User Profile Loading Integration

**Components:** UserProfileViewModel + GithubRepository + ApiClient

```swift
@MainActor
func testUserProfileLoadingIntegration() async throws {
    let viewModel = UserProfileViewModel(username: "torvalds")

    await viewModel.loadUserProfile()

    XCTAssertNotNil(viewModel.userProfile)
    XCTAssertNil(viewModel.errorMessage)

    let profile = viewModel.userProfile!
    XCTAssertEqual(profile.login, "torvalds")
    XCTAssertNotNil(profile.name)
    XCTAssertTrue(profile.publicRepos > 0)
}
```

### 4. Favorites Integration

**Components:** FavoritesManager + FavoritesRepository + Keychain

```swift
@MainActor
func testFavoritesAddRemoveIntegration() async throws {
    let manager = FavoritesManager()

    // Initial state
    await manager.loadFavorites()
    let initialCount = manager.favoriteUsers.count

    // Add favorite
    let testUser = FavoriteUser(
        id: 12345,
        login: "testuser",
        avatarUrl: "https://example.com/avatar.png"
    )
    await manager.toggleUserFavorite(testUser)

    // Verify added
    XCTAssertEqual(manager.favoriteUsers.count, initialCount + 1)
    XCTAssertTrue(manager.isUserFavorited(testUser))

    // Remove favorite
    await manager.toggleUserFavorite(testUser)

    // Verify removed
    XCTAssertEqual(manager.favoriteUsers.count, initialCount)
    XCTAssertFalse(manager.isUserFavorited(testUser))
}
```

### 5. Pagination Integration

**Components:** HomeViewModel + GithubRepository + ApiClient

```swift
@MainActor
func testPaginationIntegration() async throws {
    let viewModel = HomeViewModel()

    // Load first page
    viewModel.searchText = "swift"
    await viewModel.performSearch()

    let firstPageCount = viewModel.repositories.count
    XCTAssertTrue(firstPageCount > 0)

    // Load next page
    await viewModel.loadNextPage()

    // Verify pagination
    XCTAssertTrue(viewModel.repositories.count > firstPageCount)
    XCTAssertEqual(viewModel.currentPage, 2)
}
```

### 6. Error Handling Integration

**Components:** ViewModel + Repository + Error propagation

```swift
@MainActor
func testErrorHandlingIntegration() async throws {
    let viewModel = HomeViewModel()

    // Test with invalid/offline scenario
    viewModel.searchText = ""
    await viewModel.performSearch()

    // Should handle error gracefully
    XCTAssertNotNil(viewModel.errorMessage)
    XCTAssertFalse(viewModel.isLoading)
    XCTAssertTrue(viewModel.repositories.isEmpty)
}
```

### 7. Cache Integration

**Components:** CacheService + ViewModel + Repository

```swift
@MainActor
func testCacheIntegration() async throws {
    let viewModel = HomeViewModel()

    // First search - hits API
    viewModel.searchText = "swift"
    await viewModel.performSearch()

    let firstCallCount = viewModel.repositories.count

    // Second search - should use cache
    await viewModel.performSearch()

    // Results should be same (from cache)
    XCTAssertEqual(viewModel.repositories.count, firstCallCount)
}
```

### 8. Analytics Integration

**Components:** ViewModel + AnalyticsService

```swift
@MainActor
func testAnalyticsIntegration() async throws {
    let mockAnalytics = MockAnalyticsService()
    // Inject mock analytics
    let viewModel = HomeViewModel()

    // Perform action
    viewModel.searchText = "swift"
    await viewModel.performSearch()

    // Verify analytics tracked
    XCTAssertTrue(mockAnalytics.trackedEvents.contains { event in
        if case .searchPerformed = event {
            return true
        }
        return false
    })
}
```

## Test Organization

### Folder Structure

```
Tests/
└── IntegrationTests/
    ├── SearchFlowIntegrationTests.swift
    ├── UserFlowIntegrationTests.swift
    ├── FavoritesIntegrationTests.swift
    └── CacheIntegrationTests.swift
```

### Naming Convention

- Suffix with `IntegrationTests`
- Describe the flow being tested
- Use `test` prefix for methods

## Best Practices

### Use Real Components
Integration tests should use real implementations:

```swift
// Good - real components
let viewModel = HomeViewModel()
let repository = GithubRepositoryImpl()

// Avoid - mocked everything (that's a unit test)
let mockViewModel = MockViewModel()
let mockRepository = MockRepository()
```

### Test Boundaries
Define clear integration boundaries:

```swift
// Good - tests specific integration
func testViewModelRepositoryIntegration() {
    // ViewModel + Repository only
}

// Bad - too broad
func testEntireApp() {
    // Everything including UI
}
```

### Verify State Changes
Check that components update correctly:

```swift
// Before action
XCTAssertTrue(viewModel.repositories.isEmpty)
XCTAssertFalse(viewModel.isLoading)

// Perform action
await viewModel.performSearch()

// After action
XCTAssertFalse(viewModel.repositories.isEmpty)
XCTAssertFalse(viewModel.isLoading)
XCTAssertNil(viewModel.errorMessage)
```

### Test Error Paths
Verify error handling across components:

```swift
func testErrorPropagation() async throws {
    // Cause error in repository
    // Verify ViewModel handles it
    // Verify error message propagates
}
```

## Running Integration Tests

### In Xcode
```bash
# All integration tests
Cmd + U

# Specific integration test file
Click diamond icon next to test class
```

### Command Line
```bash
# All integration tests
xcodebuild test -scheme github_repo_search_iOS_app \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.6' \
  -only-testing:IntegrationTests

# Specific test
xcodebuild test -scheme github_repo_search_iOS_app \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.6' \
  -only-testing:IntegrationTests/SearchFlowIntegrationTests
```

## Mock vs Real Dependencies

### When to Mock
- External services (payment, push notifications)
- Time-consuming operations
- Non-deterministic behavior

### When to Use Real
- Internal components (ViewModels, Repositories)
- Data models
- Business logic

### Example Setup
```swift
class SearchIntegrationTests: XCTestCase {
    var viewModel: HomeViewModel!
    var mockAnalytics: MockAnalyticsService!

    override func setUp() {
        // Real ViewModel and Repository
        viewModel = HomeViewModel()

        // Mock external service
        mockAnalytics = MockAnalyticsService()
        DependencyContainer.shared = .test(analyticsService: mockAnalytics)
    }
}
```

## Benefits of Integration Tests

### Catch Real Issues
- Component interaction bugs
- Data flow problems
- State synchronization issues

### Confidence
- Verify components work together
- Catch integration bugs early
- Reduce manual testing

### Documentation
- Show how components interact
- Demonstrate expected behavior
- Serve as usage examples

## Challenges

### Slower Than Unit Tests
Integration tests take longer because they:
- Use real network calls
- Initialize multiple components
- Process real data

Solution: Keep integration tests focused

### Harder to Debug
More components means more potential failure points.

Solution: Use descriptive assertions and logging

### Environment Dependent
Tests may behave differently based on:
- Network availability
- API responses
- Data state

Solution: Use mocks for external dependencies

## Implementation Plan

### Phase 1: Core Flows
1. Search repositories integration
2. Search users integration
3. User profile loading

### Phase 2: Advanced Features
4. Favorites integration
5. Pagination integration
6. Cache integration

### Phase 3: Error Handling
7. Error propagation tests
8. Network failure tests
9. Edge case tests

## Resources

- [XCTest Documentation](https://developer.apple.com/documentation/xctest)
- [Testing Your Apps](https://developer.apple.com/documentation/xcode/testing-your-apps-in-xcode)
- [Integration Testing Best Practices](https://developer.apple.com/documentation/xcode/improving-your-app-s-performance)

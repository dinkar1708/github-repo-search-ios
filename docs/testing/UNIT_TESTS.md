# Unit Tests

## Overview
Unit tests verify individual components in isolation using mocks and stubs.

## Current Status

- Total: 4 unit tests
- Status: All passing
- Coverage: 51.87% overall
  - ApiClient: 88.89%
  - SearchItem: 100%

## Test Location

```
Tests/github_repo_search_iOS_appTests/
├── GitRepository_appTests.swift          # API and repository tests
└── github_repo_search_iOS_appTests.swift # Performance baseline
```

## Test Cases

### 1. testGetSearchResultInRepoNameSomeData

**Purpose:** Verify successful API calls return valid data

**Location:** `GitRepository_appTests.swift`

**What it tests:**
- GithubRepository can search repositories
- ApiClient makes HTTP requests correctly
- JSON response is parsed into SearchItem objects
- Results contain expected data

**Code:**
```swift
@MainActor
func testGetSearchResultInRepoNameSomeData() async throws {
    let repository = GithubRepositoryImpl()
    let response = try await repository.searchRepositories(query: "swift", page: 1)

    XCTAssertTrue(response.items.count > 0, "Should return results for 'swift'")
    XCTAssertTrue(response.totalCount > 0, "Total count should be greater than 0")
}
```

**Assertions:**
- Response items count > 0
- Total count > 0

**Coverage:**
- ApiClient.request() method
- GithubRepository.searchRepositories()
- SearchRepoRequest building
- JSON decoding

### 2. testGetSearchResultInRepoNameEmptyResult

**Purpose:** Verify handling of searches with no results

**Location:** `GitRepository_appTests.swift`

**What it tests:**
- API handles queries that return zero results
- Empty result sets don't crash
- Proper response structure even when empty

**Code:**
```swift
@MainActor
func testGetSearchResultInRepoNameEmptyResult() async throws {
    let repository = GithubRepositoryImpl()
    let response = try await repository.searchRepositories(
        query: "asdfghjklqwertyuiopzxcvbnm12345",
        page: 1
    )

    XCTAssertEqual(response.items.count, 0, "Should return no results")
    XCTAssertEqual(response.totalCount, 0, "Total count should be 0")
}
```

**Assertions:**
- Items array is empty
- Total count is 0

**Coverage:**
- Empty response handling
- Edge case validation

### 3. testGetSearchResultInRepoNameInvalidQuery

**Purpose:** Verify error handling for invalid requests

**Location:** `GitRepository_appTests.swift`

**What it tests:**
- API rejects empty or invalid queries
- Proper error propagation
- Error types are correct

**Code:**
```swift
@MainActor
func testGetSearchResultInRepoNameInvalidQuery() async throws {
    let repository = GithubRepositoryImpl()

    do {
        _ = try await repository.searchRepositories(query: "", page: 1)
        XCTFail("Should throw error for empty query")
    } catch {
        // Expected to throw
        XCTAssertNotNil(error)
    }
}
```

**Assertions:**
- Empty query throws error
- Error is not nil

**Coverage:**
- Input validation
- Error handling paths

### 4. testPerformanceExample

**Purpose:** Placeholder for performance measurement

**Location:** `github_repo_search_iOS_appTests.swift`

**Status:** Stub (empty implementation)

**Code:**
```swift
func testPerformanceExample() throws {
    self.measure {
        // Performance test code here
    }
}
```

## Components Tested

### ApiClient
**Coverage:** 88.89%

**What's tested:**
- HTTP request construction
- Response parsing
- Error handling
- URL building

**What's not tested:**
- Network timeout scenarios
- Certificate validation
- Request cancellation

### GithubRepository
**Coverage:** High

**What's tested:**
- searchRepositories() method
- Query parameter handling
- Response mapping

**What's not tested:**
- getUserProfile()
- getUserRepositories()
- searchUsers()

### SearchItem Model
**Coverage:** 100%

**What's tested:**
- JSON decoding
- Property mapping
- Date parsing

## Testing Patterns

### Async/Await
All tests use modern Swift concurrency:

```swift
@MainActor
func testExample() async throws {
    let result = try await repository.fetch()
    XCTAssertNotNil(result)
}
```

### Arrange-Act-Assert
Tests follow AAA pattern:

```swift
func testSearch() async throws {
    // Arrange
    let repository = GithubRepositoryImpl()
    let query = "swift"

    // Act
    let response = try await repository.searchRepositories(query: query, page: 1)

    // Assert
    XCTAssertTrue(response.items.count > 0)
}
```

### @MainActor
Tests that interact with ViewModels use @MainActor:

```swift
@MainActor
func testViewModel() async throws {
    let viewModel = HomeViewModel()
    // Test code
}
```

## Best Practices

### Test Naming
Use descriptive names that explain what is being tested:

- testGetSearchResultInRepoNameSomeData - Clear intent
- testAPI - Too vague

### Independence
Tests should not depend on each other:

```swift
// Good - each test is independent
func testA() async throws {
    let repo = GithubRepositoryImpl()
    // Test A
}

func testB() async throws {
    let repo = GithubRepositoryImpl()
    // Test B
}
```

### Single Responsibility
Each test should verify one thing:

```swift
// Good - tests one behavior
func testSearchReturnsResults() async throws {
    let response = try await repository.searchRepositories(query: "swift", page: 1)
    XCTAssertTrue(response.items.count > 0)
}

// Bad - tests multiple behaviors
func testEverything() async throws {
    // Test search
    // Test pagination
    // Test error handling
}
```

## What's Missing

### ViewModel Tests
Not yet implemented:

- HomeViewModel search logic
- UserSearchViewModel user search
- UserProfileViewModel profile loading
- FavoritesManager favorites operations

### Repository Tests
Incomplete coverage:

- User profile fetching
- User repositories
- User search
- Pagination edge cases

### Mock Testing
No mocks currently used:

- All tests hit real GitHub API
- No network layer mocking
- No dependency injection mocking

## Recommended Next Tests

### High Priority

1. **HomeViewModel Tests**
```swift
func testHomeViewModelSearch() async throws {
    let viewModel = HomeViewModel()
    viewModel.searchText = "swift"
    await viewModel.performSearch()
    XCTAssertTrue(viewModel.repositories.count > 0)
}
```

2. **Error Handling Tests**
```swift
func testNetworkError() async throws {
    // Mock network failure
    // Verify error message displayed
}
```

3. **Mock Repository Tests**
```swift
func testWithMockRepository() async throws {
    let mock = MockGithubRepository()
    let viewModel = HomeViewModel(repository: mock)
    // Test without hitting real API
}
```

### Medium Priority

4. **Pagination Tests**
5. **User Search Tests**
6. **Favorites Tests**

## Running Unit Tests

### In Xcode
```bash
# All unit tests
Cmd + U

# Single test
Click diamond icon next to test method
```

### Command Line
```bash
# All unit tests
xcodebuild test -scheme github_repo_search_iOS_app \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.6' \
  -only-testing:github_repo_search_iOS_appTests

# Specific test class
xcodebuild test -scheme github_repo_search_iOS_app \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.6' \
  -only-testing:github_repo_search_iOS_appTests/GitRepository_appTests

# Specific test method
xcodebuild test -scheme github_repo_search_iOS_app \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.6' \
  -only-testing:github_repo_search_iOS_appTests/GitRepository_appTests/testGetSearchResultInRepoNameSomeData
```

## Troubleshooting

### Tests Fail Intermittently
Network tests can fail due to:
- API rate limiting
- Network connectivity
- API changes

Solution: Implement mocking for reliable tests

### Async Tests Timeout
Default timeout is too short for slow networks.

Solution: Increase timeout or use mocks

### Tests Pass Locally, Fail in CI
Different simulator versions or network conditions.

Solution: Use consistent simulator versions

## Resources

- [XCTest Documentation](https://developer.apple.com/documentation/xctest)
- [Defining Test Cases](https://developer.apple.com/documentation/xctest/defining_test_cases_and_test_methods)
- [Testing Your Apps](https://developer.apple.com/documentation/xcode/testing-your-apps-in-xcode)

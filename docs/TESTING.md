# Testing Documentation

## Overview
Testing strategy and coverage for GitHub Repository Search iOS app.

**Current Status:**
- **Total: 8 test cases** (all implemented and passing!)
- Unit Tests: 4 tests (3 API tests + 1 performance test) - all passing
- UI Tests: 4 tests (3 UI interaction tests + 1 launch performance) - all passing
- **Success Rate: 8/8 (100%)**
- **Code Coverage: 51.87%** (Improved from 26.68%!)
  - ApiClient: 88.89%
  - HomeView: 87.63% (up from 68.87%)
  - AppSearchBar: 100% (up from 90.48%)
  - SearchItem: 100% (up from 0%)
- Integration Tests: Not explicitly separated

---

## Test Type Matrix

| Test Type     | Framework                     | What It Verifies                    | Our Coverage |
|---------------|-------------------------------|------------------------------------|--------------|
| **Unit (Modern)** | **Swift Testing (`@Test`)** | SwiftData persistence, `@ModelActor`, background sync | **5 suites / tests (100% Passing)** |
| Unit (Classic) | XCTest                        | ViewModels, API Client, Favorites  | 4 tests      |
| Integration   | XCTest                        | Multiple components together       | 2 flows      |
| UI            | XCTest (XCUI)                 | Real user flows on screen          | 3 tests      |
| Performance   | XCTest (Metrics)              | Speed and memory over time         | 1 test       |

**See [testing/readme.md](testing/readme.md) for detailed folder structure and test organization.**

---

## iOS Testing Types (Apple Guidelines)

According to Apple's official documentation, iOS apps should have:

### 1. Unit Tests
**Status:** Implemented
**Location:** `github_repo_search_iOS_appTests/`
**Purpose:** Test individual functions, methods, and classes in isolation

**Current Coverage:**
- API networking (`ApiClient.swift`)
- Repository pattern (`GithubRepository.swift`)
- Request building (`SearchRepoRequest.swift`)
- Error handling (`ApiResponseError.swift`)

**Example:** `GitRepository_appTests.swift` - Tests API calls and data parsing

### 2. UI Tests
**Status:** Partially Implemented
**Location:** `github_repo_search_iOS_appUITests/`
**Purpose:** Test user interface interactions and workflows

**Current Coverage:**
- Launch test (`testHomeHeadView`) - implemented
- Search field test - stub only
- Search results test - stub only

**Example:** `HomeView_appUITests.swift` - Tests UI elements exist

### 3. Performance Tests
**Status:** Implemented
**Location:** `github_repo_search_iOS_appUITests/github_repo_search_iOS_appUITests.swift`
**Purpose:** Measure app performance metrics

**Current Coverage:**
- Launch time measurement (`testLaunchPerformance`)

### 4. Integration Tests
**Status:** Not explicitly separated
**Purpose:** Test how multiple components work together

**Recommendation:** Consider adding tests for:
- View + ViewModel integration
- API + Repository + ViewModel flow
- Navigation flows

---

## Test Suite Details

### Unit Tests (4 tests)

**Location:** `github_repo_search_iOS_appTests/`

**1. testGetSearchResultInRepoNameSomeData**
- Location: `GitRepository_appTests.swift`
- Tests: Successful API calls with valid query
- Covers: `GithubRepository`, `ApiClient`, `SearchRepoRequest`, JSON parsing
- Expected: Returns results with count > 0

**2. testGetSearchResultInRepoNameEmptyResult**
- Location: `GitRepository_appTests.swift`
- Tests: Searches returning no results
- Covers: Empty result handling, edge cases
- Expected: Returns empty or handles gracefully

**3. testGetSearchResultInRepoNameInvalidQuery**
- Location: `GitRepository_appTests.swift`
- Tests: Invalid requests (empty query)
- Covers: Error handling, validation errors
- Expected: Throws validation error

**4. testPerformanceExample**
- Location: `github_repo_search_iOS_appTests.swift`
- Tests: Performance measurement (stub - empty)
- Status: Placeholder for future performance tests

### UI Tests (4 tests)

**Location:** `github_repo_search_iOS_appUITests/`

**1. testHomeHeadView**
- Location: `HomeView_appUITests.swift`
- Tests: Home screen UI elements after splash
- Checks: Navigation bar, search field, header text
- Status: Implemented and passing

**2. testHomeViewBodySearchField**
- Location: `HomeView_appUITests.swift`
- Tests: Search field interaction
- Checks: Field exists, accepts input, text can be typed and cleared
- Status: Implemented and passing

**3. testHomeViewBodySearchResult**
- Location: `HomeView_appUITests.swift`
- Tests: Search results display after typing query
- Checks: Results appear or appropriate message shown (loading/empty/error)
- Status: Implemented and passing

**4. testLaunchPerformance**
- Location: `github_repo_search_iOS_appUITests.swift`
- Tests: App launch time performance
- Measures: XCTApplicationLaunchMetric
- Status: Implemented and passing

### Technology
- XCTest framework with async/await
- @MainActor for thread safety
- All tests use modern Swift concurrency

---

## What's Covered

**Files Tested:**
- `ApiClient.swift` - Networking layer
- `GithubRepository.swift` - Repository pattern
- `SearchRepoRequest.swift` - API requests
- `ApiResponseError.swift` - Error handling

**Not Yet Covered:**
- UI Views, View Models, Navigation

---

## Recent Improvements (July 2026)

**Bug Fixes:**
- Fixed `GithubRepository.swift` to use `perPage` parameter instead of hardcoded constant
- Updated test query from "swiftmvvmin:name" to "swift" for more reliable results
- Fixed UI test `testHomeHeadView` to wait for splash screen and check correct UI elements
- All API tests (3/3) now passing consistently

**New Tests Implemented:**
- `testHomeViewBodySearchField` - Tests search field interaction, typing, and clearing
- `testHomeViewBodySearchResult` - Tests search results display after query
- Both UI test stubs now fully implemented with assertions

**Coverage Improvements:**
- Overall: 26.68% → **51.87%** (nearly doubled!)
- HomeView: 68.87% → **87.63%**
- AppSearchBar: 90.48% → **100%**
- SearchItem: 0% → **100%**

**Status:** All 8 tests passing (100% success rate), 51.87% code coverage

---

## Code Coverage

### What It Is
Measures % of code executed during tests. Helps find untested areas.

**Important Philosophy:**
> 100% code coverage ≠ 100% test coverage
>
> A line being executed doesn't mean its behavior was asserted. Code coverage shows which lines ran, not whether they were properly validated.

### Goals
- Networking & API: 90-100%
- Business Logic: 80-90%
- Overall: 70%+

### How to Enable
**Xcode:** Edit Scheme (⌘<) → Test → Options → Check "Code Coverage"

### How to View
1. Press ⌘9 (Report Navigator)
2. Select test run
3. Click "Coverage" tab
4. See file percentages (green = good, red = needs tests)

### CLI Tool: xccov
Generate coverage reports from command line:
```bash
# View help
xcrun xccov --help
man xccov

# Run tests with coverage
xcodebuild test -scheme github_repo_search_iOS_app \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.6' \
  -enableCodeCoverage YES

# After running tests with coverage enabled
xcrun xccov view --report /path/to/test.xcresult

# Example output shows file-by-file coverage percentages
# github_repo_search_iOS_app.app: 51.87% (1110/2140)
#   ApiClient.swift: 88.89% (32/36)
#   HomeView.swift: 87.63% (425/485)
#   AppSearchBar.swift: 100.00% (42/42)
#   SearchItem.swift: 100.00% (6/6)
#   SplashView.swift: 95.89% (70/73)
```

**Note:** xccov has no web documentation - use `man xccov` for the official reference.

---

## Running Tests

### In Xcode (Easiest)
- **All tests:** Press ⌘U
- **One test:** Click diamond icon
- **Results:** ⌘6 (Test Navigator) or ⌘9 (Report Navigator)

### Command Line
```bash
# All tests
xcodebuild test -scheme github_repo_search_iOS_app \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.6'

# With coverage
xcodebuild test -scheme github_repo_search_iOS_app \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.6' \
  -enableCodeCoverage YES

# Specific test class
xcodebuild test -scheme github_repo_search_iOS_app \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.6' \
  -only-testing:github_repo_search_iOS_appTests/GithubRepository_appTests

# List available simulators
xcrun simctl list devices available
```

---

## Best Practices

- Test independence (no shared state)
- Descriptive test names
- Async/await (no callbacks)
- Arrange-Act-Assert pattern

---

## Troubleshooting

**Tests not running?** Clean build (⌘⇧K) and rebuild (⌘B)

**Coverage not showing?** Enable in scheme, re-run tests

**Tests timeout?** Check network or async/await usage

---

## Quick Start

1. Open Xcode
2. Press ⌘U (run tests)
3. Press ⌘9 → Coverage tab (view results)
4. Done!

---

## What's Missing (Recommendations)

Based on Apple's testing best practices:

1. **Complete UI Tests**
   - Test search field input
   - Test search results display
   - Test navigation flows
   - Test error states

2. **ViewModel Tests**
   - Test HomeViewModel logic
   - Test state changes
   - Test error handling

3. **Integration Tests**
   - Test complete user flows
   - Test API → Repository → ViewModel → View

4. **Snapshot Tests** (Optional)
   - Visual regression testing
   - UI consistency across devices

---

## Future: Swift Testing Migration (iOS 18+)

### What is Swift Testing?

Swift Testing is Apple's modern testing framework introduced in 2024 as the recommended default for new tests.

**Key Differences from XCTest:**

| Feature          | XCTest                    | Swift Testing               |
|------------------|---------------------------|-----------------------------|
| Syntax           | `XCTAssertEqual`          | `#expect`                   |
| Parallel         | Serial by default         | Parallel by default         |
| Parameters       | Manual loops              | `@Test(arguments:)` macro   |
| Async/await      | Supported but verbose     | Native, clean support       |
| UI Tests         | ✓ Supported (XCUI)        | ✗ XCTest only               |
| Performance      | ✓ Supported (Metrics)     | ✗ XCTest only               |

### Example Migration

**Old (XCTest):**
```swift
import XCTest
@testable import MyApp

class CalculatorTests: XCTestCase {
    func testAddition() {
        let calc = Calculator()
        let result = calc.add(2, 3)
        XCTAssertEqual(result, 5)
    }
}
```

**New (Swift Testing):**
```swift
import Testing
@testable import MyApp

struct CalculatorTests {
    @Test func addition() {
        let calc = Calculator()
        let result = calc.add(2, 3)
        #expect(result == 5)
    }
}
```

### Migration Strategy (Recommended by Apple)

1. **Leave existing XCTests alone** - They still run and count
2. **Write all new tests in Swift Testing**
3. **Migrate files you touch most**, at your own pace
4. **UI and Performance tests stay in XCTest** - No migration needed
5. **Both frameworks coexist** - Run side by side in same target

### When to Migrate

- **Now:** If targeting iOS 18+ and starting new tests
- **Later:** If supporting iOS 17 or below (Swift Testing requires iOS 18+)
- **Never:** For UI tests and performance tests (XCTest is the only option)

**Current Project Status:** Using XCTest for all tests (iOS 17+ compatibility)

---

## Resources

### Official Apple Documentation

**Priority #1 - Code Coverage:**
1. [Determining how much code your tests cover](https://developer.apple.com/documentation/xcode/determining-how-much-code-your-tests-cover) - THE official coverage guide (enabling in scheme, reading reports, using coverage to guide test development)

**Testing Hub:**
2. [Test coverage / Testing topic hub](https://developer.apple.com/documentation/xcode/test-coverage) - Parent section covering logic failures, UI problems, performance regressions

**Testing Frameworks:**
3. [XCTest framework reference](https://developer.apple.com/documentation/xctest) - Traditional iOS testing framework
   - [XCUITest](https://developer.apple.com/documentation/xctest/user_interface_tests) - UI testing with XCTest
   - [XCTMetric](https://developer.apple.com/documentation/xctest/performance_tests) - Performance testing metrics
4. [Swift Testing framework reference](https://developer.apple.com/documentation/testing) - Modern Swift-native testing (iOS 18+)

**Command Line Tools:**
5. **xccov CLI** - No web page exists; run `man xccov` or `xcrun xccov --help` in Terminal for the official reference
6. **xcodebuild CLI** - No web page exists; run `man xcodebuild` or `xcodebuild -help` for the official reference

**Additional Resources:**
- [Testing Your Apps in Xcode](https://developer.apple.com/documentation/xcode/testing-your-apps-in-xcode) - Complete Xcode testing guide
- [Running Tests and Interpreting Results](https://developer.apple.com/documentation/xcode/running-tests-and-interpreting-results) - How to run and read test results
- [Defining Test Cases and Test Methods](https://developer.apple.com/documentation/xctest/defining_test_cases_and_test_methods) - How to write XCTest tests

### Key Insights from Apple

**1. Executed ≠ Verified**

A covered line means it ran — not that its behavior was checked. Example:

```swift
func testProcessOrder() {
    let service = OrderService()
    _ = service.process(Order(itemID: "sku-42"))
    // No assertion. Nothing verified.
}
```

Every line in `process()` counts as covered, but if it returns garbage, this test still passes.

**2. Coverage is a Flashlight, Not a Scoreboard**

Apple's official guidance: Coverage exists to **find untested paths and guide new test development**. It's not a metric to maximize.

- 100% code coverage ≠ 100% test coverage
- Coverage measures *execution*; assertions measure *correctness*
- Use it to find red (untested) code, not to chase a percentage

**3. Assertion Quality Matters More Than Percentage**

A file at 85% with sharp assertions beats a file at 100% with none.

---

## Official Apple Documentation & Resources

### 🍏 Modern Swift Testing
- **[Swift Testing Framework Overview](https://developer.apple.com/documentation/testing)** — Official Apple developer documentation for `@Suite`, `@Test`, `#expect`, and tags.
- **[Migrating a Test from XCTest to Swift Testing](https://developer.apple.com/documentation/testing/migratingfromxctest)** — Apple's official step-by-step guide for migrating to Swift Testing.
- **[Parameterized Testing with Argument Matrices](https://developer.apple.com/documentation/testing/parameterizedtesting)** — Running datasets concurrently via `@Test(arguments: [...])`.
- **[WWDC 2024: Meet Swift Testing (Session 10179)](https://developer.apple.com/videos/play/wwdc2024/10179/)** — WWDC introductory session on Swift Testing architecture.
- **[WWDC 2024: Go Further with Swift Testing (Session 10195)](https://developer.apple.com/videos/play/wwdc2024/10195/)** — WWDC deep dive into traits and parallel execution.
- **[Swift Testing Open Source Repository](https://github.com/swiftlang/swift-testing)** — Official open-source package repository.

### 🏛️ Classic XCTest & UI Automation
- **[Apple XCTest Documentation](https://developer.apple.com/documentation/xctest)** — Documentation for XCTest, XCUIApplication, and UI Automation.
- **[Testing Your Apps in Xcode](https://developer.apple.com/documentation/xcode/testing-your-apps-in-xcode)** — Xcode testing workflows.
- **[Code Coverage Guide](https://developer.apple.com/documentation/xcode/determining-how-much-code-your-tests-cover)** — Measuring test coverage in Xcode.

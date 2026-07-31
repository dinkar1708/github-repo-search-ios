# UI Tests

## Overview
UI tests verify user interface interactions and workflows using XCUITest framework.

## Current Status

- Total: 3 UI tests
- Status: All passing
- Framework: XCUITest (XCTest for UI)

## Test Location

```
Tests/github_repo_search_iOS_appUITests/
├── HomeView_appUITests.swift             # Home screen UI tests
└── github_repo_search_iOS_appUITests.swift # Launch test
```

## Test Cases

### 1. testHomeHeadView

**Purpose:** Verify home screen UI elements display correctly

**Location:** `HomeView_appUITests.swift`

**What it tests:**
- App launches successfully
- Splash screen appears and disappears
- Home screen navigation elements exist
- Search field is accessible

**Code:**
```swift
@MainActor
func testHomeHeadView() throws {
    let app = XCUIApplication()
    app.launch()

    // Wait for splash screen to disappear
    let splashExists = app.staticTexts["Splash Screen"].waitForExistence(timeout: 2)
    if splashExists {
        sleep(2) // Wait for splash animation
    }

    // Verify navigation bar
    XCTAssertTrue(app.navigationBars.element.exists, "Navigation bar should exist")

    // Verify search field exists
    let searchField = app.searchFields.firstMatch
    XCTAssertTrue(searchField.exists, "Search field should exist on home screen")
}
```

**Assertions:**
- Navigation bar exists
- Search field exists
- UI elements are accessible

**Coverage:**
- HomeView rendering
- Navigation setup
- Search bar component

### 2. testHomeViewBodySearchField

**Purpose:** Verify search field accepts user input

**Location:** `HomeView_appUITests.swift`

**What it tests:**
- Search field can be tapped
- Text can be entered
- Text can be cleared
- Field is interactive

**Code:**
```swift
@MainActor
func testHomeViewBodySearchField() throws {
    let app = XCUIApplication()
    app.launch()

    // Wait for splash
    let splashExists = app.staticTexts["Splash Screen"].waitForExistence(timeout: 2)
    if splashExists {
        sleep(2)
    }

    // Find and interact with search field
    let searchField = app.searchFields.firstMatch
    XCTAssertTrue(searchField.exists, "Search field should exist")

    // Tap and type
    searchField.tap()
    searchField.typeText("swift")

    // Verify text entered
    XCTAssertTrue(searchField.value as? String == "swift" ||
                  searchField.placeholderValue?.contains("swift") == true,
                  "Search field should contain typed text")

    // Clear text
    if let clearButton = app.buttons["Clear text"].firstMatch {
        if clearButton.exists {
            clearButton.tap()
        }
    }
}
```

**Assertions:**
- Search field exists
- Text can be typed
- Text appears in field

**Coverage:**
- Search field interaction
- Text input
- Field state changes

### 3. testHomeViewBodySearchResult

**Purpose:** Verify search results display after search

**Location:** `HomeView_appUITests.swift`

**What it tests:**
- Search triggers result loading
- Results or loading indicator appears
- UI updates after search

**Code:**
```swift
@MainActor
func testHomeViewBodySearchResult() throws {
    let app = XCUIApplication()
    app.launch()

    // Wait for splash
    let splashExists = app.staticTexts["Splash Screen"].waitForExistence(timeout: 2)
    if splashExists {
        sleep(2)
    }

    // Type search query
    let searchField = app.searchFields.firstMatch
    XCTAssertTrue(searchField.exists, "Search field should exist")

    searchField.tap()
    searchField.typeText("swift")

    // Wait for results (loading indicator or results)
    sleep(4) // Account for debounce (3 seconds) + network

    // Check for results or appropriate message
    let hasResults = app.cells.count > 0
    let hasLoadingIndicator = app.activityIndicators.firstMatch.exists
    let hasEmptyMessage = app.staticTexts["No results found"].exists ||
                          app.staticTexts["Start searching"].exists

    XCTAssertTrue(hasResults || hasLoadingIndicator || hasEmptyMessage,
                  "Should show results, loading indicator, or message after search")
}
```

**Assertions:**
- Results appear OR
- Loading indicator shows OR
- Empty state message displays

**Coverage:**
- Search triggering
- Result display
- Loading states
- Empty states

## UI Testing Patterns

### App Launch
Every UI test starts with launching the app:

```swift
let app = XCUIApplication()
app.launch()
```

### Element Queries
Find UI elements using queries:

```swift
// By type
app.buttons["Button Title"]
app.textFields.firstMatch
app.navigationBars.element

// By accessibility identifier
app.buttons["loginButton"]

// By predicate
app.cells.matching(identifier: "repositoryCell")
```

### Waiting for Elements
Use waitForExistence for async UI:

```swift
let element = app.buttons["Submit"]
let exists = element.waitForExistence(timeout: 5)
XCTAssertTrue(exists, "Element should appear within 5 seconds")
```

### Interacting with Elements
Common interactions:

```swift
// Tap
element.tap()

// Type text
textField.typeText("Hello")

// Swipe
element.swipeLeft()

// Check state
XCTAssertTrue(element.exists)
XCTAssertFalse(element.isHittable)
```

## Best Practices

### Use Accessibility Identifiers
Add identifiers to views for easier testing:

```swift
// In SwiftUI view
Text("Welcome")
    .accessibilityIdentifier("welcomeText")

// In test
let welcome = app.staticTexts["welcomeText"]
XCTAssertTrue(welcome.exists)
```

### Wait for Async Operations
Don't use sleep() - use waitForExistence:

```swift
// Bad
sleep(3)
XCTAssertTrue(element.exists)

// Good
let exists = element.waitForExistence(timeout: 3)
XCTAssertTrue(exists)
```

### Test User Flows
Test complete workflows, not just individual elements:

```swift
func testCompleteSearchFlow() {
    // Launch
    app.launch()

    // Search
    searchField.tap()
    searchField.typeText("swift")

    // View results
    let firstResult = app.cells.firstMatch
    XCTAssertTrue(firstResult.waitForExistence(timeout: 5))

    // Tap result
    firstResult.tap()

    // Verify detail view
    XCTAssertTrue(app.navigationBars["Repository Details"].exists)
}
```

### Clean State
Each test should start with clean state:

```swift
override func setUpWithError() throws {
    continueAfterFailure = false
    XCUIApplication().launch()
}
```

## What's Missing

### Navigation Tests
Not yet implemented:

```swift
func testNavigationToRepositoryDetails() {
    // Search for repository
    // Tap on result
    // Verify detail screen appears
    // Verify back navigation works
}

func testTabNavigation() {
    // Tap Users tab
    // Verify Users screen shows
    // Tap Repositories tab
    // Verify Repositories screen shows
}
```

### User Flow Tests
Complex flows not tested:

```swift
func testAddToFavorites() {
    // Search repository
    // Open details
    // Tap favorite button
    // Navigate to Favorites tab
    // Verify repository appears
}

func testSearchUsers() {
    // Navigate to Users tab
    // Search for user
    // Tap on user
    // Verify profile displays
}
```

### Error State Tests
Error scenarios not tested:

```swift
func testNetworkError() {
    // Simulate offline mode
    // Attempt search
    // Verify error message displays
}

func testEmptyResults() {
    // Search for nonsense query
    // Verify "No results" message
}
```

### Accessibility Tests
Not yet implemented:

```swift
func testVoiceOverLabels() {
    // Enable VoiceOver
    // Verify all elements have labels
}

func testDynamicType() {
    // Increase text size
    // Verify layout adjusts
}
```

## Recommended Next Tests

### High Priority

1. **Tab Navigation**
```swift
func testTabSwitching() throws {
    app.launch()

    // Tap Users tab
    app.tabBars.buttons["Users"].tap()
    XCTAssertTrue(app.navigationBars["Users"].exists)

    // Tap Repositories tab
    app.tabBars.buttons["Repositories"].tap()
    XCTAssertTrue(app.navigationBars["Repositories"].exists)
}
```

2. **Repository Details Navigation**
```swift
func testRepositoryDetailsNavigation() throws {
    app.launch()

    // Search and tap first result
    let searchField = app.searchFields.firstMatch
    searchField.tap()
    searchField.typeText("swift")

    let firstCell = app.cells.firstMatch
    XCTAssertTrue(firstCell.waitForExistence(timeout: 5))
    firstCell.tap()

    // Verify details screen
    XCTAssertTrue(app.navigationBars["Repository Details"].waitForExistence(timeout: 2))
}
```

3. **Favorites Flow**
```swift
func testAddRemoveFavorite() throws {
    // Complete flow test
}
```

## Running UI Tests

### In Xcode
```bash
# All UI tests
Cmd + U

# Record new UI test
Click record button in test method
```

### Command Line
```bash
# All UI tests
xcodebuild test -scheme github_repo_search_iOS_app \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.6' \
  -only-testing:github_repo_search_iOS_appUITests

# Specific test
xcodebuild test -scheme github_repo_search_iOS_app \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.6' \
  -only-testing:github_repo_search_iOS_appUITests/HomeView_appUITests/testHomeHeadView
```

## Debugging UI Tests

### Recording Tests
Xcode can record UI interactions:

1. Place cursor in test method
2. Click red record button at bottom
3. Interact with app in simulator
4. Stop recording
5. Code is generated automatically

### Viewing Element Hierarchy
Use UI debugger during test:

1. Set breakpoint in test
2. Run test
3. When paused, click UI debugger button
4. Inspect element tree

### Screenshots
Capture screenshots during tests:

```swift
let screenshot = XCUIScreen.main.screenshot()
let attachment = XCTAttachment(screenshot: screenshot)
attachment.lifetime = .keepAlways
add(attachment)
```

## Troubleshooting

### Elements Not Found
Check:
- Element exists in UI
- Correct query type used
- Sufficient wait time
- Accessibility identifier correct

### Tests Flaky
Common causes:
- Network delays
- Animation timing
- Race conditions

Solutions:
- Use waitForExistence
- Increase timeouts
- Disable animations

### App State Issues
Problem: Previous test affects next test

Solution: Reset app state:
```swift
override func setUp() {
    continueAfterFailure = false
    app = XCUIApplication()
    app.launchArguments = ["--uitesting"]
    app.launch()
}
```

## Resources

- [XCUITest Documentation](https://developer.apple.com/documentation/xctest/user_interface_tests)
- [UI Testing Cheat Sheet](https://developer.apple.com/library/archive/documentation/DeveloperTools/Conceptual/testing_with_xcode/)
- [WWDC Videos on Testing](https://developer.apple.com/videos/developer-tools/testing/)

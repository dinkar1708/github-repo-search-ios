# Performance Tests

## Overview
Performance tests measure app speed, responsiveness, and resource usage.

## Current Status

- Total: 1 performance test
- Status: Passing
- Framework: XCTest Performance Metrics

## Test Location

```
Tests/github_repo_search_iOS_appUITests/
└── github_repo_search_iOS_appUITests.swift
```

## Test Cases

### 1. testLaunchPerformance

**Purpose:** Measure app launch time

**Location:** `github_repo_search_iOS_appUITests.swift`

**What it measures:**
- Time from app launch to first frame
- Cold start performance
- Initialization overhead

**Code:**
```swift
func testLaunchPerformance() throws {
    if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
```

**Metrics:**
- XCTApplicationLaunchMetric
- Baseline: Established on first run
- Regression detection: Automatic

**Expected Results:**
- Launch time: < 1 second
- Consistent across runs
- No significant regressions

## Performance Metrics

### Available Metrics

XCTest provides several performance metrics:

#### 1. XCTApplicationLaunchMetric
Measures app launch time.

```swift
measure(metrics: [XCTApplicationLaunchMetric()]) {
    XCUIApplication().launch()
}
```

#### 2. XCTClockMetric
Measures wall clock time.

```swift
measure(metrics: [XCTClockMetric()]) {
    // Code to measure
    performExpensiveOperation()
}
```

#### 3. XCTCPUMetric
Measures CPU time and cycles.

```swift
measure(metrics: [XCTCPUMetric()]) {
    // Code to measure
    processBigData()
}
```

#### 4. XCTMemoryMetric
Measures memory usage.

```swift
measure(metrics: [XCTMemoryMetric()]) {
    // Code to measure
    loadLargeDataset()
}
```

#### 5. XCTStorageMetric
Measures disk I/O.

```swift
measure(metrics: [XCTStorageMetric()]) {
    // Code to measure
    saveToDatabase()
}
```

## Recommended Performance Tests

### 1. Search Performance

**Purpose:** Measure search operation speed

```swift
@MainActor
func testSearchPerformance() async throws {
    let viewModel = HomeViewModel()

    measure(metrics: [XCTClockMetric()]) {
        Task {
            viewModel.searchText = "swift"
            await viewModel.performSearch()
        }
    }
}
```

**Expected:** < 2 seconds for typical search

### 2. Scroll Performance

**Purpose:** Measure list scrolling smoothness

```swift
func testScrollPerformance() throws {
    let app = XCUIApplication()
    app.launch()

    // Perform search first
    let searchField = app.searchFields.firstMatch
    searchField.tap()
    searchField.typeText("swift")
    sleep(4)

    measure(metrics: [XCTOSSignpostMetric.scrollDecelerationMetric]) {
        app.tables.firstMatch.swipeUp(velocity: .fast)
    }
}
```

**Expected:** Smooth 60fps scrolling

### 3. Image Loading Performance

**Purpose:** Measure avatar/image loading speed

```swift
func testImageLoadingPerformance() throws {
    let app = XCUIApplication()
    app.launch()

    measure(metrics: [XCTClockMetric(), XCTMemoryMetric()]) {
        // Navigate to user search
        app.tabBars.buttons["Users"].tap()

        // Search for users
        let searchField = app.searchFields.firstMatch
        searchField.tap()
        searchField.typeText("apple")

        // Wait for images to load
        sleep(3)
    }
}
```

**Expected:** Images load within 2 seconds

### 4. Data Parsing Performance

**Purpose:** Measure JSON decoding speed

```swift
func testJSONParsingPerformance() throws {
    let repository = GithubRepositoryImpl()

    measure(metrics: [XCTClockMetric(), XCTCPUMetric()]) {
        Task {
            _ = try await repository.searchRepositories(query: "swift", page: 1)
        }
    }
}
```

**Expected:** < 100ms for typical response

### 5. Favorites Loading Performance

**Purpose:** Measure Keychain retrieval speed

```swift
@MainActor
func testFavoritesLoadingPerformance() async throws {
    let manager = FavoritesManager()

    measure(metrics: [XCTClockMetric(), XCTStorageMetric()]) {
        Task {
            await manager.loadFavorites()
        }
    }
}
```

**Expected:** < 50ms for typical favorites list

### 6. View Rendering Performance

**Purpose:** Measure view update speed

```swift
@MainActor
func testViewRenderingPerformance() async throws {
    let viewModel = HomeViewModel()

    // Load data first
    viewModel.searchText = "swift"
    await viewModel.performSearch()

    measure(metrics: [XCTClockMetric()]) {
        // Trigger view update
        viewModel.repositories = viewModel.repositories
    }
}
```

**Expected:** < 16ms (60fps) for view update

## Setting Baselines

### First Run
1. Run performance test
2. Results appear in Report Navigator
3. Click "Set Baseline"
4. Future runs compare against baseline

### Updating Baselines
1. Run performance test
2. If intentional improvement, update baseline
3. Click "Accept" in results

### Baseline Storage
Baselines stored in:
```
*.xcodeproj/xcshareddata/xcbaselines/
```

Commit these files to version control.

## Interpreting Results

### Result Values
- **Average:** Mean of all iterations
- **Std Dev:** Variance in measurements
- **Max:** Worst case performance

### Regression Detection
Xcode flags regressions automatically:
- Red: Significant regression (>10%)
- Yellow: Minor regression (5-10%)
- Green: No regression

### Acceptable Variance
- Launch time: < 5% variance
- Network operations: < 10% variance
- UI operations: < 3% variance

## Performance Goals

### Critical Paths
Operations users wait for:

- App launch: < 1 second
- Search results: < 2 seconds
- Screen transitions: < 300ms
- Image loading: < 2 seconds

### Background Operations
Non-blocking operations:

- Cache write: < 100ms
- Analytics tracking: < 50ms
- Favorites save: < 100ms

### Memory Usage
- Idle: < 50 MB
- Active search: < 100 MB
- Image cache: < 150 MB total

## Running Performance Tests

### In Xcode
```bash
# All performance tests
Cmd + U

# View results
Report Navigator (Cmd + 9)
```

### Command Line
```bash
# Run performance tests
xcodebuild test -scheme github_repo_search_iOS_app \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.6' \
  -only-testing:github_repo_search_iOS_appUITests/github_repo_search_iOS_appUITests/testLaunchPerformance
```

## Best Practices

### Consistent Environment
Run tests on:
- Same device/simulator
- Same iOS version
- Same build configuration (Release)
- Quiet system (no background tasks)

### Sufficient Iterations
Default is 5 iterations. Increase for more accuracy:

```swift
let options = XCTMeasureOptions()
options.iterationCount = 10

measure(options: options, metrics: [XCTClockMetric()]) {
    // Code to measure
}
```

### Warm Up
Exclude first run if needed:

```swift
func testWithWarmup() {
    // Warm up
    performOperation()

    // Actual measurement
    measure {
        performOperation()
    }
}
```

### Isolate Code
Measure only the code you care about:

```swift
// Bad - measures setup too
measure {
    let data = loadTestData()
    processData(data)
}

// Good - measures processing only
let data = loadTestData()
measure {
    processData(data)
}
```

## Profiling Tools

### Instruments
For deeper analysis:

1. Product → Profile (Cmd + I)
2. Choose template:
   - Time Profiler (CPU usage)
   - Allocations (memory)
   - Network (requests)
3. Record and analyze

### Common Templates
- **Time Profiler:** Find slow code
- **Allocations:** Track memory usage
- **Leaks:** Find memory leaks
- **Network:** Monitor API calls
- **Energy Log:** Battery impact

## Optimization Strategies

### Lazy Loading
Load data only when needed:

```swift
// Before - loads everything
let allData = loadEverything()

// After - loads on demand
func getData(index: Int) -> Data {
    return loadDataAt(index)
}
```

### Caching
Cache expensive operations:

```swift
// Before - parses every time
let result = parseJSON(data)

// After - caches parsed result
if let cached = cache.get(for: key) {
    return cached
}
let result = parseJSON(data)
cache.set(result, for: key)
```

### Background Processing
Move heavy work off main thread:

```swift
// Before - blocks UI
let result = expensiveOperation()
updateUI(result)

// After - async processing
Task.detached {
    let result = expensiveOperation()
    await MainActor.run {
        updateUI(result)
    }
}
```

### Image Optimization
- Use AsyncImage for automatic caching
- Downsample large images
- Use WebP or HEIC format

## Monitoring in Production

### Analytics
Track real-world performance:

```swift
let startTime = Date()
performOperation()
let duration = Date().timeIntervalSince(startTime)

analytics.track(event: .performance(
    operation: "search",
    duration: duration
))
```

### Crash Reporting
Monitor performance-related crashes:
- Out of memory
- Watchdog timeouts
- ANR (App Not Responding)

### User Metrics
Track key performance indicators:
- Time to first search
- Average search duration
- Screen load times

## Troubleshooting

### Inconsistent Results
Causes:
- Background processes
- Network variability
- Thermal throttling

Solutions:
- Run multiple times
- Use Release build
- Test on device, not simulator

### No Baseline
If baseline missing:
- Run test once
- Click "Set Baseline"
- Commit baseline file

### False Regressions
If flagged incorrectly:
- Check for real changes
- Verify environment consistency
- Update baseline if intentional

## Resources

- [XCTest Performance Metrics](https://developer.apple.com/documentation/xctest/performance_tests)
- [Instruments Documentation](https://developer.apple.com/documentation/xcode/improving-your-app-s-performance)
- [WWDC Performance Videos](https://developer.apple.com/videos/developer-tools/performance/)

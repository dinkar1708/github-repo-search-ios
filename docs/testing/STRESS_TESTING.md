# Stress Testing for iOS Apps

## Overview

Stress testing pushes your app beyond normal operating conditions to find breaking points, memory leaks, and performance degradation. This is critical for production-ready apps.

## What is Stress Testing?

**Definition:** Testing app behavior under extreme conditions:
- Rapid user interactions (fast scrolling, quick taps)
- Large data sets (thousands of items)
- Memory pressure (low memory warnings)
- Network issues (slow/unstable connections)
- Extended runtime (hours of continuous use)
- Concurrent operations (multiple simultaneous actions)

**Goal:** Find bugs that only appear under heavy load or extended use.

## Common Mobile Stress Test Scenarios

### 1. Heavy Scrolling (Most Common)

**What to test:**
- Scroll through 1000+ items rapidly
- Fling scrolls (fast, momentum-based)
- Quick direction changes
- Scroll while loading data

**What can break:**
- Memory leaks from unreleased cells
- Main thread blocking (janky UI)
- Image cache overflow
- Network request pileup
- Cell reuse bugs

**How to test:**

#### Manual Testing
```
1. Load search with many results
2. Scroll down rapidly for 30 seconds
3. Scroll up rapidly for 30 seconds
4. Repeat 10 times
5. Check memory usage in Xcode Debug Navigator
6. Look for:
   - Memory growth (indicates leaks)
   - Frame drops (indicates UI lag)
   - Crashes
```

#### Automated Testing (XCUITest)
```swift
func testHeavyScrollingStress() throws {
    let app = XCUIApplication()
    app.launch()

    // Perform search to get many results
    let searchField = app.searchFields.firstMatch
    searchField.tap()
    searchField.typeText("swift")

    // Wait for results
    let table = app.tables.firstMatch
    XCTAssertTrue(table.waitForExistence(timeout: 5))

    // Stress test: Rapid scrolling for 60 seconds
    measure(metrics: [XCTMemoryMetric(), XCTCPUMetric()]) {
        let startTime = Date()
        while Date().timeIntervalSince(startTime) < 60 {
            // Scroll down
            table.swipeUp(velocity: .fast)
            table.swipeUp(velocity: .fast)
            table.swipeUp(velocity: .fast)

            // Scroll up
            table.swipeDown(velocity: .fast)
            table.swipeDown(velocity: .fast)

            // Brief pause to allow rendering
            usleep(50_000) // 50ms
        }
    }
}
```

**Expected results:**
- Memory stays stable (< 150 MB)
- 60 FPS scrolling maintained
- No crashes or hangs

### 2. Fast Tab Switching

**What to test:**
- Rapidly switch between tabs
- Switch before content finishes loading
- Switch during network requests

**What can break:**
- Race conditions
- Memory leaks from uncancelled tasks
- State inconsistencies
- Multiple simultaneous API calls

**How to test:**

```swift
func testRapidTabSwitchingStress() throws {
    let app = XCUIApplication()
    app.launch()

    let tabBar = app.tabBars.firstMatch
    let usersTab = tabBar.buttons["Users"]
    let reposTab = tabBar.buttons["Repositories"]
    let favoritesTab = tabBar.buttons["Favorites"]
    let settingsTab = tabBar.buttons["Settings"]

    measure(metrics: [XCTMemoryMetric()]) {
        // Rapid tab switching for 30 seconds
        let startTime = Date()
        while Date().timeIntervalSince(startTime) < 30 {
            usersTab.tap()
            usleep(100_000) // 100ms

            reposTab.tap()
            usleep(100_000)

            favoritesTab.tap()
            usleep(100_000)

            settingsTab.tap()
            usleep(100_000)
        }
    }
}
```

**Expected results:**
- No crashes
- Memory doesn't grow unbounded
- UI stays responsive
- Cancelled tasks don't cause errors

### 3. Rapid Search Input

**What to test:**
- Type and delete quickly
- Paste large text
- Rapid query changes
- Search while previous search is loading

**What can break:**
- Debounce logic
- Request cancellation
- UI state synchronization
- Memory from uncancelled requests

**How to test:**

```swift
func testRapidSearchInputStress() throws {
    let app = XCUIApplication()
    app.launch()

    let searchField = app.searchFields.firstMatch
    searchField.tap()

    measure(metrics: [XCTMemoryMetric(), XCTCPUMetric()]) {
        // Rapid typing and clearing
        for _ in 0..<50 {
            searchField.typeText("swift")
            usleep(200_000) // 200ms - faster than debounce

            searchField.clearText() // Helper method
            usleep(100_000)

            searchField.typeText("ios")
            usleep(200_000)

            searchField.clearText()
            usleep(100_000)
        }
    }
}

// Helper extension
extension XCUIElement {
    func clearText() {
        guard let stringValue = self.value as? String else {
            return
        }

        let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue,
                                  count: stringValue.count)
        self.typeText(deleteString)
    }
}
```

**Expected results:**
- Debouncing prevents request spam
- Old requests are cancelled
- No memory leaks
- UI stays responsive

### 4. Memory Pressure Testing

**What to test:**
- App behavior when iOS sends memory warnings
- Large image loading
- Caching under memory constraints

**What can break:**
- App crashes (memory exceeded)
- Cache eviction failures
- Slow memory cleanup

**How to test:**

#### Manual Testing with Xcode
```
1. Run app on simulator
2. Debug → Simulate Memory Warning
3. Repeat while using app heavily
4. Monitor memory in Debug Navigator
```

#### Automated Testing
```swift
func testMemoryWarningHandling() throws {
    let app = XCUIApplication()
    app.launch()

    // Load lots of data
    let searchField = app.searchFields.firstMatch
    searchField.tap()
    searchField.typeText("swift")

    // Wait for images to load
    sleep(3)

    // Simulate memory warning
    XCTContext.runActivity(named: "Simulate memory pressure") { _ in
        // This requires manual testing with Xcode Debug menu
        // or using low memory device for automated tests

        // Continue using app after memory warning
        app.tables.firstMatch.swipeUp()
        app.tables.firstMatch.swipeDown()

        // App should still be responsive
        XCTAssertTrue(app.tables.firstMatch.exists)
    }
}
```

**Expected results:**
- App clears caches appropriately
- UI remains functional
- No crash on memory warning
- Memory usage drops after warning

### 5. Long-Running Session

**What to test:**
- App running for hours
- Continuous interactions
- Background/foreground cycling

**What can break:**
- Slow memory leaks
- Resource accumulation
- State corruption over time
- Timer/observer leaks

**How to test:**

```swift
func testLongRunningSessionStress() throws {
    let app = XCUIApplication()
    app.launch()

    // Initial memory baseline
    let startMetrics = XCTMemoryMetric()

    measure(metrics: [XCTMemoryMetric()]) {
        // Simulate 1 hour of use (compressed to 5 minutes for test)
        for iteration in 0..<60 {
            // Search
            let searchField = app.searchFields.firstMatch
            searchField.tap()
            searchField.typeText("test\(iteration)")
            sleep(2)
            searchField.clearText()

            // Browse
            app.tables.firstMatch.swipeUp()
            sleep(1)

            // Switch tabs
            app.tabBars.buttons["Favorites"].tap()
            sleep(1)
            app.tabBars.buttons["Repositories"].tap()
            sleep(1)

            // Background/foreground (every 10 iterations)
            if iteration % 10 == 0 {
                XCUIDevice.shared.press(.home)
                sleep(1)
                app.activate()
                sleep(1)
            }
        }
    }
}
```

**Expected results:**
- Memory stays stable over time
- No growing memory usage
- No performance degradation
- App restores correctly from background

### 6. Concurrent Operations

**What to test:**
- Multiple simultaneous user actions
- Favoriting while searching
- Loading user profile while searching repos
- Pull-to-refresh during active search

**What can break:**
- Race conditions
- Data corruption
- UI state conflicts
- Concurrent API request issues

**How to test:**

```swift
func testConcurrentOperationsStress() throws {
    let app = XCUIApplication()
    app.launch()

    measure(metrics: [XCTMemoryMetric(), XCTCPUMetric()]) {
        // Perform multiple actions simultaneously
        for _ in 0..<20 {
            // Start search
            let searchField = app.searchFields.firstMatch
            searchField.tap()
            searchField.typeText("swift")

            // Immediately switch tabs (interrupts search)
            app.tabBars.buttons["Users"].tap()

            // Start another search
            let userSearch = app.searchFields.firstMatch
            userSearch.tap()
            userSearch.typeText("apple")

            // Switch back while loading
            app.tabBars.buttons["Repositories"].tap()

            // Pull to refresh while search is active
            app.tables.firstMatch.swipeDown(velocity: .fast)

            sleep(2) // Let operations settle
        }
    }
}
```

**Expected results:**
- No crashes
- No data corruption
- Proper task cancellation
- UI stays consistent

### 7. Network Stress Testing

**What to test:**
- Slow network conditions
- Network interruptions
- Request timeouts
- Rapid online/offline switching

**What to test with Xcode Network Link Conditioner:**

```
1. Install Network Link Conditioner:
   Xcode → Open Developer Tool → More Developer Tools
   Download "Additional Tools for Xcode"
   Install Network Link Conditioner.prefPane

2. Test scenarios:
   - 3G connection (slow)
   - 100% packet loss (offline)
   - High latency (1000ms)
   - Switch profiles during use
```

**Automated testing:**

```swift
func testSlowNetworkStress() throws {
    // Note: This requires Network Link Conditioner to be set manually
    // or use URLSessionConfiguration with custom protocol for mocking

    let app = XCUIApplication()
    app.launch()

    measure(metrics: [XCTClockMetric()]) {
        let searchField = app.searchFields.firstMatch
        searchField.tap()

        // Perform multiple searches under slow network
        for i in 0..<10 {
            searchField.clearText()
            searchField.typeText("test\(i)")

            // Don't wait for completion - stress the queuing
            usleep(500_000) // 500ms - less than network time
        }

        // Wait for final results
        sleep(10)
    }
}
```

**Expected results:**
- App shows loading states
- No crashes on timeout
- Graceful error handling
- User can still interact with UI

## Best Practices for Mobile Stress Testing

### 1. Test on Real Devices

**Why:**
- Simulators have unlimited memory
- Simulators have faster CPUs
- Real network conditions
- Actual thermal throttling

**How:**
- Test on oldest supported device (iPhone with iOS 17)
- Test on low-memory devices
- Test on slow network (not just WiFi)

### 2. Monitor Key Metrics

**During stress tests, watch:**

| Metric | Tool | Threshold | Action if Exceeded |
|--------|------|-----------|-------------------|
| Memory | Xcode Debug Navigator | < 150 MB | Find leaks, reduce cache |
| CPU | Instruments Time Profiler | < 40% sustained | Optimize hot paths |
| Frame Rate | Instruments Core Animation | 60 FPS | Remove main thread work |
| Network | Instruments Network | < 5 concurrent | Implement request queuing |
| Battery | Instruments Energy Log | Low to Moderate | Reduce background work |

### 3. Use Xcode Debugging Tools

**Memory Graph Debugger:**
```
1. Run app under stress
2. Click "Debug Memory Graph" button in Xcode
3. Look for:
   - Retain cycles (circular references)
   - Leaked objects (marked with "!")
   - Growing object counts
```

**View Hierarchy Debugger:**
```
1. Run app under stress
2. Click "Debug View Hierarchy" button
3. Look for:
   - Excessive view nesting
   - Hidden but allocated views
   - Offscreen rendered views
```

### 4. Automated Stress Testing in CI/CD

**Add to GitHub Actions workflow:**

```yaml
- name: Run Stress Tests
  run: |
    xcodebuild test \
      -project github_repo_search_iOS_app.xcodeproj \
      -scheme github_repo_search_iOS_app \
      -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.6' \
      -only-testing:github_repo_search_iOS_appUITests/StressTests \
      -resultBundlePath TestResults

- name: Check Memory Metrics
  run: |
    # Parse xcresult for memory metrics
    xcrun xcresulttool get --path TestResults.xcresult \
      --format json | jq '.metrics.memory'
```

### 5. Realistic Test Data

**Use production-like data:**
- Search queries that return 1000+ results
- User profiles with 100+ repositories
- Large images (profile avatars)
- Realistic API response times

**Mock data for stress tests:**

```swift
// MockApiClient for stress testing
final class StressTestApiClient: ApiClient {
    func searchRepositories(query: String, page: Int) async throws -> SearchRepositories {
        // Return 1000 items to stress UI
        let items = (0..<1000).map { i in
            SearchItem(
                id: i,
                name: "Repo \(i)",
                fullName: "owner/repo-\(i)",
                description: "A test repository with a long description...",
                owner: Owner(login: "user\(i)", avatarUrl: "https://..."),
                stargazersCount: Int.random(in: 0...10000),
                forksCount: Int.random(in: 0...1000),
                language: "Swift",
                htmlUrl: "https://github.com/owner/repo-\(i)"
            )
        }

        return SearchRepositories(
            totalCount: 1000,
            incompleteResults: false,
            items: items
        )
    }
}
```

## Common Issues Found by Stress Testing

### Issue 1: Memory Leaks in List Cells

**Symptom:** Memory grows continuously during scrolling

**Cause:**
```swift
// Bad - retains self in closure
cell.imageView.onLoad = {
    self.updateBadge()
}
```

**Fix:**
```swift
// Good - weak self prevents retain cycle
cell.imageView.onLoad = { [weak self] in
    self?.updateBadge()
}
```

### Issue 2: Main Thread Blocking

**Symptom:** Janky scrolling, UI freezes

**Cause:**
```swift
// Bad - JSON parsing on main thread
@MainActor
func loadData() {
    let data = heavyJSONParsing() // Blocks UI
}
```

**Fix:**
```swift
// Good - parsing on background thread
func loadData() async {
    let data = await Task.detached {
        heavyJSONParsing()
    }.value

    await MainActor.run {
        updateUI(data)
    }
}
```

### Issue 3: Request Pileup

**Symptom:** Hundreds of pending network requests

**Cause:**
```swift
// Bad - no cancellation
func search(query: String) async {
    let results = try? await api.search(query)
    updateUI(results)
}
```

**Fix:**
```swift
// Good - cancel previous requests
private var searchTask: Task<Void, Never>?

func search(query: String) {
    searchTask?.cancel() // Cancel previous

    searchTask = Task {
        try? await Task.sleep(nanoseconds: 800_000_000) // Debounce

        guard !Task.isCancelled else { return }

        let results = try? await api.search(query)

        guard !Task.isCancelled else { return }
        updateUI(results)
    }
}
```

### Issue 4: Cache Overflow

**Symptom:** Memory warning, slow performance

**Cause:**
```swift
// Bad - unlimited cache
var imageCache: [String: UIImage] = [:]
```

**Fix:**
```swift
// Good - NSCache with limits
let imageCache: NSCache<NSString, UIImage> = {
    let cache = NSCache<NSString, UIImage>()
    cache.countLimit = 100 // Max 100 images
    cache.totalCostLimit = 50 * 1024 * 1024 // 50 MB
    return cache
}()
```

### Issue 5: Uncancelled Timers

**Symptom:** Memory leaks, crashes after view dismissal

**Cause:**
```swift
// Bad - timer not invalidated
class ViewModel {
    var timer = Timer.scheduledTimer(...)
    // Timer keeps running after ViewModel is released
}
```

**Fix:**
```swift
// Good - cancel timer
class ViewModel {
    var timer: Timer?

    deinit {
        timer?.invalidate()
    }
}

// Better - use Task with automatic cancellation
class ViewModel {
    var refreshTask: Task<Void, Never>?

    func startRefreshing() {
        refreshTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 5_000_000_000)
                await refresh()
            }
        }
    }

    deinit {
        refreshTask?.cancel()
    }
}
```

## Stress Testing Checklist

Before releasing to production, verify:

- [ ] Heavy scrolling (1000+ items, 60+ seconds)
- [ ] Fast tab switching (30+ seconds of rapid switching)
- [ ] Rapid search input (50+ quick queries)
- [ ] Memory warnings handled gracefully
- [ ] Long sessions (30+ minutes) show stable memory
- [ ] Concurrent operations don't crash
- [ ] Slow network doesn't hang UI
- [ ] Background/foreground cycles work correctly
- [ ] Memory stays under 150 MB during heavy use
- [ ] 60 FPS scrolling maintained
- [ ] No visible memory leaks in Memory Graph
- [ ] Tested on oldest supported device

## Tools Summary

| Tool | Purpose | When to Use |
|------|---------|-------------|
| **XCUITest** | Automated stress tests | CI/CD, regression testing |
| **Xcode Debug Navigator** | Real-time memory/CPU | During manual testing |
| **Instruments Time Profiler** | Find slow code | Performance optimization |
| **Instruments Allocations** | Track memory usage | Find leaks, reduce memory |
| **Memory Graph Debugger** | Find retain cycles | Investigate memory issues |
| **Network Link Conditioner** | Slow network testing | Test error handling |
| **Device Console** | View system logs | Debug crashes, warnings |

## Recommended Stress Test Suite

Create dedicated stress test target:

```
github_repo_search_iOS_app_StressTests/
├── ScrollingStressTests.swift
├── TabSwitchingStressTests.swift
├── SearchInputStressTests.swift
├── MemoryPressureTests.swift
├── LongSessionTests.swift
├── ConcurrentOperationTests.swift
└── NetworkStressTests.swift
```

Run nightly or before releases:
```bash
xcodebuild test \
  -project github_repo_search_iOS_app.xcodeproj \
  -scheme github_repo_search_iOS_app \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.6' \
  -only-testing:github_repo_search_iOS_app_StressTests
```

## Resources

- [Apple - Testing in Xcode](https://developer.apple.com/documentation/xcode/testing-your-apps-in-xcode)
- [WWDC - Testing and Debugging](https://developer.apple.com/videos/developer-tools/testing-and-debugging/)
- [iOS Memory Deep Dive](https://developer.apple.com/videos/play/wwdc2018/416/)
- [Network Link Conditioner](https://developer.apple.com/download/all/)

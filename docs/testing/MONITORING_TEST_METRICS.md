# Monitoring Test Metrics During Execution

## Overview

Yes, you CAN monitor performance metrics while running test cases! This guide shows you how to track memory, CPU, and other metrics during test execution.

## Methods to Monitor Tests

### 1. Xcode Debug Navigator (Real-Time Monitoring)

**Best for:** Manual test runs, live monitoring during development

**How to use:**

```
1. Open Xcode
2. Run tests (⌘U)
3. Click Debug Navigator (⌘7) while tests run
4. Watch real-time graphs:
   - CPU usage
   - Memory usage
   - Disk I/O
   - Network activity
```

**What you'll see:**

| Metric | Graph | What to Watch |
|--------|-------|---------------|
| **CPU** | Blue line | Should stay < 40% sustained, spikes OK |
| **Memory** | Green line | Should stay < 150MB, watch for growth |
| **Energy Impact** | Battery icon | Should be "Low" or "Moderate" |
| **Network** | Up/down arrows | Number of concurrent requests |

**Screenshot:**
```
Debug Navigator while tests run:
├── CPU: 25% (Good)
├── Memory: 87 MB (Good)
├── Energy Impact: Low (Good)
├── Disk: 2.1 MB written
└── Network: 3 requests
```

### 2. XCTest Metrics (Automated Monitoring)

**Best for:** CI/CD, automated regression testing

**Built-in metrics you can track:**

```swift
// Memory usage during test
measure(metrics: [XCTMemoryMetric()]) {
    // Your test code
    performHeavyScrolling()
}

// CPU time
measure(metrics: [XCTCPUMetric()]) {
    performExpensiveOperation()
}

// Wall clock time
measure(metrics: [XCTClockMetric()]) {
    searchAndDisplayResults()
}

// Multiple metrics together
measure(metrics: [XCTMemoryMetric(), XCTCPUMetric(), XCTClockMetric()]) {
    performCompleteUserFlow()
}
```

**Example output:**
```
✓ testHeavyScrolling60Seconds (30.5 seconds) passed
  Metrics:
    Memory Physical: 142.3 MB (baseline: 130.5 MB, δ +9%)
    CPU Time: 2.54 s (baseline: 2.31 s, δ +10%)
    CPU Instructions Retired: 3.2B (baseline: 2.9B, δ +10%)
```

### 3. Xcode Test Results (Post-Test Analysis)

**Best for:** Reviewing test runs, comparing baselines

**How to view:**

```
1. Run tests (⌘U)
2. Open Report Navigator (⌘9)
3. Click latest test run
4. View detailed metrics:
   - Test duration
   - Memory usage
   - CPU usage
   - Performance baselines
```

**What's included:**
- ✓ Average values
- ✓ Standard deviation
- ✓ Max values
- ✓ Regression detection
- ✓ Comparison with baseline

### 4. Instruments Profiling (Deep Analysis)

**Best for:** Investigating specific performance issues

**How to profile tests:**

```bash
# Method 1: Profile from Xcode
1. Product → Profile (⌘I)
2. Choose "Time Profiler" or "Allocations"
3. Click Record
4. Manually run test scenario
5. Stop and analyze

# Method 2: Run tests with profiling
xcodebuild test \
  -project MyApp.xcodeproj \
  -scheme MyApp \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -enableCodeCoverage YES \
  -resultBundlePath TestResults.xcresult
```

**Available Instruments:**

| Instrument | What It Monitors | Use Case |
|------------|------------------|----------|
| **Time Profiler** | CPU usage, hot code paths | Find slow code |
| **Allocations** | Memory allocations, heap | Track memory usage |
| **Leaks** | Memory leaks | Detect unreleased objects |
| **System Trace** | CPU, threads, system calls | Deep system analysis |
| **Network** | HTTP requests, bandwidth | API performance |

**Example: Profile heavy scrolling test**
```
1. Open Instruments → Allocations
2. Start recording
3. In simulator, run heavy scrolling test manually
4. Stop recording
5. Check:
   - All Allocations graph (should be flat)
   - Persistent bytes (should not grow)
   - Leaks (should be zero)
```

### 5. Command Line Test Results

**Best for:** CI/CD pipelines, automated reports

**Run tests with metrics:**

```bash
# Run all tests with result bundle
xcodebuild test \
  -project github_repo_search_iOS_app.xcodeproj \
  -scheme github_repo_search_iOS_app \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.6' \
  -resultBundlePath TestResults.xcresult \
  | tee test_output.log

# Parse results for metrics
xcrun xcresulttool get \
  --path TestResults.xcresult \
  --format json \
  > test_metrics.json

# Extract memory metrics
cat test_metrics.json | jq '.metrics.memory'

# Extract CPU metrics
cat test_metrics.json | jq '.metrics.cpu'
```

**Example output:**
```json
{
  "testName": "testHeavyScrolling60Seconds",
  "metrics": {
    "com.apple.XCTPerformanceMetric_MemoryPhysical": {
      "measurements": [142.3, 145.1, 139.8, 144.2, 141.5],
      "average": 142.58,
      "stdDev": 2.01,
      "maxRegression": 0.1,
      "unitOfMeasurement": "MB"
    }
  }
}
```

### 6. Memory Graph Debugger (Leak Detection)

**Best for:** Finding memory leaks during tests

**How to use:**

```
1. Run test (⌘U)
2. Pause during test execution
3. Click "Debug Memory Graph" button (◊) in Xcode toolbar
4. Look for:
   - Purple "!" icons (leaks)
   - Growing object counts
   - Retain cycles (circular references)
```

**Example workflow:**
```
1. Start heavy scrolling test
2. After 30 seconds, pause
3. Capture memory graph
4. Resume test
5. After 60 seconds, pause
6. Capture second memory graph
7. Compare: Object count should be similar
```

## Practical Monitoring Examples

### Example 1: Monitor Heavy Scrolling Test

**Goal:** Ensure memory doesn't leak during scrolling

**Method:**
```swift
func testHeavyScrolling60Seconds() throws {
    measure(metrics: [XCTMemoryMetric()]) {
        // 60 seconds of rapid scrolling
        let startTime = Date()
        while Date().timeIntervalSince(startTime) < 60 {
            table.swipeUp(velocity: .fast)
            table.swipeDown(velocity: .fast)
            usleep(50_000)
        }
    }
}
```

**Monitor in Xcode:**
1. Run test (⌘U)
2. Open Debug Navigator (⌘7)
3. Watch Memory graph:
   - Start: ~80 MB
   - During: ~120-140 MB (images loading)
   - End: Should return to ~80-100 MB
   - Red flag: Memory keeps growing

**Expected results:**
```
Memory Physical: 135.2 MB (baseline: 128.4 MB, δ +5.3%)
✓ PASS - Within acceptable range
```

### Example 2: Monitor Tab Switching

**Goal:** Ensure no race conditions or crashes

**Method:**
```swift
func testRapidTabSwitching30Seconds() throws {
    measure(metrics: [XCTMemoryMetric(), XCTCPUMetric()]) {
        let startTime = Date()
        while Date().timeIntervalSince(startTime) < 30 {
            usersTab.tap()
            reposTab.tap()
            favoritesTab.tap()
            settingsTab.tap()
        }
    }
}
```

**Monitor in Xcode:**
1. Watch Console for errors/warnings
2. Check Memory: Should be stable
3. Check CPU: May spike during switches, but should average < 40%

**Expected results:**
```
Memory: 92.1 MB (stable)
CPU Time: 3.2s over 30s (10.7% average)
✓ PASS - No crashes, stable memory
```

### Example 3: Monitor Concurrent Operations

**Goal:** Verify debouncing and request cancellation work

**Method:**
```swift
func testRapidSearchInputChanges() throws {
    measure(metrics: [XCTMemoryMetric(), XCTCPUMetric()]) {
        for i in 0..<50 {
            searchField.typeText("swift")
            usleep(200_000) // Faster than debounce
            searchField.clearText()
        }
    }
}
```

**Monitor in Xcode:**
1. Open Debug Navigator → Network
2. Should see: 1-2 actual API requests (debounced)
3. Red flag: 50 simultaneous requests

**Monitor in Console:**
```bash
# Filter logs for API calls
xcrun simctl spawn booted log stream \
  --predicate 'subsystem == "com.yourapp.network"' \
  --level debug

# Expected output:
[Network] 🌐 Searching for: swift
[Network] Request cancelled: swift
[Network] Request cancelled: swift
[Network] 🌐 Searching for: swift (final)
```

## Monitoring in CI/CD

### GitHub Actions Example

```yaml
name: Stress Tests with Metrics

on:
  schedule:
    - cron: '0 2 * * *' # Run nightly at 2 AM

jobs:
  stress-tests:
    runs-on: macos-14
    steps:
      - uses: actions/checkout@v4

      - name: Run Stress Tests
        run: |
          xcodebuild test \
            -project github_repo_search_iOS_app.xcodeproj \
            -scheme github_repo_search_iOS_app \
            -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.6' \
            -only-testing:github_repo_search_iOS_app_UITests/HeavyScrollingStressTests \
            -only-testing:github_repo_search_iOS_app_UITests/TabSwitchingStressTests \
            -only-testing:github_repo_search_iOS_app_UITests/ConcurrentOperationsStressTests \
            -resultBundlePath TestResults.xcresult \
            | tee test_output.log

      - name: Extract Metrics
        run: |
          xcrun xcresulttool get \
            --path TestResults.xcresult \
            --format json \
            > metrics.json

      - name: Check Memory Threshold
        run: |
          # Extract average memory usage
          MEMORY=$(cat metrics.json | jq '.metrics.memory.average')

          if (( $(echo "$MEMORY > 150" | bc -l) )); then
            echo "Memory usage too high: ${MEMORY} MB"
            exit 1
          else
            echo "✓ Memory usage OK: ${MEMORY} MB"
          fi

      - name: Upload Results
        uses: actions/upload-artifact@v4
        with:
          name: test-results
          path: |
            TestResults.xcresult
            metrics.json
            test_output.log
```

## Interpreting Metrics

### Memory Metrics

| Value | Status | Action |
|-------|--------|--------|
| < 100 MB | ✓ Excellent | None |
| 100-150 MB | ✓ Good | Monitor |
| 150-200 MB | Warning | Investigate |
| > 200 MB | Critical | Optimize immediately |

**Patterns to watch:**
- **Linear growth** = Memory leak
- **Saw-tooth pattern** = Healthy (allocate/deallocate)
- **Sudden spike** = One-time allocation (OK)
- **Plateaus stepping up** = Accumulating objects (bad)

### CPU Metrics

| Value | Status | Action |
|-------|--------|--------|
| < 20% average | ✓ Excellent | None |
| 20-40% average | ✓ Good | None |
| 40-60% average | Warning | Optimize hot paths |
| > 60% average | Critical | Major optimization needed |

**Spikes are OK, sustained high CPU is not.**

### Test Duration

| Test Type | Expected Duration | Action if Slower |
|-----------|-------------------|------------------|
| Unit test | < 1 second | Optimize or mock |
| Integration test | 1-5 seconds | Check network, I/O |
| UI test | 5-30 seconds | Normal |
| Stress test | 30-120 seconds | Normal |

## Best Practices

### 1. Set Baselines

```
1. Run test first time
2. Review results
3. Click "Set Baseline" in Xcode
4. Future runs compare against baseline
5. Re-baseline after intentional improvements
```

### 2. Monitor Multiple Runs

```swift
let options = XCTMeasureOptions()
options.iterationCount = 10 // Run 10 times

measure(options: options, metrics: [XCTMemoryMetric()]) {
    performTest()
}
```

**Why:** Reduces variance, detects flaky tests

### 3. Use Consistent Environment

```
- Same simulator/device
- Same iOS version
- Same build configuration (Release for performance)
- Quit other apps
- Consistent network conditions
```

### 4. Log Custom Metrics

```swift
func testHeavyScrolling() throws {
    var scrollCount = 0

    measure(metrics: [XCTMemoryMetric()]) {
        let startTime = Date()
        while Date().timeIntervalSince(startTime) < 60 {
            table.swipeUp()
            scrollCount += 1
        }
    }

    print("Total scrolls in 60s: \(scrollCount)")
    // Appears in test logs for analysis
}
```

### 5. Fail Tests on Threshold Breach

```swift
func testMemoryUsage() throws {
    var maxMemory: Double = 0

    measure(metrics: [XCTMemoryMetric()]) {
        performHeavyOperation()
        // maxMemory captured by metric
    }

    // Get actual memory from metrics (simplified)
    let memoryUsed = getMemoryFromMetrics() // Implementation needed

    XCTAssertLessThan(memoryUsed, 150.0,
                      "Memory usage (\(memoryUsed) MB) exceeded threshold (150 MB)")
}
```

## Troubleshooting

### Issue: Can't see metrics in test results

**Solution:**
```
1. Edit Scheme (⌘<)
2. Test tab
3. Options
4. ✓ Gather coverage for some targets
5. ✓ Enable performance test diagnostics
```

### Issue: High memory in tests but not in app

**Cause:** Test runner overhead

**Solution:**
- Focus on trends, not absolute values
- Compare tests to each other
- Use Memory Graph to find actual leaks

### Issue: Inconsistent results

**Causes:**
- Background processes
- Simulator state
- Network variability

**Solutions:**
- Run multiple iterations
- Use fresh simulator
- Mock network calls

## Tools Comparison

| Tool | Real-Time | Historical | Automated | CI/CD | Detail Level |
|------|-----------|------------|-----------|-------|--------------|
| **Debug Navigator** | ✓ | ✗ | ✗ | ✗ | Medium |
| **XCTest Metrics** | ✗ | ✓ | ✓ | ✓ | Low |
| **Instruments** | ✓ | ✓ | ✗ | ✗ | Very High |
| **Memory Graph** | ✓ | ✗ | ✗ | ✗ | Very High |
| **xcresulttool** | ✗ | ✓ | ✓ | ✓ | Medium |

**Recommendation:** Use all of them!
- Development: Debug Navigator + Instruments
- CI/CD: XCTest Metrics + xcresulttool
- Debugging: Memory Graph + Instruments

## Example: Complete Monitoring Workflow

```
1. Write stress test with measure() metrics
2. Run test (⌘U)
3. Monitor in Debug Navigator:
   - Watch Memory graph
   - Watch CPU usage
4. Check Console for errors/logs
5. Review results in Report Navigator:
   - Compare to baseline
   - Check for regressions
6. If issues found:
   - Re-run with Instruments
   - Capture Memory Graph
   - Analyze leak or hot path
7. Fix issue
8. Re-run test
9. Update baseline if intentional change
10. Commit to git
```

## Resources

- [XCTest Metrics Documentation](https://developer.apple.com/documentation/xctest/performance_tests)
- [Instruments User Guide](https://help.apple.com/instruments/mac/current/)
- [xcresulttool Reference](https://developer.apple.com/documentation/xcode/running-tests-and-interpreting-results)
- [Memory Graph Debugger](https://developer.apple.com/documentation/xcode/gathering-information-about-memory-use)

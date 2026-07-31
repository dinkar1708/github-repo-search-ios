# Code Coverage

## Overview
Code coverage measures the percentage of code executed during tests.

## Current Status

- Overall Coverage: 51.87%
- Target: 70%+

### File Coverage
- ApiClient.swift: 88.89%
- HomeView.swift: 87.63%
- AppSearchBar.swift: 100%
- SearchItem.swift: 100%

## What is Code Coverage?

Code coverage measures which lines of code run during tests. It helps identify untested code paths.

### Important: Coverage vs Testing

Coverage measures execution, not correctness.

Example:
```swift
func testProcessOrder() {
    let service = OrderService()
    _ = service.process(Order(itemID: "sku-42"))
    // No assertion - line runs but nothing verified
}
```

This gives 100% coverage but tests nothing.

## Coverage Goals

### By Component

**Critical Components:** 90-100%
- API client
- Network layer
- Data models
- Business logic

**Standard Components:** 70-90%
- ViewModels
- Repositories
- Services

**UI Components:** 50-70%
- Views (SwiftUI)
- Navigation
- UI helpers

**Overall Target:** 70%+

## Enabling Coverage

### In Xcode

1. Open scheme editor: Cmd + <
2. Select "Test" on left
3. Click "Options" tab
4. Check "Code Coverage"
5. Choose "All targets" or specific targets

### Command Line

```bash
xcodebuild test -scheme github_repo_search_iOS_app \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.6' \
  -enableCodeCoverage YES
```

## Viewing Coverage

### In Xcode

#### Coverage Tab
1. Run tests: Cmd + U
2. Open Report Navigator: Cmd + 9
3. Select latest test run
4. Click "Coverage" tab
5. View file percentages

#### Source Editor
1. After running tests with coverage
2. Open any source file
3. Coverage shown in gutter:
   - Green: Line executed
   - Red: Line not executed
   - No color: Not executable (comments, etc.)

#### Coverage Details
Click file in Coverage tab to see:
- Function-level coverage
- Execution counts
- Uncovered lines highlighted

### Using xccov

#### View Coverage Report

```bash
# Find latest test result
ls -lt ~/Library/Developer/Xcode/DerivedData/*/Logs/Test/*.xcresult | head -1

# View coverage
xcrun xccov view --report <path-to>.xcresult
```

#### Example Output
```
github_repo_search_iOS_app.app: 51.87% (1110/2140)
  ApiClient.swift: 88.89% (32/36)
  HomeView.swift: 87.63% (425/485)
  AppSearchBar.swift: 100.00% (42/42)
  SearchItem.swift: 100.00% (6/6)
  SplashView.swift: 95.89% (70/73)
```

#### Export JSON
```bash
# Export to JSON
xcrun xccov view --report --json <path-to>.xcresult > coverage.json
```

## Interpreting Results

### Coverage Percentage

- **Green (80-100%):** Well tested
- **Yellow (50-79%):** Moderate coverage
- **Red (0-49%):** Needs tests

### Execution Counts

In source editor:
- Number shows how many times line ran
- Higher number = more test coverage
- 0 = never executed

### Function Coverage

Coverage tab shows per-function coverage:
- Click file to expand functions
- See which functions need tests

## Improving Coverage

### Find Untested Code

1. Open Coverage tab
2. Sort by coverage % (ascending)
3. Focus on red/yellow files
4. Click file to see uncovered lines

### Write Tests for Uncovered Lines

```swift
// Before: Uncovered error handling
func search() async throws {
    do {
        let result = try await api.fetch()
        process(result)
    } catch {
        handleError(error)  // This line red (uncovered)
    }
}

// Add test to cover error path
func testSearchError() async throws {
    // Trigger error condition
    let mockAPI = MockAPIThatFails()

    do {
        try await search()
        XCTFail("Should throw")
    } catch {
        // Error path now covered
    }
}
```

### Cover Edge Cases

```swift
func testEmptyInput() {
    // Test with empty string
}

func testNilValues() {
    // Test with optional values
}

func testBoundaryConditions() {
    // Test min/max values
}
```

## Coverage Best Practices

### Quality Over Quantity

Don't chase 100% coverage:
- Focus on critical paths
- Test important behavior
- Skip trivial code

### Test Behavior, Not Lines

```swift
// Bad - just executes code
func testCalculation() {
    _ = calculator.add(2, 3)
}

// Good - verifies behavior
func testCalculation() {
    let result = calculator.add(2, 3)
    XCTAssertEqual(result, 5)
}
```

### Ignore Unreachable Code

Some code doesn't need coverage:
- Logging statements
- Debugging helpers
- Impossible error cases

### Regular Monitoring

Check coverage regularly:
- After adding features
- Before releases
- During code review

## CI/CD Integration

### Generate Coverage Reports

```bash
# Run tests with coverage
xcodebuild test \
  -scheme github_repo_search_iOS_app \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -enableCodeCoverage YES \
  -resultBundlePath TestResults.xcresult

# Export coverage
xcrun xccov view --report TestResults.xcresult > coverage.txt
```

### Fail Build on Low Coverage

```bash
# Extract coverage percentage
COVERAGE=$(xcrun xccov view --report TestResults.xcresult | \
  grep "github_repo_search_iOS_app.app" | \
  awk '{print $2}' | \
  sed 's/%//')

# Check threshold
if (( $(echo "$COVERAGE < 70" | bc -l) )); then
  echo "Coverage $COVERAGE% is below 70%"
  exit 1
fi
```

## Coverage Reports

### HTML Reports

Use third-party tools to generate HTML reports:

#### Slather
```bash
gem install slather
slather coverage --html
```

#### xcpretty
```bash
gem install xcpretty
xcodebuild test | xcpretty --report html
```

### Upload to Services

- Codecov
- Coveralls
- SonarQube

## Common Issues

### Coverage Not Showing

**Problem:** Tests run but no coverage data

**Solutions:**
1. Enable coverage in scheme
2. Clean build folder (Cmd + Shift + K)
3. Rebuild and rerun tests

### Wrong Coverage Values

**Problem:** Coverage percentage seems incorrect

**Solutions:**
1. Run all tests, not just some
2. Check target selection in scheme
3. Clean derived data

### Performance Impact

**Problem:** Tests run slowly with coverage enabled

**Solution:** Coverage adds overhead. Disable for dev, enable for CI.

## Limitations

### What Coverage Doesn't Tell You

Coverage cannot detect:
- Logic errors
- Missing assertions
- Wrong behavior
- Edge cases not tested
- Integration issues

### Example

```swift
// 100% coverage but wrong
func testDivision() {
    let result = divide(10, 2)
    // WRONG: Should be 5, but test missing assertion
}
```

All lines execute (100% coverage) but test verifies nothing.

## Best Practices Summary

1. Enable coverage for all test runs
2. Aim for 70%+ overall coverage
3. Focus on critical components (90%+)
4. Write meaningful assertions
5. Test edge cases and errors
6. Monitor trends over time
7. Don't chase 100% blindly
8. Quality > quantity
9. Review uncovered code
10. Integrate into CI/CD

## Tools Reference

### xccov Commands

```bash
# View help
xcrun xccov --help
man xccov

# View report
xcrun xccov view --report <xcresult>

# View as JSON
xcrun xccov view --report --json <xcresult>

# View specific file
xcrun xccov view --file <filepath> <xcresult>
```

### Xcode Shortcuts

- Cmd + < : Edit scheme
- Cmd + U : Run tests
- Cmd + 9 : Report Navigator
- Cmd + Shift + K : Clean build

## Resources

- [Apple Code Coverage Guide](https://developer.apple.com/documentation/xcode/determining-how-much-code-your-tests-cover)
- [XCTest Documentation](https://developer.apple.com/documentation/xctest)
- [xccov Manual](man xccov)

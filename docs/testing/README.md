# Testing Documentation

## Overview
Comprehensive testing strategy for GitHub Repository Search iOS app.

## Current Status

- Total Tests: 8 (all passing)
- Success Rate: 100%
- Code Coverage: 51.87%

## Test Categories

### Unit Tests
Tests for individual components in isolation.

**See:** [unit_tests.md](unit_tests.md)

- 4 unit tests
- API client testing
- Repository pattern testing
- Error handling

### UI Tests
Tests for user interface and interactions.

**See:** [ui_tests.md](ui_tests.md)

- 3 UI interaction tests
- Screen navigation
- User flows

### Integration Tests
Tests for multiple components working together.

**See:** [integration_tests.md](integration_tests.md)

- Status: Not yet implemented
- Recommended tests listed

### Performance Tests
Tests for app performance metrics.

**See:** [performance_tests.md](performance_tests.md)

- 1 launch performance test
- Baseline measurements
- Profiling with Xcode Instruments

### Stress Tests
Tests for app behavior under extreme conditions.

**See:**
- [stress_testing.md](stress_testing.md) - Comprehensive stress testing guide
- [stress_tests_setup.md](stress_tests_setup.md) - Quick setup and running instructions

**Tests:**
- Heavy scrolling (60s continuous)
- Rapid search operations
- Extreme scrolling (100+ swipes)
- Memory and CPU monitoring

## Quick Start

### Run All Tests
```bash
# In Xcode
Cmd + U

# Command line
xcodebuild test -scheme github_repo_search_iOS_app \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.6'
```

### View Coverage
1. Edit Scheme (Cmd + <)
2. Test → Options → Enable "Code Coverage"
3. Run tests (Cmd + U)
4. Report Navigator (Cmd + 9) → Coverage tab

## Documentation Structure

```
docs/testing/
├── README.md                    # This file - testing overview
├── unit_tests.md               # Unit test documentation
├── ui_tests.md                 # UI test documentation
├── integration_tests.md        # Integration test documentation
├── performance_tests.md        # Performance test documentation
├── stress_testing.md           # Stress testing guide (comprehensive)
├── stress_tests_setup.md       # Quick setup and running stress tests
├── monitoring_test_metrics.md  # How to monitor tests (memory, CPU, metrics)
└── code_coverage.md            # Coverage guide and best practices
```

## Coverage Goals

- API and networking: 90-100%
- Business logic (ViewModels): 80-90%
- Overall target: 70%+

Current: 51.87% (improving)

## Test Locations

```
Tests/
├── github_repo_search_iOS_appTests/
│   ├── GitRepository_appTests.swift       # Unit tests
│   └── github_repo_search_iOS_appTests.swift
└── github_repo_search_iOS_appUITests/
    ├── HomeView_appUITests.swift          # UI tests
    └── github_repo_search_iOS_appUITests.swift
```

## Next Steps

1. Read the testing overview for general testing practices
2. Review specific test type documentation
3. Check [code_coverage.md](code_coverage.md) for coverage best practices
4. Write new tests following the patterns

## Resources

- [Apple XCTest Documentation](https://developer.apple.com/documentation/xctest)
- [Code Coverage Guide](https://developer.apple.com/documentation/xcode/determining-how-much-code-your-tests-cover)
- [Testing Your Apps in Xcode](https://developer.apple.com/documentation/xcode/testing-your-apps-in-xcode)

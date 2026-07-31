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

**See:** [UNIT_TESTS.md](UNIT_TESTS.md)

- 4 unit tests
- API client testing
- Repository pattern testing
- Error handling

### UI Tests
Tests for user interface and interactions.

**See:** [UI_TESTS.md](UI_TESTS.md)

- 3 UI interaction tests
- Screen navigation
- User flows

### Integration Tests
Tests for multiple components working together.

**See:** [INTEGRATION_TESTS.md](INTEGRATION_TESTS.md)

- Status: Not yet implemented
- Recommended tests listed

### Performance Tests
Tests for app performance metrics.

**See:** [PERFORMANCE_TESTS.md](PERFORMANCE_TESTS.md)

- 1 launch performance test
- Baseline measurements

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
├── README.md                  # This file - testing overview
├── UNIT_TESTS.md             # Unit test documentation
├── UI_TESTS.md               # UI test documentation
├── INTEGRATION_TESTS.md      # Integration test documentation
├── PERFORMANCE_TESTS.md      # Performance test documentation
├── CODE_COVERAGE.md          # Coverage guide and best practices
└── TESTING_GUIDE.md          # General testing guide
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

1. Read [TESTING_GUIDE.md](TESTING_GUIDE.md) for general testing practices
2. Review specific test type documentation
3. Check [CODE_COVERAGE.md](CODE_COVERAGE.md) for coverage best practices
4. Write new tests following the patterns

## Resources

- [Apple XCTest Documentation](https://developer.apple.com/documentation/xctest)
- [Code Coverage Guide](https://developer.apple.com/documentation/xcode/determining-how-much-code-your-tests-cover)
- [Testing Your Apps in Xcode](https://developer.apple.com/documentation/xcode/testing-your-apps-in-xcode)

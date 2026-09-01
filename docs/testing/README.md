# Testing Documentation

## Overview
Comprehensive testing strategy for GitHub Repository Search iOS app.

## Current Status

- Total Tests: 8 (all passing)
- Success Rate: 100%
- Code Coverage: 51.87%

## Dual-Framework Testing Architecture

We maintain a **dual-framework test suite** demonstrating enterprise migration competency:

```text
github_repo_search_iOS_app_UnitTests/
├── 🍏 Modern_SwiftTesting/              - Apple's Swift Testing Framework (iOS 17.0+ / Swift 6)
│   ├── SwiftDataOfflineTests.swift      - SwiftData 4-Table Persistence, @ModelActor, BGTaskScheduler
│   └── OfflineSyncMatrixTests.swift     - Parameterized filter matrices, relational cascading, bookmarks
│
└── 🏛️ Classic_XCTest/                  - Production-Grade XCTest Framework (Industry Standard)
    ├── HomeViewModelTests.swift         - Home search, debounce, pagination, and state flow
    ├── UserProfileViewModelTests.swift  - Profile fetching, fork filtering, repository listing
    ├── ApiClientTests.swift             - URLSession request building, URL encoding, HTTP methods
    ├── GithubRepositoryTests.swift      - Network repository boundary & error decoding
    └── FavoritesManagerTests.swift      - Keychain-backed favorites, duplicate prevention, analytics
```

## Test Categories

### 1. Unit Tests (Modern Swift Testing + Classic XCTest)
- **Modern Swift Testing (`import Testing`):** Persisted relational models, SwiftData `@ModelActor`, background ingestion, parameterized sync matrices (`@Test(arguments: ...)`).
- **Classic XCTest (`import XCTest`):** Production ViewModels, ApiClient, repository mapping, and Keychain favorites.
- **See:** [unit_tests.md](unit_tests.md) and [`github_repo_search_iOS_app_UnitTests/README.md`](../../github_repo_search_iOS_app_UnitTests/README.md)

### 2. UI Tests (XCUITest)
Tests for user interface and interactions (`XCUIApplication`).
**See:** [ui_tests.md](ui_tests.md)

### 3. Performance & Stress Tests (XCTest Metrics)
Tests for app performance metrics (`measure(metrics: ...)`).
**See:** [performance_tests.md](performance_tests.md) and [stress_testing.md](stress_testing.md)

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
│   ├── Modern_SwiftTesting/           # Swift Testing suite
│   └── Classic_XCTest/                # XCTest suite
└── github_repo_search_iOS_appUITests/
    ├── HomeView_appUITests.swift          # UI tests
    └── github_repo_search_iOS_appUITests.swift
```

## Next Steps

1. Read the testing overview for general testing practices
2. Review specific test type documentation
3. Check [code_coverage.md](code_coverage.md) for coverage best practices
4. Write new tests following the patterns

## Resources & Official Apple Documentation

### 🍏 Modern Swift Testing
- **[Swift Testing Framework Overview](https://developer.apple.com/documentation/testing)** — Official Apple developer documentation for `@Suite`, `@Test`, `#expect`, and tags.
- **[Migrating a Test from XCTest to Swift Testing](https://developer.apple.com/documentation/testing/migratingfromxctest)** — Apple's official step-by-step guide for migrating to Swift Testing.
- **[Parameterized Testing with Argument Matrices](https://developer.apple.com/documentation/testing/parameterizedtesting)** — Running datasets concurrently via `@Test(arguments: [...])`.
- **[WWDC 2024: Meet Swift Testing (Session 10179)](https://developer.apple.com/videos/play/wwdc2024/10179/)** — WWDC introductory session.
- **[WWDC 2024: Go Further with Swift Testing (Session 10195)](https://developer.apple.com/videos/play/wwdc2024/10195/)** — WWDC advanced session on parallel execution.
- **[Swift Testing Open Source Repository](https://github.com/swiftlang/swift-testing)** — Official open-source codebase.

### 🏛️ Classic XCTest & UI Automation
- **[Apple XCTest Documentation](https://developer.apple.com/documentation/xctest)** — Documentation for XCTest, XCUIApplication, and UI Automation.
- **[Testing Your Apps in Xcode](https://developer.apple.com/documentation/xcode/testing-your-apps-in-xcode)** — Xcode testing workflows.
- **[Code Coverage Guide](https://developer.apple.com/documentation/xcode/determining-how-much-code-your-tests-cover)** — Measuring test coverage in Xcode.

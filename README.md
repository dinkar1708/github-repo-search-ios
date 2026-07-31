# GitHub Repository Search iOS App

Modern iOS app for searching GitHub repositories and users. Built with SwiftUI, MVVM architecture, and production-ready infrastructure.

## Quick Info

- **Platform**: iOS 17.0+
- **Language**: Swift 5.9+
- **UI**: SwiftUI with @Observable
- **Architecture**: MVVM + Repository pattern
- **Build Status**: BUILD SUCCEEDED
- **No External Dependencies**: 100% native iOS

## Key Features
- Repository and User Search with debouncing
- User profiles with repository listings
- Secure favorites (Keychain encryption)
- Tab navigation (Users, Repositories, Favorites, Settings)
- Dark mode support
- Multi-language (English, Japanese)
- Offline capability with caching

## Documentation

Comprehensive documentation organized by category. [View all documentation](docs/README.md)

### Getting Started
- [Quick Start Guide](docs/getting-started/QUICKSTART.md) - Setup and run in 5 minutes
- [Setup Guide](docs/SETUP.md) - Development environment configuration

### Technical Documentation
- [Architecture Patterns](docs/technical/ARCHITECTURE_PATTERNS.md) - MVVM, DI, Repository pattern
- [Dependency Injection](docs/technical/DEPENDENCY_INJECTION.md) - Property wrapper-based DI
- [Keychain Storage](docs/technical/KEYCHAIN_STORAGE.md) - AES-256 secure storage
- [Logging System](docs/technical/LOGGING.md) - OSLog with type-safe categories
- [Caching Strategy](docs/technical/CACHING.md) - NSCache with TTL
- [Analytics](docs/technical/ANALYTICS.md) - Event tracking system
- [Error Handling](docs/technical/ERROR_HANDLING.md) - Typed NetworkError
- [Code Style](docs/technical/CODE_STYLE.md) - SwiftLint configuration

### Testing Documentation
- [Testing Overview](docs/testing/README.md) - Testing strategy (8 tests, 51.87% coverage)
- [Unit Tests](docs/testing/UNIT_TESTS.md) - Component testing guide
- [UI Tests](docs/testing/UI_TESTS.md) - XCUITest guide
- [Integration Tests](docs/testing/INTEGRATION_TESTS.md) - Multi-component testing
- [Performance Tests](docs/testing/PERFORMANCE_TESTS.md) - Metrics and benchmarks
- [Code Coverage](docs/testing/CODE_COVERAGE.md) - Coverage best practices

### Product Documentation
- [Features](docs/FEATURES.md) - Complete feature list
- [User Flows](docs/product/USER_FLOWS.md) - User interaction patterns
- [UI/UX Design](docs/product/UI_UX_DESIGN.md) - Apple HIG compliance
- [API Integration](docs/product/API_INTEGRATION.md) - GitHub REST API v3

### References
- [Best Practices](docs/references.md) - iOS development resources
- [All Documentation Index](docs/README.md) - Complete documentation hub

### Cross-Platform Specifications
This iOS app follows master specifications from the Android version:
- [Master Feature Spec](https://github.com/dinkar1708/GithubCruiseAndroid/blob/main/docs/master/MASTER_FEATURE_SPECIFICATION.md)
- [GitHub API Spec](https://github.com/dinkar1708/GithubCruiseAndroid/blob/main/docs/master/GITHUB_API_SPECIFICATION.md)
- [Master Best Practices](https://github.com/dinkar1708/GithubCruiseAndroid/blob/main/docs/master/MASTER_BEST_PRACTICES.md)

## Features

### Core Features
- **Repository Search** - Incremental search with real-time results and 3-second debouncing
- **User Search** - Search GitHub users with 800ms debouncing and auto-complete
- **User Profiles** - View detailed user profiles with bio, stats, and repository list
- **Favorites** - Save favorite users AND repositories with UserDefaults persistence
- **Tab Navigation** - 4 tabs: Users, Repositories, Favorites, Settings
- **Settings** - Dark mode toggle, language selection, cache management

### Technical Features
- No external libraries - 100% native iOS implementation
- API request throttling for optimal performance
- Modern iOS design with cards, gradients, and smooth animations
- Rich repository cards with avatars, stats, and descriptions
- Comprehensive detail view with full repository information
- Dark mode support with adaptive colors
- Multi-language support (English, Japanese)
- Universal app - supports iPhone and iPad

## Screenshots

### Light Mode

<div align="center">
  <img src="docs/images/01-repositories-search.png" alt="Repository Search" width="250"/>
  <img src="docs/images/02-repositories-results.png" alt="Repository Results" width="250"/>
  <img src="docs/images/03-users-search.png" alt="User Search" width="250"/>
</div>

<div align="center">
  <img src="docs/images/04-user-profile.png" alt="User Profile" width="250"/>
  <img src="docs/images/05-repository-details.png" alt="Repository Details" width="250"/>
  <img src="docs/images/06-favorites-users.png" alt="Favorites - Users" width="250"/>
</div>

<div align="center">
  <img src="docs/images/07-favorites-repositories.png" alt="Favorites - Repositories" width="250"/>
  <img src="docs/images/08-settings.png" alt="Settings" width="250"/>
</div>

### Dark Mode

<div align="center">
  <img src="docs/images/09-users-dark-mode.png" alt="Users - Dark Mode" width="250"/>
  <img src="docs/images/10-repositories-dark-mode.png" alt="Repositories - Dark Mode" width="250"/>
</div>


## Project Folder Structure

The project follows a modular architecture with clear separation between data, features, and utilities:

<div align="center">
  <img src="docs/images/project-structure.png" alt="Xcode Project Structure" width="600"/>
</div>

**Main Components:**
- **Modules/** - Core application modules (Data, Feature, Util)
- **AppConfig/** - App configuration and navigation
- **Resource/** - Assets, colors, localization files
- **Tests/** - Unit tests, UI tests, Integration tests, Performance tests


## App Structure

The app consists of 4 main tabs:

**Tab 1: Users**
- Search GitHub users by username
- View user cards with avatar and stats
- Tap to view detailed profile
- 800ms debounce for smooth searching

**Tab 2: Repositories**
- Search GitHub repositories
- Real-time search with 3-second debouncing
- Rich repository cards with stats
- Infinite scroll pagination

**Tab 3: Favorites**
- View saved favorite users AND repositories
- Segmented control to switch between Users and Repositories
- Swipe to delete
- Persists across app restarts using UserDefaults
- One-tap favorite from repository search
- One-tap favorite from user profile

**Tab 4: Settings**
- Toggle dark mode
- Change language (English/Japanese)
- Clear cache
- App information

# Testing

## Test Summary

**Comprehensive test suite with multiple test types**

| Test Type     | Framework          | Test Files | What It Verifies                    |
|---------------|--------------------|------------|-------------------------------------|
| Unit          | XCTest             | 4 files    | Components in isolation             |
| Integration   | XCTest             | 2 files    | Multiple components together        |
| UI            | XCTest (XCUI)      | 1 file     | Real user flows on screen           |
| Performance   | XCTest (Metrics)   | 2 files    | Speed and memory benchmarks         |

**Test Targets:**
- `github_repo_search_iOS_app_UnitTests` - Unit tests (ApiClient, ViewModels, Repository)
- `github_repo_search_iOS_app_IntegrationTests` - Integration tests (User flows, Search flows)
- `github_repo_search_iOS_app_UITests` - UI tests (HomeView interactions)
- `github_repo_search_iOS_app_PerformanceTests` - Performance tests (Launch, API performance)

**Code Coverage: 51.87%** (Target: 70%+)
- ApiClient: 88.89%
- HomeView: 87.63%
- AppSearchBar: 100%
- SearchItem: 100%

## Quick Start
From Xcode, click **Product → Test** (or press `⌘U`) - it will run all test cases written inside:
- **github_repo_search_iOS_appTests** - Unit tests for business logic and API calls
- **github_repo_search_iOS_appUITests** - UI tests for user interaction flows

## 📖 Complete Testing Documentation

**[docs/TESTING.md](docs/TESTING.md)** - Complete testing guide including:
- All test cases with detailed explanations
- Code coverage measurement and setup
- How to run tests (Xcode, command line, CI/CD)
- Test results interpretation
- Best practices and troubleshooting

## Code Coverage

**Quick Setup:**
1. Edit Scheme (`⌘<`) → Test → Options → Enable "Code Coverage"
2. Run tests (`⌘U`)
3. View results: Report Navigator (`⌘9`) → Coverage tab

**Coverage Goals:**
- Critical paths (API, business logic): 90-100%
- View models: 70-90%
- Overall target: 70%+

**View Coverage:**
- Green = well tested (>80%)
- Yellow = moderate (40-80%)
- Red = needs tests (<40%)

For detailed coverage documentation, command line usage, and best practices, see **[docs/TESTING.md](docs/TESTING.md)**

## Requirements

- **Xcode 15.0 or later** (latest version recommended)
- **iOS 17.0 or later** (minimum deployment target)
- **Swift 5.9 or later** (includes modern concurrency and Observation framework)

### How to run
- Clone this repo
- Open project in xcode
- Select team signing and capability

## CI/CD Workflows

> ⚠️ **Note**: GitHub Actions workflows are configured but not yet tested in production. The workflows may require adjustments based on your specific Apple Developer account setup and signing configuration. Please test and adjust as needed before relying on automated deployments.

**Available Workflows:**
- `build-and-test.yml` - Build and test on `release/*` branches
- `deploy-testflight.yml` - Deploy to TestFlight
- `deploy-appstore.yml` - Deploy to App Store (requires `[release]` in commit message)
- `deploy-shared.yml` - Reusable deployment workflow

See [docs/SETUP.md](docs/SETUP.md) for GitHub Actions secrets configuration.

## Technology Stack

**Language:** Swift 5.9+ with modern concurrency

**UI:** SwiftUI with @main App lifecycle, AsyncImage, LazyVGrid, SF Symbols

**Architecture:** MVVM + Repository pattern

**Networking:** URLSession with async/await, type-safe ApiClient

**State:** @Observable macro (iOS 17+), @State, automatic change tracking

**Features:** Task-based debouncing, @MainActor, dark mode, accessibility, multi-language (EN/JP)

## Project Structure

```
Modules/
├── Data/
│   ├── Remote/
│   │   ├── Model/           # SearchUser, UserProfile, UserRepository, SearchItem
│   │   ├── Request/         # API request definitions
│   │   └── Repository/      # GithubRepository
│   └── Network/             # ApiClient
├── Feature/
│   └── UI/
│       ├── UserSearch/      # User search tab
│       ├── UserProfile/     # User profile detail
│       ├── Home/            # Repository search tab
│       ├── Favorites/       # Favorites tab with FavoritesManager
│       └── Settings/        # Settings tab
└── Util/                    # Shared utilities

AppConfig/
└── MainTabView.swift        # Tab navigation
```

## Platform Support

**Languages:** English, Japanese
**Themes:** Light, Dark (adaptive)
**Devices:** iPhone, iPad (universal)
**Orientations:** Portrait, Landscape


## API Endpoints Used

The app uses the following GitHub APIs:

1. Search Repositories: `GET /search/repositories`
2. Search Users: `GET /search/users`
3. User Profile: `GET /users/{username}`
4. User Repositories: `GET /users/{username}/repos`

All API calls use async/await with proper error handling.

## Key Highlights

**Modern iOS 17+ Features:**
- async/await throughout (no third-party frameworks)
- @Observable macro for reactive state
- Task-based debouncing and concurrency
- @MainActor for thread-safe UI updates
- SwiftUI @main App lifecycle

**Architecture:**
- MVVM design pattern
- Repository pattern for data abstraction
- Type-safe networking with URLSession
- Structured error handling
- Clean separation of concerns

## Recent Updates (July 2026)

**Latest:**
- ✓ Repository favorites with in-app navigation (repositories open in details screen, not browser)
- ✓ User favorites with profile navigation
- ✓ Segmented control in Favorites tab (Users/Repositories)
- ✓ Favorite button on repository details screen (not list cards)
- ✓ Favorite button on user profile screen
- ✓ Compact UI improvements (inline navigation, removed duplicate chevrons)
- ✓ 10 app screenshots (8 light mode, 2 dark mode)
- ✓ Documentation simplified (FEATURES.md, TESTING.md)
- ✓ Cross-references to Android master documentation

**Earlier:**
- User search with 800ms debouncing
- Repository search with 3-second debouncing
- Settings screen with dark mode and language selection
- 4-tab navigation (Users, Repositories, Favorites, Settings)
- Debounce fix for smooth searching without cancellation errors
- Legacy favorites migration support

## TODO List

**Completed:**
- [x] Add repository favorites functionality
- [x] Add segmented control for Users/Repositories in Favorites tab
- [x] Move favorite button from list to details screen
- [x] Fix favorites navigation to open in-app
- [x] UI improvements: compact navigation, remove duplicate chevrons
- [x] Add app screenshots to documentation
- [x] Simplify documentation structure
- [x] Add CI/CD pipeline (GitHub Actions + Fastlane)
- [x] Implement comprehensive logging system (OSLog)
- [x] Add pull-to-refresh on all tabs
- [x] Add unit tests for new ViewModels
- [x] Fix pagination bugs and performance issues
- [x] Migrate to NavigationStack (iOS 16+)

**Pending:**
- [ ] Add unit tests for FavoritesManager (repository favorites)
- [ ] Add UI tests for new features (User Search, Favorites with repositories)
- [ ] Implement search history
- [ ] Replace placeholder app icon with custom design
- [ ] Add animation transitions between screens
- [ ] Migrate to Swift Testing framework (WWDC 2024)
- [ ] Add deep linking support

# Meta
- Dinakar Maurya
- dinkar1708@gmail.com

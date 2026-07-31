# Architecture Documentation

## Overview

This iOS app follows **MVVM (Model-View-ViewModel)** architecture with a clean separation of concerns and modern Swift patterns.

## Architecture Layers

### 1. Presentation Layer (View)
- **Technology**: SwiftUI with iOS 17+ features
- **Pattern**: Declarative UI with `@Observable` macro
- **Navigation**: NavigationStack (iOS 16+)
- **Responsibility**: Display data and delegate user actions to ViewModels

**Example**:
```swift
struct HomeView: View {
    @State private var homeViewModel = HomeViewModel()

    var body: some View {
        NavigationStack {
            // UI implementation
        }
    }
}
```

### 2. ViewModel Layer
- **Technology**: `@Observable` macro with `@MainActor`
- **Pattern**: Modern Observation framework (iOS 17+)
- **Responsibility**: Business logic, state management, data transformation
- **Concurrency**: Swift async/await

**Example**:
```swift
@Observable
@MainActor
final class HomeViewModel {
    private let repository: GithubRepository
    var searchItems = [SearchItem]()
    var isLoading = false

    func searchRepositories() async {
        // Business logic
    }
}
```

### 3. Data Layer (Repository Pattern)
- **Pattern**: Protocol-based repository abstraction
- **Implementation**: DefaultGithubRepository
- **Responsibility**: Data access, API communication, data mapping

**Example**:
```swift
protocol GithubRepository: Sendable {
    func getSearchResultInRepoName(...) async throws -> SearchItemResponse
}

final class DefaultGithubRepository: GithubRepository {
    private let apiClient = ApiClient()
    // Implementation
}
```

### 4. Model Layer
- **Pattern**: Pure data structures
- **Protocols**: Codable, Sendable, Identifiable
- **Responsibility**: Data representation only (no business logic)

**Example**:
```swift
struct SearchItem: Decodable, Hashable, Identifiable, Sendable {
    let id: Int
    let name: String
    let owner: Owner
    // Data properties only
}
```

## Key Design Patterns

### Dependency Injection
- **Type**: Constructor-based with default parameters
- **Benefits**: Testable, flexible, maintains defaults for production

```swift
class HomeViewModel {
    private let repository: GithubRepository

    init(repository: GithubRepository = DefaultGithubRepository()) {
        self.repository = repository
    }
}
```

### Repository Pattern
- **Purpose**: Abstract data sources
- **Benefits**: Separation of concerns, easy mocking for tests
- **Implementation**: Protocol + Default implementation

### Async/Await Concurrency
- **Pattern**: Modern Swift concurrency
- **Benefits**: Readable async code, built-in cancellation
- **Usage**: All network calls, data loading

### State Management
- **Pattern**: Enum-based state
- **Benefits**: Exhaustive switch, clear states

```swift
enum MessageState {
    case loading
    case loaded
    case error(String)
    case emptySearchResult
}
```

## Project Structure

```
github_repo_search_iOS_app/
├── Modules/
│   ├── Feature/
│   │   ├── UI/
│   │   │   ├── Home/          # Repository search
│   │   │   ├── UserSearch/    # User search
│   │   │   ├── UserProfile/   # User details
│   │   │   ├── Favorites/     # Saved items
│   │   │   └── Settings/      # App settings
│   │   └── Util/
│   │       ├── CommonView/    # Reusable components
│   │       └── Extension/     # Swift extensions
│   ├── Domain/
│   │   └── Model/             # Domain models
│   └── Data/
│       ├── Remote/
│       │   └── API/           # API client, requests
│       └── Local/             # Local data (UserDefaults)
└── AppConfig/
```

## Modern iOS Practices

### iOS 17+ Features
- ✅ `@Observable` macro (replaces ObservableObject)
- ✅ `@MainActor` for UI updates
- ✅ NavigationStack (iOS 16+)
- ✅ Sendable protocol for thread safety

### Code Quality
- ✅ SwiftLint integration
- ✅ OSLog structured logging
- ✅ No force unwrapping
- ✅ Privacy Manifest (App Store requirement)

### Testing
- ✅ Unit tests for ViewModels
- ✅ Integration tests for flows
- ✅ Mock repositories for testing
- ✅ CI/CD with GitHub Actions

## Thread Safety

All models implement `Sendable`:
```swift
struct SearchItem: Decodable, Sendable { }
```

ViewModels use `@MainActor`:
```swift
@MainActor
class HomeViewModel { }
```

Repository is marked `Sendable`:
```swift
protocol GithubRepository: Sendable { }
```

## Data Flow

```
User Action → View → ViewModel → Repository → API Client → Network
                ↑                    ↓
                └── State Update ←───┘
```

1. User interacts with View
2. View delegates to ViewModel
3. ViewModel calls Repository
4. Repository uses ApiClient for network
5. Response flows back through layers
6. ViewModel updates state
7. View automatically re-renders (Observation)

## Error Handling

```swift
enum ApiResponseError: Error, Sendable {
    case invalidResponse(statusCode: Int, message: String)
    case decodingError(String)
    case networkError(String)
    case apiError(errors: [ApiError]?, message: String, documentationUrl: String)
}
```

## Performance Optimizations

### Pagination
- Threshold-based triggering (5 items from end)
- Separate loading states for initial vs. more
- Debounced search (800ms)

### Code Reusability
- AvatarImageView component
- Color.languageColor() extension
- Centralized constants

### Caching
- URLCache for network responses
- UserDefaults for favorites
- Automatic memory management

## Security

### Privacy Manifest
- `PrivacyInfo.xcprivacy` declares API usage
- Compliant with App Store requirements (2024+)

### Secure Coding
- No hardcoded secrets
- Proper error handling
- Input validation

## Future Considerations

### Recommended Improvements
1. **Swift Testing** - Migrate from XCTest (WWDC 2024)
2. **SwiftData** - For local persistence (iOS 17+)
3. **Coordinator Pattern** - For complex navigation
4. **Deep Linking** - URL scheme support

### Scalability
- Repository pattern allows easy backend switching
- Protocol-oriented design enables feature modularity
- MVVM scales well for large teams

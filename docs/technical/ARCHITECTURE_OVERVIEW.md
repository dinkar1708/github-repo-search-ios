# Architecture Overview

## High-Level Architecture

The app follows a clean, layered architecture with clear separation of concerns.

### Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                         UI Layer                            │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │  SwiftUI     │  │  SwiftUI     │  │  SwiftUI     │      │
│  │  Views       │  │  Views       │  │  Views       │      │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘      │
│         │                 │                 │               │
│  ┌──────▼───────┐  ┌──────▼───────┐  ┌──────▼───────┐      │
│  │ ViewModel    │  │ ViewModel    │  │ ViewModel    │      │
│  │ (@Observable)│  │ (@Observable)│  │ (@Observable)│      │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘      │
└─────────┼──────────────────┼──────────────────┼─────────────┘
          │                  │                  │
          └──────────────────┼──────────────────┘
                             │
┌─────────────────────────────▼─────────────────────────────┐
│                    Business Logic Layer                    │
│  ┌─────────────────────────────────────────────────────┐  │
│  │         Dependency Injection Container               │  │
│  │  @Injected property wrapper for dependencies        │  │
│  └─────────────────────────────────────────────────────┘  │
└────────────────────────────────────────────────────────────┘
          │                  │                  │
┌─────────▼──────────────────▼──────────────────▼──────────┐
│                      Data Layer                           │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐    │
│  │ Repository   │  │ Repository   │  │  Manager     │    │
│  │ (Protocol)   │  │ (Protocol)   │  │  (Shared)    │    │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘    │
│         │                 │                 │             │
│  ┌──────▼───────┐  ┌──────▼───────┐  ┌──────▼───────┐    │
│  │Implementation│  │Implementation│  │Implementation│    │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘    │
└─────────┼──────────────────┼──────────────────┼───────────┘
          │                  │                  │
┌─────────▼──────────────────▼──────────────────▼──────────┐
│                    Infrastructure Layer                   │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐    │
│  │  ApiClient   │  │KeychainMgr   │  │ CacheService │    │
│  │ (URLSession) │  │ (Security)   │  │  (NSCache)   │    │
│  └──────┬───────┘  └──────────────┘  └──────────────┘    │
└─────────┼────────────────────────────────────────────────┘
          │
┌─────────▼──────────────────────────────────────────────────┐
│                     External Services                       │
│              GitHub REST API v3 (api.github.com)           │
└────────────────────────────────────────────────────────────┘
```

### Data Flow

```
User Action → View → ViewModel → Repository → ApiClient → API
                                                    ↓
User ← View ← ViewModel ← Repository ← ApiClient ← Response
```

## Layer Details

### 1. UI Layer

**Components:**
- SwiftUI Views
- ViewModels (@Observable)
- Navigation

**Responsibilities:**
- Display data to user
- Handle user input
- Navigation between screens
- UI state management

**Example:**
```
HomeView (SwiftUI)
    ↓
HomeViewModel (@Observable)
    ↓ @Injected(\.githubRepository)
GithubRepository (Protocol)
```

**Key Files:**
- `Modules/Feature/UI/Home/View/HomeView.swift`
- `Modules/Feature/UI/Home/ViewModel/HomeViewModel.swift`
- `Modules/Feature/UI/UserSearch/View/UserSearchView.swift`
- `Modules/Feature/UI/UserProfile/View/UserProfileView.swift`

### 2. Business Logic Layer

**Components:**
- Dependency Injection Container
- @Injected property wrapper
- Business rules

**Responsibilities:**
- Dependency management
- Business logic coordination
- Cross-cutting concerns

**Dependency Injection:**
```swift
// Container holds all dependencies
@MainActor
final class DependencyContainer {
    static var shared = DependencyContainer()

    let githubRepository: GithubRepository
    let favoritesRepository: FavoritesRepository
    let cacheService: CacheService
    let analyticsService: AnalyticsService
}

// Inject into ViewModel
@Observable
final class HomeViewModel {
    @ObservationIgnored @Injected(\.githubRepository) private var repository
}
```

**Key Files:**
- `Modules/Core/DI/DependencyContainer.swift`

### 3. Data Layer

**Components:**
- Repository protocols
- Repository implementations
- Data models
- Managers

**Responsibilities:**
- Abstract data sources
- Data transformation
- Error handling
- Caching coordination

**Repositories:**
- `GithubRepository` - GitHub API operations
- `FavoritesRepository` - Favorites persistence
- `FavoritesManager` - Favorites coordination

**Models:**
- `SearchItem` - Repository search result
- `UserProfile` - User profile data
- `SearchUser` - User search result
- `FavoriteUser` - Favorite user storage
- `FavoriteRepository` - Favorite repository storage

**Key Files:**
- `Modules/Data/Remote/Repository/GithubRepository.swift`
- `Modules/Data/Repository/FavoritesRepository.swift`
- `Modules/Feature/UI/Favorites/Manager/FavoritesManager.swift`
- `Modules/Data/Remote/Model/*.swift`

### 4. Infrastructure Layer

**Components:**
- ApiClient
- KeychainManager
- CacheService
- AnalyticsService
- Logger

**Responsibilities:**
- HTTP networking
- Secure storage
- Caching
- Event tracking
- Logging

**Key Services:**

**ApiClient:**
- Makes HTTP requests
- Handles responses
- Error mapping
- URL construction

**KeychainManager:**
- AES-256 encryption
- Secure storage
- Migration from UserDefaults

**CacheService:**
- In-memory caching (NSCache)
- TTL support
- Cache invalidation

**AnalyticsService:**
- Event tracking
- User behavior analysis

**Logger:**
- Structured logging
- Category-based (OSLog)

**Key Files:**
- `Modules/Data/Network/ApiClient.swift`
- `Modules/Core/Storage/KeychainManager.swift`
- `Modules/Core/Cache/CacheService.swift`
- `Modules/Core/Analytics/AnalyticsService.swift`
- `Modules/Core/Logging/Logger.swift`

## Design Patterns

### MVVM (Model-View-ViewModel)

**View:**
- SwiftUI views
- Declarative UI
- Observes ViewModel

**ViewModel:**
- @Observable macro
- Business logic
- State management
- No UIKit dependencies

**Model:**
- Data structures
- Codable for JSON
- Sendable for concurrency

### Repository Pattern

**Benefits:**
- Abstracts data sources
- Testable (mock implementations)
- Single source of truth
- Swappable implementations

**Example:**
```swift
protocol GithubRepository: Sendable {
    func searchRepositories(query: String, page: Int) async throws -> SearchItemResponse
}

final class DefaultGithubRepository: GithubRepository {
    func searchRepositories(query: String, page: Int) async throws -> SearchItemResponse {
        // Implementation using ApiClient
    }
}

final class MockGithubRepository: GithubRepository {
    func searchRepositories(query: String, page: Int) async throws -> SearchItemResponse {
        // Mock implementation for tests
    }
}
```

### Dependency Injection

**Property Wrapper Pattern:**
```swift
@propertyWrapper
struct Injected<T> {
    private let keyPath: KeyPath<DependencyContainer, T>

    @MainActor
    public var wrappedValue: T {
        DependencyContainer.shared[keyPath: keyPath]
    }
}

// Usage
@Injected(\.githubRepository) private var repository
```

**Benefits:**
- Compile-time safety
- Testable (swap dependencies)
- Clean syntax
- No external frameworks

### Observer Pattern

**SwiftUI + @Observable:**
```swift
@Observable
final class HomeViewModel {
    var searchText: String = ""
    var searchItems: [SearchItem] = []

    // View automatically updates when these change
}

struct HomeView: View {
    @State private var viewModel = HomeViewModel()

    var body: some View {
        // Automatically observes viewModel changes
    }
}
```

### Singleton Pattern

**Used sparingly:**
- `DependencyContainer.shared`
- `FavoritesManager.shared`
- `Logger` categories

## Concurrency Model

### async/await

All asynchronous operations use Swift concurrency:

```swift
func searchRepositories(query: String) async throws -> SearchItemResponse {
    let request = SearchRepoRequest(queryString: query, perPage: 30, pageNumber: 1)
    return try await apiClient.request(request)
}
```

### @MainActor

UI updates run on main thread:

```swift
@Observable
@MainActor
final class HomeViewModel {
    var searchItems: [SearchItem] = []

    func performSearch() async {
        // Automatically on main thread
        searchItems = try await repository.searchRepositories(query: searchText)
    }
}
```

### Task Management

Cancellable tasks for debouncing:

```swift
private var searchTask: Task<Void, Never>?

func onSearchTextChange() {
    searchTask?.cancel()
    searchTask = Task {
        try? await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
        await performSearch()
    }
}
```

## Error Handling

### Typed Errors

```swift
enum NetworkError: Error {
    case invalidURL
    case requestFailed(Error)
    case invalidResponse(statusCode: Int, message: String)
    case decodingFailed(Error)
}
```

### Error Propagation

```swift
// Repository
func searchRepositories(query: String) async throws -> SearchItemResponse {
    try await apiClient.request(request)
}

// ViewModel
func performSearch() async {
    do {
        searchItems = try await repository.searchRepositories(query: searchText)
        messageState = .loaded
    } catch {
        messageState = .error(error.localizedDescription)
        logger.error("Search failed: \(error)")
    }
}
```

## State Management

### ViewModel State

```swift
enum MessageState {
    case loading
    case loaded
    case emptySearchResult
    case error(String)
}

@Observable
final class HomeViewModel {
    var messageState: MessageState = .loaded
    var searchItems: [SearchItem] = []
    var searchText: String = ""
}
```

### Navigation State

```swift
@Observable
final class NavigationCoordinator {
    var path: NavigationPath = NavigationPath()

    func navigateToDetail(_ item: SearchItem) {
        path.append(item)
    }
}
```

## Caching Strategy

### Multi-Layer Caching

1. **In-Memory (NSCache)**
   - Fast access
   - TTL support
   - Automatic eviction

2. **Keychain (Favorites)**
   - Persistent storage
   - AES-256 encryption
   - Secure

### Cache Keys

```
search:<query>:page:<page>       # Search results
user:<username>                  # User profiles
repos:<username>:page:<page>     # User repositories
```

### TTL Configuration

```swift
searchResults: 300 seconds   (5 minutes)
userProfiles: 600 seconds    (10 minutes)
```

## Analytics & Logging

### Analytics Events

```swift
enum AnalyticsEvent {
    case searchPerformed(query: String, resultCount: Int)
    case repositoryViewed(repositoryName: String)
    case userProfileViewed(username: String)
    case favoriteAdded(type: FavoriteType)
    case favoriteRemoved(type: FavoriteType)
}
```

### Logging Categories

```swift
enum LogCategory: String {
    case networking    // API calls
    case viewModel     // ViewModel operations
    case cache         // Cache operations
    case favorites     // Favorites operations
    case analytics     // Analytics events
    case ui            // UI interactions
    case app           // App lifecycle
    case storage       // Storage operations
    case repository    // Repository operations
}

// Usage
Logger.networking.info("API request: \(url)")
Logger.cache.debug("Cache hit for key: \(key)")
```

## Security

### Secure Storage

- Keychain for favorites
- AES-256 encryption
- Migration from UserDefaults

### Network Security

- HTTPS only
- Certificate pinning (optional)
- No sensitive data in URLs

### Data Privacy

- No user tracking
- Local analytics only
- No third-party SDKs

## Testing Architecture

### Test Pyramid

```
        ┌────────┐
       ╱  UI (1)  ╲
      ├────────────┤
     ╱ Integration ╲
    ╱   Tests (2)   ╲
   ├─────────────────┤
  ╱   Unit Tests (5) ╲
 ╱─────────────────────╲
```

### Mock Implementations

Every protocol has a mock:
- `MockGithubRepository`
- `MockFavoritesRepository`
- `MockCacheService`
- `MockAnalyticsService`

### Test DI Container

```swift
DependencyContainer.shared = .test(
    githubRepository: MockGithubRepository(),
    cacheService: MockCacheService(),
    analyticsService: MockAnalyticsService()
)
```

## Performance Optimizations

### Debouncing

- Search: 3 seconds
- User search: 800ms

### Pagination

- 30 items per page
- Lazy loading
- Infinite scroll

### Image Loading

- AsyncImage with caching
- Placeholder support
- Error handling

### Memory Management

- NSCache for automatic eviction
- Weak references where needed
- Task cancellation

## Future Architecture Considerations

### Scalability

- Modularization (SPM packages)
- Feature flags
- A/B testing framework

### Offline Support

- CoreData integration
- Sync strategy
- Conflict resolution

### Performance

- Image caching library
- Network layer optimization
- Database indexing

## Architecture Decision Records

See individual documentation files for detailed decisions:
- [architecture_patterns.md](architecture_patterns.md)
- [faq/intermediate/swiftdata_offline_storage_sync_architecture.md](faq/intermediate/swiftdata_offline_storage_sync_architecture.md)
- [faq/intermediate/dependency_injection.md](faq/intermediate/dependency_injection.md)
- [faq/beginner/ios_data_storage_options.md](faq/beginner/ios_data_storage_options.md)
- [faq/beginner/caching.md](faq/beginner/caching.md)
- [faq/beginner/error_handling.md](faq/beginner/error_handling.md)

### 📋 Modern Observation Standard & Refactoring Roadmap
- **Standard:** Modern iOS 17+ Observation framework (`@Observable`) is the universal standard for all ViewModels. Normal `var` properties drive UI updates with surgical diffing.
- **TODO:** Audit educational sample views in `Modules/Feature/UI/Samples/` to replace legacy `ObservableObject` and `@Published` with `@Observable`. Follow [Apple Developer: Migrating from ObservableObject to @Observable](https://developer.apple.com/documentation/swiftui/migrating-from-the-observable-object-protocol-to-the-observable-macro).

## Summary

The architecture provides:
- ✓ Clear separation of concerns
- ✓ Testability through DI and protocols
- ✓ Scalability through modular design
- ✓ Maintainability through clean code
- ✓ Performance through caching and optimization
- ✓ Security through encryption and best practices

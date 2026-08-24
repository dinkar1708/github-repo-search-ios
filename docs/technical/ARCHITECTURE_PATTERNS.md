# Architecture Patterns

## Overview
MVVM architecture with Repository pattern, dependency injection, and clean separation of concerns.

## Architecture Layers

### Presentation Layer (Feature)
Location: `Modules/Feature/UI/`

Contains all UI components:
- Views (SwiftUI)
- ViewModels (@Observable)
- Navigation logic
- UI state management

### Data Layer (Data)
Location: `Modules/Data/`

Handles data operations:
- Remote API calls
- Data models
- Repository implementations
- Network error handling

### Core Layer (Core)
Location: `Modules/Core/`

Provides infrastructure:
- Dependency injection
- Logging system
- Caching service
- Analytics service
- Keychain storage

## MVVM Pattern

### View
SwiftUI views with no business logic:

```swift
struct HomeView: View {
    @State private var viewModel = HomeViewModel()

    var body: some View {
        List(viewModel.repositories) { repo in
            RepositoryCard(repository: repo)
        }
        .searchable(text: $viewModel.searchText)
        .task {
            await viewModel.performSearch()
        }
    }
}
```

### ViewModel
Business logic and state management:

```swift
@Observable
@MainActor
class HomeViewModel {
    @ObservationIgnored @Injected(\.githubRepository) private var repository
    @ObservationIgnored @Injected(\.analyticsService) private var analytics

    var searchText = ""
    var repositories: [SearchItem] = []
    var isLoading = false
    var errorMessage: String?

    func performSearch() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let response = try await repository.searchRepositories(query: searchText)
            self.repositories = response.items
            analytics.track(event: .searchPerformed(query: searchText, resultCount: response.totalCount))
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
```

### Model
Data structures representing API entities and domain models:

```swift
struct SearchItem: Decodable, Hashable, Identifiable, Sendable {
    let id: Int
    let name: String
    let fullName: String
    let description: String?
    let owner: Owner
    let stargazersCount: Int
    let forksCount: Int
}
```

#### 📦 Model Protocol Conformance Guide:

| Protocol | Purpose & Data Direction | Why Used in This App |
| :--- | :--- | :--- |
| **`Decodable`** | **JSON ➔ Swift Struct**<br>Decodes raw API response bytes into strongly-typed properties. | We use `Decodable` (instead of full `Codable`) because search results are **read-only** from GitHub API. Conforming only to what is needed reduces compiled binary size. |
| **`Encodable`** | **Swift Struct ➔ JSON**<br>Serializes Swift data into raw JSON for POST/PUT request bodies. | Used when sending request payloads (e.g. creating bookmarks, user preferences). |
| **`Codable`** | **Both Ways**<br>Typealias for `Decodable & Encodable`. | Used when a model needs both upload and download serialization. |
| **`Identifiable`** | **SwiftUI List & Diffing**<br>Requires unique `var id: Int / String`. | Powers smooth SwiftUI `List` and `ForEach` row animations without requiring manual `id: \.id` keypaths. |
| **`Hashable`** | **Navigation & Set Collections**<br>Enables hashing and equality (`==`). | Allows models to be used as `NavigationStack(value:)` destinations (`.navigationDestination(for: SearchItem.self)`) and in `Set<SearchItem>` for $O(1)$ fast lookup. |
| **`Sendable`** | **Swift 6 Concurrency & Thread Safety**<br>Guarantees safe thread boundary crossing. | Allows models to be safely passed from background `URLSession` / `Task.detached` threads to `@MainActor` ViewModels without data races. |

## Repository Pattern

### Protocol Definition
```swift
protocol GithubRepository: Sendable {
    func searchRepositories(query: String, page: Int) async throws -> SearchItemResponse
    func searchUsers(query: String, page: Int) async throws -> SearchUserResponse
    func getUserProfile(username: String) async throws -> UserProfile
    func getUserRepositories(username: String, page: Int) async throws -> [UserRepository]
}
```

### Implementation
```swift
class GithubRepositoryImpl: GithubRepository {
    private let apiClient: ApiClient

    init(apiClient: ApiClient = ApiClient()) {
        self.apiClient = apiClient
    }

    func searchRepositories(query: String, page: Int) async throws -> SearchItemResponse {
        let request = SearchRepositoriesRequest(query: query, page: page)
        return try await apiClient.request(request)
    }
}
```

### Benefits
- Abstracts data source
- Easy to mock for testing
- Swappable implementations
- Testable without network

## Dependency Injection

### Container-Based DI
```swift
@MainActor
final class DependencyContainer: @unchecked Sendable {
    static var shared = DependencyContainer()

    let githubRepository: GithubRepository
    let favoritesRepository: FavoritesRepository
    let cacheService: CacheService
    let analyticsService: AnalyticsService

    init(
        githubRepository: GithubRepository = GithubRepositoryImpl(),
        favoritesRepository: FavoritesRepository = KeychainFavoritesRepository(),
        cacheService: CacheService = CacheServiceImpl(),
        analyticsService: AnalyticsService = ConsoleAnalyticsService()
    ) {
        self.githubRepository = githubRepository
        self.favoritesRepository = favoritesRepository
        self.cacheService = cacheService
        self.analyticsService = analyticsService
    }
}
```

### Property Wrapper
```swift
@propertyWrapper
struct Injected<T> {
    private let keyPath: KeyPath<DependencyContainer, T>

    init(_ keyPath: KeyPath<DependencyContainer, T>) {
        self.keyPath = keyPath
    }

    @MainActor
    public var wrappedValue: T {
        DependencyContainer.shared[keyPath: keyPath]
    }
}
```

### Usage
```swift
@Observable
@MainActor
class HomeViewModel {
    @ObservationIgnored @Injected(\.githubRepository) private var repository
}
```

## Data Flow

### Unidirectional Flow
```
User Action
    |
    v
View Event
    |
    v
ViewModel Method
    |
    v
Repository Call
    |
    v
API Request
    |
    v
Response
    |
    v
ViewModel State Update
    |
    v
View Re-render
```

### Example Flow
```swift
// 1. User types in search field
.searchable(text: $viewModel.searchText)

// 2. View triggers search
.onChange(of: viewModel.searchText) {
    Task { await viewModel.performSearch() }
}

// 3. ViewModel calls repository
let response = try await repository.searchRepositories(query: searchText)

// 4. Repository makes API request
return try await apiClient.request(SearchRepositoriesRequest(query: query))

// 5. API client handles network
let (data, response) = try await URLSession.shared.data(for: request)

// 6. Response decoded
let decoded = try JSONDecoder().decode(SearchItemResponse.self, from: data)

// 7. ViewModel updates state
self.repositories = decoded.items

// 8. View automatically re-renders (via @Observable)
List(viewModel.repositories) { repo in ... }
```

## Separation of Concerns

### View Responsibilities
- Display data
- Handle user input
- Navigation
- Layout

### ViewModel Responsibilities
- Business logic
- State management
- Data transformation
- Error handling

### Repository Responsibilities
- Data fetching
- Data persistence
- API abstraction

### Service Responsibilities
- Cross-cutting concerns
- Caching
- Logging
- Analytics

## Thread Safety

### @MainActor
All UI-related code runs on main thread:

```swift
@Observable
@MainActor
class HomeViewModel {
    // All properties and methods are @MainActor
}
```

### Sendable
Data models are thread-safe:

```swift
struct SearchItem: Decodable, Identifiable, Sendable {
    // All properties are value types or Sendable
}
```

### Async/Await
Network calls use structured concurrency:

```swift
func performSearch() async {
    do {
        let response = try await repository.searchRepositories(query: searchText)
        // Automatically back on @MainActor
        self.repositories = response.items
    } catch {
        self.errorMessage = error.localizedDescription
    }
}
```

## Navigation

### NavigationStack
Modern navigation with type-safe paths:

```swift
struct MainTabView: View {
    @State private var navigationPath = NavigationPath()

    var body: some View {
        NavigationStack(path: $navigationPath) {
            HomeView()
                .navigationDestination(for: SearchItem.self) { item in
                    RepositoryDetailView(repository: item)
                }
        }
    }
}
```

## State Management

### @Observable Macro
Modern state management (iOS 17+):

```swift
@Observable
class HomeViewModel {
    var searchText = ""  // Automatically tracked
    var repositories: [SearchItem] = []  // Automatically tracked
}
```

### Benefits
- No @Published needed
- Automatic change tracking
- Fine-grained updates
- Better performance

### With @State
```swift
struct HomeView: View {
    @State private var viewModel = HomeViewModel()

    var body: some View {
        // View updates when viewModel properties change
    }
}
```

## Testing Architecture

### Protocol-Based Design
Easy to create mocks:

```swift
class MockGithubRepository: GithubRepository {
    var mockResponse: SearchItemResponse?
    var shouldThrowError = false

    func searchRepositories(query: String, page: Int) async throws -> SearchItemResponse {
        if shouldThrowError {
            throw NetworkError.requestFailed(URLError(.notConnectedToInternet))
        }
        return mockResponse ?? SearchItemResponse(items: [], totalCount: 0)
    }
}
```

### Dependency Injection
Easy to inject mocks:

```swift
func testSearch() async throws {
    let mock = MockGithubRepository()
    mock.mockResponse = SearchItemResponse(items: testItems, totalCount: 10)

    DependencyContainer.shared = .test(githubRepository: mock)

    let viewModel = HomeViewModel()
    await viewModel.performSearch()

    XCTAssertEqual(viewModel.repositories.count, 10)
}
```

## Design Principles

### SOLID Principles

#### Single Responsibility
Each class has one reason to change:
- ApiClient: Network requests
- GithubRepository: API abstraction
- HomeViewModel: Search UI logic

#### Open/Closed
Open for extension, closed for modification:
- Protocol-based design allows new implementations
- Repository pattern allows different data sources

#### Liskov Substitution
Implementations are interchangeable:
- MockGithubRepository can replace GithubRepositoryImpl
- No behavior changes required

#### Interface Segregation
Small, focused protocols:
- GithubRepository: API operations
- CacheService: Caching operations
- AnalyticsService: Event tracking

#### Dependency Inversion
Depend on abstractions, not concretions:
- ViewModels depend on protocols
- Injected via DependencyContainer
- Concrete implementations at runtime

## Best Practices

### ViewModels
- Keep ViewModels platform-agnostic
- No UIKit/SwiftUI imports in ViewModels
- Use @MainActor for UI ViewModels
- Use @ObservationIgnored with @Injected

### Repositories
- One repository per domain entity
- Protocol-based design
- Async/await for all operations
- Proper error handling

### Views
- No business logic in Views
- Use ViewModels for state
- Keep views small and focused
- Extract reusable components

### Dependency Injection
- Register all dependencies in container
- Use property wrappers for injection
- Provide mock implementations for tests
- Keep container @MainActor isolated

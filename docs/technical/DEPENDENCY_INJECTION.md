# Dependency Injection System

## Overview
Custom property wrapper-based DI system for clean, testable code.

## Core Components

### DependencyContainer
Central registry for all dependencies.

Location: `Modules/Core/DI/DependencyContainer.swift`

```swift
@MainActor
final class DependencyContainer: @unchecked Sendable {
    static var shared = DependencyContainer()

    let githubRepository: GithubRepository
    let favoritesRepository: FavoritesRepository
    let cacheService: CacheService
    let analyticsService: AnalyticsService
}
```

### @Injected Property Wrapper
Zero-boilerplate dependency injection.

```swift
@propertyWrapper
struct Injected<T> {
    private let keyPath: KeyPath<DependencyContainer, T>

    @MainActor
    public var wrappedValue: T {
        DependencyContainer.shared[keyPath: keyPath]
    }
}
```

## Usage

### In ViewModels
```swift
@Observable
@MainActor
class HomeViewModel {
    @ObservationIgnored @Injected(\.githubRepository) private var repository
    @ObservationIgnored @Injected(\.analyticsService) private var analytics
    @ObservationIgnored @Injected(\.cacheService) private var cache
}
```

### Important: @ObservationIgnored
Always use @ObservationIgnored with @Injected to prevent conflicts with @Observable macro.

## Testing

### Test Container
```swift
DependencyContainer.shared = .test(
    githubRepository: MockGithubRepository(),
    cacheService: MockCacheService(),
    analyticsService: MockAnalyticsService()
)
```

### Test Setup Example
```swift
class HomeViewModelTests: XCTestCase {
    var mockRepository: MockGithubRepository!
    var sut: HomeViewModel!

    override func setUp() {
        mockRepository = MockGithubRepository()
        DependencyContainer.shared = .test(
            githubRepository: mockRepository
        )
        sut = HomeViewModel()
    }
}
```

## Registered Dependencies

### Repositories
- `githubRepository: GithubRepository` - API communication
- `favoritesRepository: FavoritesRepository` - Keychain storage

### Services
- `cacheService: CacheService` - Caching layer
- `analyticsService: AnalyticsService` - Event tracking

## Thread Safety
- DependencyContainer is @MainActor isolated
- All property wrapper access is @MainActor
- Safe for concurrent access

## Benefits
- Zero boilerplate in ViewModels
- One-line test setup
- Type-safe dependencies
- Compile-time verification
- Easy to mock

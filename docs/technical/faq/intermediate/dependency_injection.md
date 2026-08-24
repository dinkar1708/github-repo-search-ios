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

### Deep Dive: Why is `@ObservationIgnored` Required?

In iOS 17's `@Observable` macro:
1. **Macro Property Synthesis:** By default, `@Observable` inspects all stored properties and generates internal observation hooks (`_$observationRegistrar`) so SwiftUI views re-render when a property changes.
2. **Property Wrapper Conflict:** Property wrappers like `@Injected` have their own projected/wrapped storage. Applying `@Observable` without `@ObservationIgnored` creates a compiler conflict because `@Injected` is a wrapper, not an observable state property.
3. **Stateless Service Optimization:** `gitHubRepository`, `analyticsService`, and `cacheService` are infrastructure dependencies, NOT UI state. Marking them `@ObservationIgnored` ensures SwiftUI never wastes CPU cycles tracking them for view diffing.

---

## 📋 TODO: Modern iOS 17+ Refactoring Roadmap (Constructor Injection)

While the `@Injected` property wrapper works, the modern Swift 6 / iOS 17+ best practice is to migrate to **Constructor / Initializer Injection with Default Values**:

```swift
@Observable
@MainActor
class HomeViewModel {
    // ✅ Modern iOS 17+ Style: `let` constants are automatically ignored by @Observable!
    private let gitHubRepository: GithubRepository
    private let analytics: AnalyticsService
    private let cache: CacheService

    init(
        gitHubRepository: GithubRepository = DependencyContainer.shared.githubRepository,
        analytics: AnalyticsService = DependencyContainer.shared.analyticsService,
        cache: CacheService = DependencyContainer.shared.cacheService
    ) {
        self.gitHubRepository = gitHubRepository
        self.analytics = analytics
        self.cache = cache
    }
}
```

### 🌟 Advantages of Modern Constructor Injection:
* **Zero Boilerplate:** No need for `@ObservationIgnored` on every property (`let` constants are skipped by `@Observable` automatically).
* **Isolated Unit Testing:** Unit tests can inject mock dependencies directly into `HomeViewModel(gitHubRepository: MockRepository())` without mutating global static state (`DependencyContainer.shared = .test(...)`).
* **Explicit Dependencies:** Clearly reveals all class dependencies in the `init` signature.

---

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

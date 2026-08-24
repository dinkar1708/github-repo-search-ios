# Async/Await & Structured Concurrency in Swift

## Overview

Async/await is Swift's modern approach to asynchronous programming, introduced in Swift 5.5. It provides a cleaner, more readable alternative to completion handlers and combines with structured concurrency to make concurrent code safer and easier to reason about.

## 📁 Code Examples in Project

**Complete working example:** [`Modules/Feature/UI/Samples/Beginner/AsyncAwaitView.swift`](../../../../github_repo_search_iOS_app/Modules/Feature/UI/Samples/Beginner/AsyncAwaitView.swift)

This file demonstrates:
- ✅ Async functions with await
- ✅ Task creation and management
- ✅ Task groups for parallel execution
- ✅ Error handling with async/await
- ✅ Interactive examples with API simulation

**Real usage in production code:**
- `Modules/Data/Remote/API/ApiClient.swift` - Async API calls with URLSession
- `Modules/Data/Remote/Repository/GithubRepository.swift` - Async repository pattern
- `Modules/Feature/UI/Home/ViewModel/HomeViewModel.swift` - Task-based debouncing
- `Modules/Feature/UI/UserProfile/ViewModel/UserProfileViewModel.swift` - Concurrent data fetching

## Why It Matters

- Modern Swift standard for asynchronous operations
- Replacing completion handlers and callbacks
- Essential for API calls, database operations, and long-running tasks
- Frequently asked in iOS technical assessments for iOS 15+ positions
- Foundation for building responsive, non-blocking UIs
- Prevents common concurrency bugs

## Key Concepts

### 1. The Problem: Completion Handlers

**Old Approach (Callbacks):**
```swift
// Callback hell / Pyramid of doom
func loadUserProfile(userId: String, completion: @escaping (Result<User, Error>) -> Void) {
    fetchUser(userId) { result in
        switch result {
        case .success(let user):
            fetchUserPosts(user.id) { postsResult in
                switch postsResult {
                case .success(let posts):
                    fetchComments(posts.first?.id ?? "") { commentsResult in
                        // Nested deeper and deeper...
                        completion(.success(user))
                    }
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        case .failure(let error):
            completion(.failure(error))
        }
    }
}
```

**Problems:**
- Deeply nested code (pyramid of doom)
- Hard to read and maintain
- Error handling scattered
- Easy to forget completion calls
- Difficult to cancel operations

### 2. The Solution: Async/Await

**Modern Approach:**
```swift
// Clean, sequential code
func loadUserProfile(userId: String) async throws -> User {
    let user = try await fetchUser(userId)
    let posts = try await fetchUserPosts(user.id)
    let comments = try await fetchComments(posts.first?.id ?? "")
    return user
}
```

**Benefits:**
- Reads like synchronous code
- Clear error handling with try
- Automatic propagation of errors
- Easier to understand flow
- Built-in cancellation support

### 3. Basic Async/Await Syntax

**Declaring async function:**
```swift
func fetchUser(id: String) async throws -> User {
    // Async work here
    return user
}
```

**Calling async function:**
```swift
func loadData() async {
    do {
        let user = try await fetchUser(id: "123")
        print("Loaded: \(user.name)")
    } catch {
        print("Error: \(error)")
    }
}
```

**Components:**
- `async` - Function can suspend execution
- `await` - Potential suspension point
- `throws` - Can throw errors
- `try` - Handle potential errors

### 4. Async Functions in SwiftUI

**Pattern 1: .task modifier**
```swift
struct UserProfileView: View {
    @State private var user: User?
    @State private var isLoading = false

    var body: some View {
        Group {
            if let user = user {
                UserDetailView(user: user)
            } else if isLoading {
                ProgressView()
            }
        }
        .task {
            isLoading = true
            do {
                user = try await fetchUser(id: "123")
            } catch {
                print("Error: \(error)")
            }
            isLoading = false
        }
    }
}
```

**What .task does:**
- Runs async code when view appears
- Automatically cancels when view disappears
- Tied to view lifecycle
- Safe for async operations

**Pattern 2: Task in button action**
```swift
struct LoadButton: View {
    @State private var data: String?

    var body: some View {
        Button("Load Data") {
            Task {
                data = try? await loadData()
            }
        }
    }
}
```

### 5. Structured Concurrency with Task

**Creating Tasks:**
```swift
func loadMultipleUsers() async throws -> [User] {
    // Create a task
    let task1 = Task {
        try await fetchUser(id: "1")
    }

    let task2 = Task {
        try await fetchUser(id: "2")
    }

    // Wait for results
    let user1 = try await task1.value
    let user2 = try await task2.value

    return [user1, user2]
}
```

**Task Properties:**
- `task.value` - Waits for result
- `task.cancel()` - Cancels task
- `task.isCancelled` - Check if cancelled
- Automatic cancellation propagation

### 6. Parallel Execution with async let

**Sequential (Slow):**
```swift
func loadUserData() async throws -> (User, [Post], [Comment]) {
    let user = try await fetchUser(id: "123")      // Wait
    let posts = try await fetchPosts(userId: "123") // Wait
    let comments = try await fetchComments()        // Wait

    return (user, posts, comments)
}
// Total time: 3 seconds (1s + 1s + 1s)
```

**Parallel (Fast):**
```swift
func loadUserData() async throws -> (User, [Post], [Comment]) {
    async let user = fetchUser(id: "123")          // Start
    async let posts = fetchPosts(userId: "123")    // Start
    async let comments = fetchComments()           // Start

    // Wait for all to complete
    return try await (user, posts, comments)
}
// Total time: 1 second (parallel execution)
```

**Key Points:**
- `async let` starts task immediately
- Doesn't wait for result right away
- All must complete before returning
- Automatic error propagation
- Automatic cancellation if one fails

### 7. TaskGroup for Dynamic Concurrency

**Problem: Unknown number of tasks**
```swift
// Can't use async let when count is dynamic
let userIds = ["1", "2", "3", ..., "100"]
```

**Solution: TaskGroup**
```swift
func fetchAllUsers(ids: [String]) async throws -> [User] {
    try await withThrowingTaskGroup(of: User.self) { group in
        // Add tasks dynamically
        for id in ids {
            group.addTask {
                try await fetchUser(id: id)
            }
        }

        // Collect results
        var users: [User] = []
        for try await user in group {
            users.append(user)
        }
        return users
    }
}
```

**TaskGroup Variants:**
```swift
// Can throw errors
withThrowingTaskGroup(of: User.self) { group in ... }

// Cannot throw errors
withTaskGroup(of: User.self) { group in ... }
```

### 8. MainActor for UI Updates

**Problem: Thread safety**
```swift
func loadData() async {
    let data = try await fetchData()
    // ERROR: Must be on main thread
    self.displayData = data  // UI update on background thread!
}
```

**Solution 1: @MainActor on function**
```swift
@MainActor
func updateUI() async {
    let data = try await fetchData()
    self.displayData = data  // Guaranteed on main thread
}
```

**Solution 2: @MainActor on class**
```swift
@MainActor
class UserViewModel: ObservableObject {
    @Published var user: User?

    func loadUser() async {
        // All code here runs on main thread
        user = try? await fetchUser(id: "123")
    }
}
```

**Solution 3: Explicit MainActor.run**
```swift
func loadData() async {
    let data = try await fetchData()

    await MainActor.run {
        self.displayData = data  // Safe UI update
    }
}
```

### 9. Error Handling

**Pattern 1: try/catch**
```swift
func loadUser() async {
    do {
        let user = try await fetchUser(id: "123")
        print("Success: \(user.name)")
    } catch NetworkError.notFound {
        print("User not found")
    } catch NetworkError.timeout {
        print("Request timed out")
    } catch {
        print("Unknown error: \(error)")
    }
}
```

**Pattern 2: try? (Optional)**
```swift
func loadUser() async {
    if let user = try? await fetchUser(id: "123") {
        print("Success: \(user.name)")
    } else {
        print("Failed to load user")
    }
}
```

**Pattern 3: try! (Crash if fails)**
```swift
func loadUser() async {
    let user = try! await fetchUser(id: "123")  // Use only when guaranteed
    print("User: \(user.name)")
}
```

### 10. Cancellation

**Checking for cancellation:**
```swift
func processLargeDataset() async throws -> [Result] {
    var results: [Result] = []

    for item in largeDataset {
        // Check if cancelled
        try Task.checkCancellation()

        // Or manually check
        if Task.isCancelled {
            print("Task cancelled, cleaning up...")
            break
        }

        let result = await processItem(item)
        results.append(result)
    }

    return results
}
```

**Cancelling a task:**
```swift
let task = Task {
    try await longRunningOperation()
}

// Cancel from elsewhere
task.cancel()
```

**SwiftUI automatic cancellation:**
```swift
struct DataView: View {
    @State private var data: Data?

    var body: some View {
        Text(data?.description ?? "Loading...")
            .task {
                data = try? await loadData()
                // Automatically cancelled when view disappears
            }
    }
}
```

## Real-World Examples

### Example 1: API Call

**Old way (completion handler):**
```swift
func fetchUser(id: String, completion: @escaping (Result<User, Error>) -> Void) {
    URLSession.shared.dataTask(with: url) { data, response, error in
        if let error = error {
            completion(.failure(error))
            return
        }

        guard let data = data else {
            completion(.failure(NetworkError.noData))
            return
        }

        do {
            let user = try JSONDecoder().decode(User.self, from: data)
            completion(.success(user))
        } catch {
            completion(.failure(error))
        }
    }.resume()
}
```

**New way (async/await):**
```swift
func fetchUser(id: String) async throws -> User {
    let (data, _) = try await URLSession.shared.data(from: url)
    return try JSONDecoder().decode(User.self, from: data)
}
```

### Example 2: ViewModel with Async Operations

```swift
@MainActor
class UserViewModel: ObservableObject {
    @Published var user: User?
    @Published var posts: [Post] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let api: APIClient

    init(api: APIClient) {
        self.api = api
    }

    func loadUserProfile(userId: String) async {
        isLoading = true
        errorMessage = nil

        do {
            // Load user and posts in parallel
            async let userTask = api.fetchUser(id: userId)
            async let postsTask = api.fetchPosts(userId: userId)

            let (fetchedUser, fetchedPosts) = try await (userTask, postsTask)

            user = fetchedUser
            posts = fetchedPosts
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func refreshData() async {
        guard let userId = user?.id else { return }
        await loadUserProfile(userId: userId)
    }
}
```

### Example 3: SwiftUI View with Async Loading

```swift
struct UserProfileView: View {
    @StateObject private var viewModel = UserViewModel(api: APIClient())
    let userId: String

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView("Loading...")
            } else if let user = viewModel.user {
                VStack {
                    Text(user.name)
                    List(viewModel.posts) { post in
                        Text(post.title)
                    }
                }
            } else if let error = viewModel.errorMessage {
                Text("Error: \(error)")
            }
        }
        .task {
            await viewModel.loadUserProfile(userId: userId)
        }
        .refreshable {
            await viewModel.refreshData()
        }
    }
}
```

### Example 4: Multiple API Calls with Error Handling

```swift
@MainActor
class DashboardViewModel: ObservableObject {
    @Published var userData: UserData?
    @Published var isLoading = false

    func loadDashboard() async {
        isLoading = true
        defer { isLoading = false }

        do {
            // Load multiple endpoints in parallel
            async let user = api.fetchUser()
            async let stats = api.fetchStats()
            async let notifications = api.fetchNotifications()

            let (fetchedUser, fetchedStats, fetchedNotifications) = try await (user, stats, notifications)

            userData = UserData(
                user: fetchedUser,
                stats: fetchedStats,
                notifications: fetchedNotifications
            )
        } catch {
            print("Failed to load dashboard: \(error)")
        }
    }
}
```

## Common Patterns

### Pattern 1: Retry Logic

```swift
func fetchWithRetry<T>(
    maxRetries: Int = 3,
    operation: @escaping () async throws -> T
) async throws -> T {
    var lastError: Error?

    for attempt in 1...maxRetries {
        do {
            return try await operation()
        } catch {
            lastError = error
            if attempt < maxRetries {
                let delay = UInt64(attempt * 1_000_000_000)  // Exponential backoff
                try await Task.sleep(nanoseconds: delay)
            }
        }
    }

    throw lastError ?? NSError(domain: "Retry failed", code: -1)
}

// Usage
let user = try await fetchWithRetry {
    try await api.fetchUser(id: "123")
}
```

### Pattern 2: Timeout

```swift
func withTimeout<T>(
    seconds: TimeInterval,
    operation: @escaping () async throws -> T
) async throws -> T {
    try await withThrowingTaskGroup(of: T.self) { group in
        group.addTask {
            try await operation()
        }

        group.addTask {
            try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
            throw TimeoutError()
        }

        let result = try await group.next()!
        group.cancelAll()
        return result
    }
}

// Usage
let user = try await withTimeout(seconds: 5) {
    try await api.fetchUser(id: "123")
}
```

### Pattern 3: Debouncing

```swift
actor Debouncer {
    private var task: Task<Void, Never>?

    func debounce(for duration: TimeInterval, operation: @escaping () async -> Void) {
        task?.cancel()

        task = Task {
            try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))

            guard !Task.isCancelled else { return }

            await operation()
        }
    }
}

// Usage in View
struct SearchView: View {
    @State private var searchText = ""
    @State private var results: [Item] = []
    private let debouncer = Debouncer()

    var body: some View {
        TextField("Search", text: $searchText)
            .onChange(of: searchText) { newValue in
                Task {
                    await debouncer.debounce(for: 0.5) {
                        results = await performSearch(newValue)
                    }
                }
            }
    }
}
```

## Comparison: Async/Await vs Completion Handlers

| Aspect | Completion Handlers | Async/Await |
|--------|-------------------|-------------|
| Readability | Poor (nested) | Excellent (linear) |
| Error Handling | Manual in each closure | try/catch, automatic |
| Cancellation | Manual tracking | Built-in with Task |
| Thread Safety | Manual dispatch | MainActor annotation |
| Type Safety | Weak (Any in closures) | Strong (typed async) |
| Performance | Similar | Similar |
| Code Length | Longer | Shorter |
| Learning Curve | Lower | Higher |
| Modern iOS | Legacy | Standard |

## Common Mistakes

### Mistake 1: Forgetting await

```swift
// WRONG - Compile error
func loadUser() async {
    let user = fetchUser(id: "123")  // Error: missing await
}

// CORRECT
func loadUser() async {
    let user = await fetchUser(id: "123")
}
```

### Mistake 2: UI Updates on Background Thread

```swift
// WRONG
func loadData() async {
    let data = try await fetchData()
    self.displayData = data  // Crash: UI update on background thread
}

// CORRECT - Option 1: @MainActor on function
@MainActor
func loadData() async {
    let data = try await fetchData()
    self.displayData = data
}

// CORRECT - Option 2: MainActor.run
func loadData() async {
    let data = try await fetchData()
    await MainActor.run {
        self.displayData = data
    }
}
```

### Mistake 3: Blocking Main Thread

```swift
// WRONG - Blocks UI
func loadUser() {
    Task {
        let user = try await fetchUser(id: "123")
    }
    // Code here runs before user is loaded!
}

// CORRECT - Properly async
func loadUser() async {
    let user = try await fetchUser(id: "123")
    // Code here runs after user is loaded
}
```

### Mistake 4: Not Handling Cancellation

```swift
// WRONG - Ignores cancellation
func processItems() async {
    for item in items {
        await process(item)  // Continues even if cancelled
    }
}

// CORRECT - Checks cancellation
func processItems() async throws {
    for item in items {
        try Task.checkCancellation()
        await process(item)
    }
}
```

## Technical Questions

### Q1: What's the difference between async and await?
**Answer:**
- `async` marks a function that can suspend execution
- `await` marks a potential suspension point where function waits
- `async` is declaration, `await` is usage
- Every `await` must be in an `async` context

### Q2: How do you run async code from synchronous context?
**Answer:**
```swift
// Use Task
func synchronousFunction() {
    Task {
        await asyncFunction()
    }
}
```

### Q3: What's the difference between async let and regular let with await?
**Answer:**
- `async let` starts task immediately without waiting
- `let` with `await` waits for completion before continuing
- `async let` enables parallel execution
- `await` with tuple waits for all `async let` to complete

### Q4: How do you ensure UI updates happen on main thread?
**Answer:**
- Mark class/function with `@MainActor`
- Use `MainActor.run { }`
- All SwiftUI views are implicitly `@MainActor`

### Q5: What happens when a Task is cancelled?
**Answer:**
- `Task.isCancelled` becomes true
- `Task.checkCancellation()` throws `CancellationError`
- Child tasks are automatically cancelled
- Must manually check and handle cancellation

### Q6: What's the difference between Task and async let?
**Answer:**
- `Task` creates unstructured concurrency
- `async let` creates structured concurrency
- `async let` must complete before function returns
- `Task` can outlive function scope

### Q7: How do you handle errors in async functions?
**Answer:**
```swift
do {
    let result = try await asyncFunction()
} catch MyError.specific {
    // Handle specific error
} catch {
    // Handle any error
}
```

### Q8: What's TaskGroup used for?
**Answer:**
- Dynamic number of parallel tasks
- Unknown task count at compile time
- Collecting results from multiple tasks
- More flexible than `async let`

## Related Topics

- [Swift Optionals](../beginner/swift_optionals.md) - Error handling with optionals
- [Closures](../beginner/swift_closures.md) - Understanding closure capture
- [Property Wrappers](./property_wrappers.md) - @Published with async
- [Combine Framework](./combine_basics.md) - Alternative reactive approach
- [Actors](../advanced/actors_thread_safety.md) - Thread-safe state

## Further Reading

- [Swift Concurrency Documentation](https://docs.swift.org/swift-book/LanguageGuide/Concurrency.html)
- [WWDC 2021 - Meet async/await in Swift](https://developer.apple.com/videos/play/wwdc2021/10132/)
- [WWDC 2021 - Explore structured concurrency in Swift](https://developer.apple.com/videos/play/wwdc2021/10134/)
- [Swift by Sundell - Async/Await Guide](https://www.swiftbysundell.com/articles/async-await-guide/)

---

**Last Updated:** 2026-08-16
**Difficulty:** Intermediate
**Estimated Reading Time:** 30 minutes
**Prerequisites:** Basic Swift, closures, error handling

---

## Quick Reference

```swift
// Basic async function
func fetch() async throws -> Data { }

// Call with await
let data = try await fetch()

// Parallel execution
async let a = fetchA()
async let b = fetchB()
let (resultA, resultB) = try await (a, b)

// TaskGroup for dynamic tasks
try await withThrowingTaskGroup(of: Item.self) { group in
    for id in ids {
        group.addTask { try await fetch(id) }
    }
}

// MainActor for UI
@MainActor
func updateUI() async { }

// Cancellation
try Task.checkCancellation()
if Task.isCancelled { return }
```

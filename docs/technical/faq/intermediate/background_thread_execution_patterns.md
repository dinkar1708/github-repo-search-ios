# Background Thread Execution Patterns in iOS

This guide covers the main patterns for executing code on background threads in iOS applications.

## 1. Grand Central Dispatch (GCD)

The most common approach for concurrent execution using dispatch queues.

### Basic Usage

```swift
// Async execution on background queue
DispatchQueue.global(qos: .background).async {
    // Heavy work here
    let result = performHeavyComputation()

    // Update UI on main thread
    DispatchQueue.main.async {
        self.label.text = result
    }
}

// Execute after delay
DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
    // Delayed execution
}
```

### Queue Types

```swift
// Serial queue - executes tasks one at a time in order
let serialQueue = DispatchQueue(label: "com.app.serial")

// Concurrent queue - executes multiple tasks simultaneously
let concurrentQueue = DispatchQueue(label: "com.app.concurrent",
                                   attributes: .concurrent)

// Main queue - always use for UI updates
DispatchQueue.main.async {
    // UI updates
}
```

### Quality of Service (QoS) Levels

- **`.userInteractive`**: Work directly involved with UI (animations, event handling)
- **`.userInitiated`**: Work user initiated and waiting for (loading data user requested)
- **`.default`**: Default priority
- **`.utility`**: Long-running work with user-visible progress (downloads, imports)
- **`.background`**: Work user isn't aware of (prefetching, maintenance)

#### QoS for API Calls and JSON Parsing

**For API Calls:**
- **`.userInitiated`** - When user taps a button and waits for result (e.g., search, refresh)
- **`.utility`** - For pagination, background refresh with visible progress
- **`.background`** - For prefetching, cache updates user doesn't know about

**For Large JSON Parsing:**
- **`.userInitiated`** - If parsing data user is waiting for (search results, detail view)
- **`.utility`** - If parsing large data with progress indicator (import, sync)
- **`.background`** - If parsing prefetched/cached data user isn't waiting for

```swift
// Example: API call + JSON parsing
func fetchAndParseData(userInitiated: Bool) {
    let qos: DispatchQoS.QoSClass = userInitiated ? .userInitiated : .background

    DispatchQueue.global(qos: qos).async {
        // 1. API call
        let data = self.apiClient.fetchData()

        // 2. Large JSON parsing (on same background queue)
        let decoder = JSONDecoder()
        let items = try? decoder.decode([Item].self, from: data)

        // 3. Update UI on main queue
        DispatchQueue.main.async {
            self.items = items
            self.tableView.reloadData()
        }
    }
}

// User tapped search button - use .userInitiated
fetchAndParseData(userInitiated: true)

// Background prefetch - use .background
fetchAndParseData(userInitiated: false)
```

#### Total Dispatch Queues Available

**System Queues (8 total):**

1. **Main Queue (1)** - Serial queue for UI updates
   ```swift
   DispatchQueue.main.async { }
   ```

2. **Global Concurrent Queues (6)** - Based on QoS levels
   ```swift
   DispatchQueue.global(qos: .userInteractive)
   DispatchQueue.global(qos: .userInitiated)
   DispatchQueue.global(qos: .default)
   DispatchQueue.global(qos: .utility)
   DispatchQueue.global(qos: .background)
   DispatchQueue.global(qos: .unspecified)
   ```

3. **System Background Queue (1)** - Internal system use

**Custom Queues:**
- You can create unlimited custom queues (serial or concurrent)
- But use global queues when possible to avoid overhead

```swift
// Avoid creating too many custom queues
// ❌ Bad - creates queue for every request
func fetchData() {
    let queue = DispatchQueue(label: "fetch") // Don't do this!
    queue.async { }
}

// ✅ Good - use global queue
func fetchData() {
    DispatchQueue.global(qos: .userInitiated).async { }
}

// ✅ Good - reuse custom queue for specific purpose
class DataManager {
    private let serialQueue = DispatchQueue(label: "com.app.data")

    func updateData() {
        serialQueue.async { }
    }
}
```

#### Choosing the Right Queue

| Task | Queue | Reason |
|------|-------|--------|
| **User tapped button → API call** | `.global(qos: .userInitiated)` | User waiting for response |
| **User tapped button → Large JSON parsing** | `.global(qos: .userInitiated)` | User waiting for parsed data |
| **Background sync API call** | `.global(qos: .background)` | User not aware, low priority |
| **Background JSON parsing (large)** | `.global(qos: .utility)` or `.background` | Depends if user sees progress |
| **Pagination (scroll to load more)** | `.global(qos: .userInitiated)` | User expects data soon |
| **Prefetch next page** | `.global(qos: .background)` | User hasn't requested yet |
| **UI updates** | `.main` | ALWAYS for UI |
| **Sequential writes to database** | Custom serial queue | Prevent race conditions |

#### Example: Complete API + JSON Parsing Flow

```swift
class RepositoryViewModel {
    private let apiQueue = DispatchQueue(label: "com.app.api", qos: .userInitiated)

    func searchRepositories(query: String) {
        // Use .userInitiated - user is waiting
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }

            // 1. API call
            let jsonData = self.apiClient.search(query: query)

            // 2. Parse large JSON (same queue, same priority)
            let decoder = JSONDecoder()
            let repositories = try? decoder.decode([Repository].self, from: jsonData)

            // 3. Update UI
            DispatchQueue.main.async {
                self.repositories = repositories ?? []
                self.onDataUpdated?()
            }
        }
    }

    func prefetchNextPage() {
        // Use .background - user hasn't requested this yet
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self else { return }

            let jsonData = self.apiClient.fetchNextPage()
            let repositories = try? JSONDecoder().decode([Repository].self, from: jsonData)

            DispatchQueue.main.async {
                self.appendRepositories(repositories ?? [])
            }
        }
    }

    func importLargeFile(fileURL: URL, progressHandler: @escaping (Double) -> Void) {
        // Use .utility - long-running with visible progress
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self = self else { return }

            let data = try? Data(contentsOf: fileURL)

            // Parse in chunks, report progress
            for (index, chunk) in self.splitIntoChunks(data).enumerated() {
                let progress = Double(index) / Double(totalChunks)

                DispatchQueue.main.async {
                    progressHandler(progress)
                }

                // Parse chunk
                _ = try? JSONDecoder().decode([Item].self, from: chunk)
            }

            DispatchQueue.main.async {
                progressHandler(1.0)
            }
        }
    }
}
```

### Dispatch Groups

Coordinate multiple asynchronous tasks:

```swift
let group = DispatchGroup()

// Method 1: enter/leave
group.enter()
fetchDataFromAPI1 { data in
    // Process data
    group.leave()
}

group.enter()
fetchDataFromAPI2 { data in
    // Process data
    group.leave()
}

// Notify when all tasks complete
group.notify(queue: .main) {
    print("All tasks completed")
    self.updateUI()
}

// Or wait synchronously (avoid on main thread!)
// group.wait()
```

### Dispatch Barriers

Ensure exclusive access in concurrent queues:

```swift
let queue = DispatchQueue(label: "com.app.data", attributes: .concurrent)

// Read operations (concurrent)
queue.async {
    let value = self.data
}

// Write operation (exclusive with barrier)
queue.async(flags: .barrier) {
    self.data = newValue
}
```

### Dispatch Semaphores

Control access to limited resources:

```swift
let semaphore = DispatchSemaphore(value: 3) // Max 3 concurrent operations

for i in 1...10 {
    DispatchQueue.global().async {
        semaphore.wait() // Decrement

        // Limited concurrent work
        performNetworkRequest(i)

        semaphore.signal() // Increment
    }
}
```

## 2. Operation & OperationQueue

More structured approach with dependencies, priorities, and cancellation support.

### Basic Usage

```swift
let queue = OperationQueue()
queue.maxConcurrentOperationCount = 3

// Block operation
let operation1 = BlockOperation {
    // Perform work
    print("Operation 1 executing")
}

queue.addOperation(operation1)
```

### Custom Operation Subclass

```swift
class DataProcessingOperation: Operation {
    private let data: Data

    init(data: Data) {
        self.data = data
        super.init()
    }

    override func main() {
        // Check for cancellation
        guard !isCancelled else { return }

        // Perform work
        processData(data)

        // Check again during long operations
        guard !isCancelled else { return }

        saveResults()
    }
}

let operation = DataProcessingOperation(data: data)
queue.addOperation(operation)
```

### Dependencies

```swift
let downloadOperation = DownloadOperation()
let processOperation = ProcessOperation()
let uploadOperation = UploadOperation()

// processOperation waits for downloadOperation
processOperation.addDependency(downloadOperation)

// uploadOperation waits for processOperation
uploadOperation.addDependency(processOperation)

queue.addOperations([downloadOperation, processOperation, uploadOperation],
                   waitUntilFinished: false)
```

### Completion Blocks

```swift
operation.completionBlock = {
    if operation.isCancelled {
        print("Operation was cancelled")
        return
    }

    DispatchQueue.main.async {
        // Update UI
    }
}
```

### Cancellation

```swift
// Cancel specific operation
operation.cancel()

// Cancel all operations in queue
queue.cancelAllOperations()

// Wait for all operations to finish
queue.waitUntilAllOperationsAreFinished()
```

## 3. Modern Swift Concurrency (async/await)

The newest and recommended pattern for iOS 13+ (fully supported iOS 15+).

### Async Functions

```swift
func fetchData() async throws -> Data {
    let (data, response) = try await URLSession.shared.data(from: url)

    guard let httpResponse = response as? HTTPURLResponse,
          httpResponse.statusCode == 200 else {
        throw NetworkError.invalidResponse
    }

    return data
}

// Calling async function
Task {
    do {
        let data = try await fetchData()
        await processData(data)
    } catch {
        print("Error: \(error)")
    }
}
```

### Task Creation

```swift
// Unstructured task
Task {
    await doBackgroundWork()
}

// Task with priority
Task(priority: .background) {
    await heavyWork()
}

// Detached task (doesn't inherit context)
Task.detached {
    await independentWork()
}
```

### MainActor for UI Updates

```swift
@MainActor
func updateUI() {
    // Always runs on main thread
    label.text = "Updated"
}

// Or use MainActor.run
Task {
    let data = await fetchData()

    await MainActor.run {
        self.label.text = String(data: data, encoding: .utf8)
    }
}
```

### Structured Concurrency with TaskGroup

```swift
func fetchMultipleURLs(_ urls: [URL]) async throws -> [Data] {
    try await withThrowingTaskGroup(of: Data.self) { group in
        for url in urls {
            group.addTask {
                let (data, _) = try await URLSession.shared.data(from: url)
                return data
            }
        }

        var results: [Data] = []
        for try await data in group {
            results.append(data)
        }
        return results
    }
}
```

### Actors for Thread-Safe State

```swift
actor DataManager {
    private var cache: [String: Data] = [:]

    func getCachedData(for key: String) -> Data? {
        cache[key]
    }

    func cache(_ data: Data, for key: String) {
        cache[key] = data
    }
}

// Usage
let manager = DataManager()
await manager.cache(data, for: "key")
let cached = await manager.getCachedData(for: "key")
```

### AsyncSequence

```swift
func processLines() async throws {
    let url = URL(fileURLWithPath: "/path/to/file.txt")

    for try await line in url.lines {
        print(line)
    }
}

// Custom AsyncSequence
struct AsyncCountdown: AsyncSequence {
    typealias Element = Int
    let start: Int

    struct AsyncIterator: AsyncIteratorProtocol {
        var current: Int

        mutating func next() async -> Int? {
            guard current >= 0 else { return nil }
            let value = current
            current -= 1
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            return value
        }
    }

    func makeAsyncIterator() -> AsyncIterator {
        AsyncIterator(current: start)
    }
}
```

### Cancellation with Task

```swift
let task = Task {
    for i in 1...100 {
        // Check for cancellation
        try Task.checkCancellation()

        await performWork(i)

        // Or check Task.isCancelled
        if Task.isCancelled {
            cleanup()
            return
        }
    }
}

// Cancel the task
task.cancel()
```

## 4. Background Tasks (App in Background)

For work when the app is not in the foreground.

### BGTaskScheduler (iOS 13+)

```swift
import BackgroundTasks

// Register task in AppDelegate or App struct
func application(_ application: UIApplication,
                didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

    BGTaskScheduler.shared.register(
        forTaskWithIdentifier: "com.app.refresh",
        using: nil
    ) { task in
        self.handleAppRefresh(task: task as! BGAppRefreshTask)
    }

    return true
}

// Schedule task
func scheduleAppRefresh() {
    let request = BGAppRefreshTaskRequest(identifier: "com.app.refresh")
    request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60) // 15 minutes

    do {
        try BGTaskScheduler.shared.submit(request)
    } catch {
        print("Could not schedule app refresh: \(error)")
    }
}

// Handle task
func handleAppRefresh(task: BGAppRefreshTask) {
    scheduleAppRefresh() // Schedule next refresh

    let queue = OperationQueue()
    queue.maxConcurrentOperationCount = 1

    let operation = RefreshOperation()

    task.expirationHandler = {
        queue.cancelAllOperations()
    }

    operation.completionBlock = {
        task.setTaskCompleted(success: !operation.isCancelled)
    }

    queue.addOperation(operation)
}
```

### Background Processing Task

```swift
// For longer processing tasks (minutes)
BGTaskScheduler.shared.register(
    forTaskWithIdentifier: "com.app.processing",
    using: nil
) { task in
    self.handleProcessing(task: task as! BGProcessingTask)
}

let request = BGProcessingTaskRequest(identifier: "com.app.processing")
request.requiresNetworkConnectivity = true
request.requiresExternalPower = false

try? BGTaskScheduler.shared.submit(request)
```

### Background URLSession

```swift
class DownloadManager: NSObject, URLSessionDownloadDelegate {
    var session: URLSession!

    override init() {
        super.init()

        let config = URLSessionConfiguration.background(
            withIdentifier: "com.app.download"
        )
        session = URLSession(configuration: config,
                           delegate: self,
                           delegateQueue: nil)
    }

    func startDownload(url: URL) {
        let task = session.downloadTask(with: url)
        task.resume()
    }

    func urlSession(_ session: URLSession,
                   downloadTask: URLSessionDownloadTask,
                   didFinishDownloadingTo location: URL) {
        // Handle completed download
    }
}
```

### BGTaskScheduler Memory Leak Prevention

**Critical**: BGTaskScheduler tasks can cause memory leaks if not properly managed!

#### Common Memory Leak Causes

1. **Not calling `setTaskCompleted()`** - Task handler never releases
2. **Strong reference cycles** in task handlers
3. **Not cancelling operations** when task expires
4. **Retaining task objects** unnecessarily

#### ❌ Bad - Memory Leaks

```swift
// LEAK: Strong reference cycle
BGTaskScheduler.shared.register(
    forTaskWithIdentifier: "com.app.refresh",
    using: nil
) { task in
    // 'self' is captured strongly
    self.handleAppRefresh(task: task as! BGAppRefreshTask)
}

// LEAK: Never calls setTaskCompleted()
func handleAppRefresh(task: BGAppRefreshTask) {
    performWork()
    // Missing: task.setTaskCompleted(success: true)
    // Task handler is never released!
}

// LEAK: Operations not cancelled on expiration
task.expirationHandler = {
    print("Task expired")
    // Missing: queue.cancelAllOperations()
    // Operations continue running and retain resources
}
```

#### ✅ Good - No Memory Leaks

```swift
// Use weak self in registration handler
BGTaskScheduler.shared.register(
    forTaskWithIdentifier: "com.app.refresh",
    using: nil
) { [weak self] task in
    guard let self = self else {
        task.setTaskCompleted(success: false)
        return
    }
    self.handleAppRefresh(task: task as! BGAppRefreshTask)
}

// ALWAYS call setTaskCompleted()
func handleAppRefresh(task: BGAppRefreshTask) {
    scheduleAppRefresh()

    let queue = OperationQueue()
    queue.maxConcurrentOperationCount = 1

    let operation = RefreshOperation()

    // MUST cancel operations on expiration
    task.expirationHandler = { [weak queue] in
        queue?.cancelAllOperations()
    }

    // MUST call setTaskCompleted in completion
    operation.completionBlock = { [weak self] in
        task.setTaskCompleted(success: !operation.isCancelled)

        // Clean up resources
        self?.cleanup()
    }

    queue.addOperation(operation)
}
```

#### Best Practices for BGTaskScheduler

1. **Always use `[weak self]`** in registration handler
2. **Always call `task.setTaskCompleted()`** - even on errors or cancellation
3. **Always cancel operations** in `expirationHandler`
4. **Set expiration handler** before starting work
5. **Clean up resources** in completion blocks
6. **Test with debugger** - set breakpoint on `setTaskCompleted()` to ensure it's called

#### Complete Safe Implementation

```swift
class BackgroundTaskManager {
    private var currentTask: BGTask?
    private var operationQueue: OperationQueue?

    func registerBackgroundTasks() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: "com.app.refresh",
            using: nil
        ) { [weak self] task in
            self?.handleAppRefresh(task: task as! BGAppRefreshTask)
        }
    }

    private func handleAppRefresh(task: BGAppRefreshTask) {
        currentTask = task
        scheduleNextRefresh()

        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        operationQueue = queue

        let operation = RefreshOperation()

        // Set expiration handler BEFORE adding operations
        task.expirationHandler = { [weak self, weak queue] in
            queue?.cancelAllOperations()
            self?.cleanup()
        }

        // Set completion handler with weak self
        operation.completionBlock = { [weak self, weak operation] in
            let success = !(operation?.isCancelled ?? true)

            // ALWAYS call setTaskCompleted
            task.setTaskCompleted(success: success)

            // Clean up
            self?.cleanup()
        }

        queue.addOperation(operation)
    }

    private func cleanup() {
        operationQueue = nil
        currentTask = nil
    }

    private func scheduleNextRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: "com.app.refresh")
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60)

        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Could not schedule: \(error)")
        }
    }
}
```

#### Debugging BGTaskScheduler Leaks

Use Xcode's Memory Graph Debugger to detect leaks:

```bash
# Simulate background task in debugger
e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateLaunchForTaskWithIdentifier:@"com.app.refresh"]

# Simulate expiration
e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateExpirationForTaskWithIdentifier:@"com.app.refresh"]
```

Check for:
- Retained closures after task completion
- Operations still in queue after expiration
- Strong reference cycles between task handler and view controller

## 5. Thread (Lower-Level)

Rarely needed in modern iOS development.

```swift
Thread.detachNewThread {
    // Work on separate thread
    performWork()

    Thread.sleep(forTimeInterval: 1.0)
}

// Check if on main thread
if Thread.isMainThread {
    // Update UI directly
} else {
    DispatchQueue.main.async {
        // Update UI
    }
}
```

## Pattern Selection Guide

| Pattern | Use When | Pros | Cons |
|---------|----------|------|------|
| **GCD** | Simple async tasks, fire-and-forget operations | Fast, lightweight, easy to use | Less control over execution |
| **OperationQueue** | Complex dependencies, need cancellation, limit concurrency | Cancellable, dependencies, KVO-compliant | More overhead than GCD |
| **async/await** | Modern Swift code, structured concurrency | Clean syntax, compiler-checked, integrates with actors | Requires iOS 13+ (best on iOS 15+) |
| **BGTaskScheduler** | App needs to run periodically in background | System-managed, battery-efficient | Limited execution time |
| **Thread** | Legacy code or very specific requirements | Full control | Manual management, error-prone |

## Best Practices

1. **Use async/await** for new code when targeting iOS 15+
2. **Always update UI on main thread**
3. **Avoid blocking the main thread** - keep it free for user interactions
4. **Use appropriate QoS levels** to help system prioritize work
5. **Handle cancellation** properly in long-running tasks
6. **Avoid excessive thread creation** - use system-managed queues
7. **Use actors** for thread-safe mutable state in Swift Concurrency
8. **Test background patterns** thoroughly, including low-power and low-memory scenarios

## Memory Leak Prevention

When working with background threads:

- **Avoid strong reference cycles**: Use `[weak self]` or `[unowned self]` in closures
- **Cancel tasks properly**: Ensure operations/tasks are cancelled when no longer needed
- **Clean up resources**: Release resources in completion handlers
- **Use structured concurrency**: Prefer `TaskGroup` over unstructured `Task` creation
- **Monitor with Instruments**: Use the Leaks and Allocations instruments to detect issues

```swift
// ✅ Good - weak reference
DispatchQueue.global().async { [weak self] in
    guard let self = self else { return }
    let data = self.fetchData()

    DispatchQueue.main.async { [weak self] in
        self?.updateUI(with: data)
    }
}

// ❌ Bad - strong reference cycle
DispatchQueue.global().async {
    let data = self.fetchData()

    DispatchQueue.main.async {
        self.updateUI(with: data) // Retains self
    }
}
```

## See Also

- [Memory Leak Detection](advanced/memory_leak_detection.md)
- [iOS 17 Observation Migration Guide](ios17_observation_migration_guide.md)
- [Architecture Patterns](../../architecture_patterns.md)

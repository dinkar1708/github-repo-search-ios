# Memory Leak Detection in iOS/SwiftUI

## Purpose

Learn how to detect, diagnose, and fix memory leaks in iOS applications using Xcode Memory Debugger, Instruments, and Swift best practices.

## 📁 Code Examples in Project

**Complete working example:** [`Modules/Feature/UI/Samples/Advanced/MemoryLeakDetectionView.swift`](../../../../github_repo_search_iOS_app/Modules/Feature/UI/Samples/Advanced/MemoryLeakDetectionView.swift)

This file demonstrates:
- ✅ Common memory leak patterns (strong reference cycles)
- ✅ How to fix leaks with [weak self] and [unowned self]
- ✅ Closure capture lists
- ✅ Delegate pattern memory management
- ✅ Timer and observation cleanup
- ✅ Interactive leak simulation

**Real usage in production code:**
- `Modules/Feature/UI/Home/ViewModel/HomeViewModel.swift` - Proper Task cancellation
- `Modules/Feature/UI/UserProfile/ViewModel/UserProfileViewModel.swift` - Weak self in closures
- `Modules/Data/Remote/API/ApiClient.swift` - Memory-safe networking

---

## What is a Memory Leak?

A memory leak occurs when objects are no longer needed but cannot be deallocated because they're still referenced. This leads to:
- Increasing memory usage over time
- App crashes due to memory pressure
- Poor app performance
- Battery drain

---

## Common Causes

### 1. Strong Reference Cycles

```swift
// BAD - Strong reference cycle
class ViewController: UIViewController {
    var closure: (() -> Void)?

    override func viewDidLoad() {
        closure = {
            self.view.backgroundColor = .red  // Captures self strongly
        }
    }
}

// GOOD - Use [weak self]
class ViewController: UIViewController {
    var closure: (() -> Void)?

    override func viewDidLoad() {
        closure = { [weak self] in
            self?.view.backgroundColor = .red
        }
    }
}
```

### 2. Timer Leaks

```swift
// BAD - Timer retains target
class MyView: UIView {
    var timer: Timer?

    func startTimer() {
        timer = Timer.scheduledTimer(
            timeInterval: 1.0,
            target: self,      // Strong reference!
            selector: #selector(tick),
            userInfo: nil,
            repeats: true
        )
    }

    @objc func tick() { }
}

// GOOD - Invalidate timer and use weak reference
class MyView: UIView {
    var timer: Timer?

    func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    func tick() { }

    deinit {
        timer?.invalidate()
        print("✅ MyView deinitialized")
    }
}
```

### 3. NotificationCenter Observers

```swift
// BAD - Observer not removed
class MyViewController: UIViewController {
    override func viewDidLoad() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleNotification),
            name: .someNotification,
            object: nil
        )
        // Missing: removeObserver!
    }
}

// GOOD - Remove observer or use Combine
class MyViewController: UIViewController {
    deinit {
        NotificationCenter.default.removeObserver(self)
        print("✅ Observer removed")
    }
}

// BETTER - Use Combine (auto-cleanup)
import Combine

class MyViewController: UIViewController {
    var cancellables = Set<AnyCancellable>()

    override func viewDidLoad() {
        NotificationCenter.default
            .publisher(for: .someNotification)
            .sink { [weak self] _ in
                self?.handleNotification()
            }
            .store(in: &cancellables)
    }

    // cancellables automatically cleaned up on deinit
}
```

### 4. Delegate Leaks

```swift
// BAD - Strong delegate reference
class DataManager {
    var delegate: DataDelegate?  // Should be weak!
}

// GOOD - Weak delegate
class DataManager {
    weak var delegate: DataDelegate?
}

protocol DataDelegate: AnyObject {  // AnyObject required for weak
    func dataDidUpdate()
}
```

### 5. Uncancelled Async Work

```swift
// BAD - Task continues after view is gone
class MyViewModel {
    func loadData() {
        Task {
            let data = await fetchData()
            self.data = data  // Keeps self alive
        }
    }
}

// GOOD - Cancel task when needed
class MyViewModel {
    var loadTask: Task<Void, Never>?

    func loadData() {
        loadTask = Task { [weak self] in
            let data = await fetchData()
            self?.data = data
        }
    }

    deinit {
        loadTask?.cancel()
        print("✅ Task cancelled")
    }
}
```

---

## Detection Tools

### 1. Xcode Memory Debugger

**How to use**:
1. Run your app in Xcode
2. Navigate through screens
3. Click **Debug** → **Memory** → **Debug Memory Graph** (or ⌘⇧M)
4. Look for purple runtime issue icons (indicate retain cycles)

**What to check**:
- Objects that should be deallocated but aren't
- Purple warning icons showing strong reference cycles
- Object graph showing retain relationships

**Steps**:
```
1. Navigate to a screen
2. Navigate back/dismiss
3. Debug → Memory → Debug Memory Graph
4. Filter by your class name (e.g., "MyViewController")
5. Check instance count (should be 0)
6. If > 0, inspect backtrace references
```

### 2. Instruments - Leaks Template

**How to use**:
1. Product → Profile (⌘I)
2. Select **Leaks** template
3. Click record
4. Interact with your app
5. Look for red leak indicators in timeline

**What to check**:
- Red bars in timeline = leaks detected
- Click leak to see stack trace
- Examine objects that leaked
- Find allocation backtrace

### 3. Instruments - Allocations Template

**For tracking memory growth**:
1. Product → Profile (⌘I)
2. Select **Allocations** template
3. Record session
4. Navigate through app flows
5. Monitor "All Heap & Anonymous VM" graph
6. Look for continuous upward trend (bad)

**Mark Generation**:
```
1. Perform action (e.g., open screen)
2. Click "Mark Generation" in Allocations
3. Go back/close screen
4. Click "Mark Generation" again
5. Check "Growth" column
6. Should be near zero (small fluctuations OK)
```

### 4. SwiftUI View Lifecycle Logging

```swift
// Add to your views for debugging
struct MyView: View {
    init() {
        print("✅ MyView created")
    }

    var body: some View {
        Text("Hello")
            .onAppear {
                print("✅ MyView appeared")
            }
            .onDisappear {
                print("✅ MyView disappeared")
            }
    }
}

class MyViewModel: ObservableObject {
    init() {
        print("✅ MyViewModel created")
    }

    deinit {
        print("✅ MyViewModel deinitialized")
    }
}
```

---

## Fixing Common Patterns

### Pattern 1: SwiftUI with ObservableObject

```swift
// GOOD - Proper lifecycle
class MyViewModel: ObservableObject {
    @Published var data: [String] = []
    private var cancellables = Set<AnyCancellable>()

    func fetchData() {
        URLSession.shared.dataTaskPublisher(for: someURL)
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { [weak self] data, _ in
                    self?.data = parseData(data)
                }
            )
            .store(in: &cancellables)
    }

    deinit {
        print("✅ MyViewModel deinitialized")
        cancellables.removeAll()
    }
}

struct MyView: View {
    @StateObject private var viewModel = MyViewModel()

    var body: some View {
        List(viewModel.data, id: \.self) { item in
            Text(item)
        }
        .onAppear {
            viewModel.fetchData()
        }
    }
}
```

### Pattern 2: Cleanup in onDisappear

```swift
struct TimerView: View {
    @State private var timer: Timer?
    @State private var count = 0

    var body: some View {
        Text("Count: \(count)")
            .onAppear {
                startTimer()
            }
            .onDisappear {
                stopTimer()  // IMPORTANT!
            }
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            count += 1
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
        print("✅ Timer cleaned up")
    }
}
```

### Pattern 3: Using Task with Cancellation

```swift
struct AsyncDataView: View {
    @State private var data: String = ""
    @State private var loadTask: Task<Void, Never>?

    var body: some View {
        Text(data)
            .onAppear {
                loadTask = Task {
                    data = await fetchData()
                }
            }
            .onDisappear {
                loadTask?.cancel()
                print("✅ Task cancelled")
            }
    }

    private func fetchData() async -> String {
        // Async work
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        return "Loaded"
    }
}
```

---

## Best Practices

### 1. Use Weak/Unowned References

- ✅ Use `[weak self]` in closures
- ✅ Use `weak` for delegate properties
- ✅ Use `unowned` only when guaranteed non-nil

### 2. Always Cleanup

```swift
// In views
.onDisappear {
    // Cancel timers
    // Cancel tasks
    // Remove observers
}

// In objects
deinit {
    // Invalidate timers
    // Cancel network requests
    // Remove observers
}
```

### 3. Use Combine for Async Work

```swift
// Auto-cleanup with cancellables
class MyViewModel: ObservableObject {
    private var cancellables = Set<AnyCancellable>()

    func loadData() {
        publisher
            .sink { [weak self] value in
                self?.process(value)
            }
            .store(in: &cancellables)
    }

    // Cancellables auto-cleanup on deinit
}
```

### 4. Prefer @StateObject over @ObservedObject

```swift
// GOOD - View owns the object
struct MyView: View {
    @StateObject private var viewModel = MyViewModel()
}

// Use @ObservedObject only for passed-in objects
struct ChildView: View {
    @ObservedObject var viewModel: MyViewModel
}
```

### 5. Test with Debug Memory Graph

```
Regular testing workflow:
1. Run app
2. Navigate to screen
3. Navigate back
4. Debug Memory Graph (⌘⇧M)
5. Verify 0 instances of your view/viewmodel
6. Fix any leaks found
7. Repeat
```

---

## Testing Checklist

When testing for leaks:

1. **Navigate flows**
   - Open screen → Go back → Check memory
   - Present modal → Dismiss → Check memory

2. **Rotate device**
   - Configuration changes can expose leaks

3. **Background/Foreground**
   - App lifecycle transitions

4. **Extended usage**
   - Use Allocations to monitor growth over time

5. **Profile before release**
   - Run Leaks instrument on full app flow

---

## Debugging Workflow

```
1. Notice memory growth or crashes
2. Profile → Allocations
3. Mark generation before/after action
4. Check growth column
5. If high growth:
   a. Profile → Leaks
   b. Look for red leak indicators
   c. Examine leak stack trace
   d. Find allocation source
6. Open Debug Memory Graph
7. Find leaked object
8. Inspect reference graph
9. Identify strong reference cycle
10. Fix by adding [weak self] or cleanup
11. Re-test to verify fix
```

---

## Common Mistakes

### Mistake 1: Forgetting onDisappear

```swift
// BAD
struct MyView: View {
    @State var timer: Timer?

    var body: some View {
        Text("Hello")
            .onAppear {
                timer = Timer.scheduledTimer(...)
            }
        // Missing: onDisappear cleanup!
    }
}
```

### Mistake 2: Strong Self in Async

```swift
// BAD
Task {
    await someWork()
    self.updateUI()  // Captures self strongly
}

// GOOD
Task { [weak self] in
    await someWork()
    self?.updateUI()
}
```

### Mistake 3: Not Testing Deinit

```swift
// Always add deinit logging during development
class MyViewModel: ObservableObject {
    deinit {
        print("✅ MyViewModel deinit - should print when dismissed!")
    }
}

// If deinit doesn't print = leak!
```

---

## Resources

- [Xcode Memory Debugger](https://developer.apple.com/documentation/xcode/gathering-information-about-memory-use)
- [Instruments User Guide](https://help.apple.com/instruments/mac/current/)
- [Swift ARC](https://docs.swift.org/swift-book/LanguageGuide/AutomaticReferenceCounting.html)

---

## Code Reference

See project example:
- `Modules/Feature/UI/Samples/Advanced/MemoryLeakDetectionView.swift`

Remember: **Prevention is easier than debugging! Always use [weak self] and cleanup resources.**

# Swift Closures and Capture Lists

Complete guide to Swift closures, capture lists, and memory management.

## What is a Closure?

A closure is a self-contained block of functionality that can be passed around and used in your code.

```swift
// Function
func greet() {
    print("Hello!")
}

// Closure (anonymous function)
let greetClosure = {
    print("Hello!")
}

greetClosure()  // Prints: Hello!
```

---

## Capturing Values

Closures can **capture** values from their surrounding context.

### Basic Capture (Reference)

```swift
func testBasicCapture() {
    var counter = 0

    let incrementCounter = {
        counter += 1  // Captures 'counter' by REFERENCE
        print("Counter: \(counter)")
    }

    incrementCounter()  // Counter: 1
    incrementCounter()  // Counter: 2

    print("Final counter: \(counter)")  // Final counter: 2
}
```

**What happens:**
- Closure captures `counter` by **reference**
- Changes inside closure affect original variable
- Changes outside closure affect closure's view

---

## Capture Lists - The Key Concept

### Problem: Capture by Reference

```swift
func testProblem() {
    var a = 900

    let closure = {
        // 'a' is captured by REFERENCE
        print("Inside closure: \(a)")
    }

    a = 1000  // Modify 'a' AFTER creating closure

    closure()  // Prints: Inside closure: 1000 ⚠️

    print("Outside closure: \(a)")  // Outside closure: 1000
}

testProblem()
```

**Output:**
```
Inside closure: 1000
Outside closure: 1000
```

**Why?** Closure captures `a` by **reference**, so it sees the latest value.

---

### Solution: Capture List [a]

```swift
func testCaptureList() {
    var a = 900

    // [a] forces the closure to COPY the value of 'a' right now
    let closure = { [a] in
        // 'a' is now a CONSTANT inside this closure (let constant)
        // It has the value 900 (captured at closure creation)
        let modifiedA = a + 50
        print("Inside closure: \(modifiedA)")
    }

    // Modify 'a' outside
    a = 1000

    // Call the closure
    closure()

    print("Outside closure after calling: \(a)")
}

testCaptureList()
```

**Output:**
```
Inside closure: 950
Outside closure after calling: 1000
```

**Why?**
- `[a]` creates a **copy** of `a` when closure is created
- Closure's copy has value `900`
- `900 + 50 = 950`
- Outside `a` is `1000` (unchanged by closure)

---

## How Capture Lists Work

### Without Capture List

```swift
var number = 10

let closure = {
    print(number)  // Captures by REFERENCE
}

number = 20
closure()  // Prints: 20 (sees latest value)
```

### With Capture List

```swift
var number = 10

let closure = { [number] in
    print(number)  // Captures by VALUE (copy)
}

number = 20
closure()  // Prints: 10 (original captured value)
```

---

## Capture List Syntax

```swift
{ [captureList] (parameters) -> ReturnType in
    // Body
}
```

### Examples:

```swift
// 1. Capture single value
{ [a] in
    print(a)
}

// 2. Capture multiple values
{ [a, b, c] in
    print(a, b, c)
}

// 3. Rename captured value
{ [capturedValue = someVariable] in
    print(capturedValue)
}

// 4. Weak reference (for classes)
{ [weak self] in
    self?.doSomething()
}

// 5. Unowned reference (for classes)
{ [unowned self] in
    self.doSomething()
}
```

---

## Value Types vs Reference Types

### Value Types (Structs, Enums, Primitives)

```swift
struct Counter {
    var count = 0
}

func testValueCapture() {
    var counter = Counter(count: 5)

    // Capture by VALUE (copy)
    let closure = { [counter] in
        print("Captured count: \(counter.count)")
    }

    counter.count = 100

    closure()  // Captured count: 5

    print("Outside count: \(counter.count)")  // Outside count: 100
}
```

**Result:** Closure has a **copy** of the struct.

---

### Reference Types (Classes)

```swift
class Person {
    var name: String
    init(name: String) { self.name = name }
}

func testReferenceCapture() {
    var person = Person(name: "Alice")

    // Capture by REFERENCE (even with capture list!)
    let closure = { [person] in
        print("Captured name: \(person.name)")
    }

    person.name = "Bob"

    closure()  // Captured name: Bob ⚠️

    print("Outside name: \(person.name)")  // Outside name: Bob
}
```

**Result:** Closure captures **reference** to same object!

---

## Memory Management: [weak self] and [unowned self]

### The Problem: Retain Cycles

```swift
class ViewController: UIViewController {
    var closure: (() -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()

        // ❌ BAD: Retain cycle!
        closure = {
            self.view.backgroundColor = .red
            // self → closure
            // closure → self
            // RETAIN CYCLE! ViewController never deallocated
        }
    }

    deinit {
        print("ViewController deallocated")  // NEVER CALLED!
    }
}
```

**Retain Cycle:**
```
ViewController → closure (strong)
      ↑              ↓
      └─────────────┘
         (strong)
```

---

### Solution 1: [weak self]

```swift
class ViewController: UIViewController {
    var closure: (() -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()

        // ✅ GOOD: No retain cycle
        closure = { [weak self] in
            // self is now Optional
            self?.view.backgroundColor = .red
        }
    }

    deinit {
        print("✅ ViewController deallocated")  // CALLED!
    }
}
```

**Use `[weak self]` when:**
- Closure might outlive the object
- You want object to be deallocated
- You're okay with self being nil

---

### Solution 2: [unowned self]

```swift
class ViewController: UIViewController {
    var closure: (() -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()

        // ⚠️ UNOWNED: No retain cycle, but self must exist
        closure = { [unowned self] in
            // self is NOT optional
            self.view.backgroundColor = .red
            // Crashes if ViewController is deallocated!
        }
    }
}
```

**Use `[unowned self]` when:**
- Closure and object have same lifetime
- You're SURE self will exist when closure runs
- You want non-optional self

**Warning:** Crashes if self is deallocated!

---

## Real-World Examples

### Example 1: Network Request

```swift
class RepositoryViewModel {
    var repositories: [Repository] = []

    func fetchRepositories() {
        // ❌ BAD: Retain cycle
        apiClient.fetch { data in
            self.repositories = parseData(data)
        }

        // ✅ GOOD: No retain cycle
        apiClient.fetch { [weak self] data in
            guard let self = self else { return }
            self.repositories = parseData(data)
        }
    }

    deinit {
        print("✅ ViewModel deallocated")
    }
}
```

---

### Example 2: Timer

```swift
class TimerViewController: UIViewController {
    var timer: Timer?

    func startTimer() {
        // ❌ BAD: Retain cycle
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.updateUI()
        }

        // ✅ GOOD: No retain cycle
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateUI()
        }
    }

    func updateUI() {
        print("UI updated")
    }

    deinit {
        timer?.invalidate()
        print("✅ TimerViewController deallocated")
    }
}
```

---

### Example 3: Animation Completion

```swift
class AnimationViewController: UIViewController {

    func animateView() {
        // ❌ BAD: Retain cycle
        UIView.animate(withDuration: 0.3, animations: {
            self.view.alpha = 0.5
        }, completion: { _ in
            self.view.alpha = 1.0
        })

        // ✅ GOOD: No retain cycle
        UIView.animate(withDuration: 0.3, animations: { [weak self] in
            self?.view.alpha = 0.5
        }, completion: { [weak self] _ in
            self?.view.alpha = 1.0
        })
    }
}
```

---

### Example 4: Dispatch Queue

```swift
class DataProcessor {
    var data: [String] = []

    func processData() {
        // ❌ BAD: Retain cycle
        DispatchQueue.global().async {
            let processed = self.heavyProcessing()
            DispatchQueue.main.async {
                self.data = processed
            }
        }

        // ✅ GOOD: No retain cycle
        DispatchQueue.global().async { [weak self] in
            guard let self = self else { return }
            let processed = self.heavyProcessing()

            DispatchQueue.main.async { [weak self] in
                self?.data = processed
            }
        }
    }

    func heavyProcessing() -> [String] {
        return ["processed"]
    }

    deinit {
        print("✅ DataProcessor deallocated")
    }
}
```

---

## Guard let self Pattern

### Common Pattern

```swift
class MyClass {
    func doWork() {
        performTask { [weak self] result in
            guard let self = self else { return }

            // Now 'self' is strong for rest of closure
            self.processResult(result)
            self.updateUI()
            self.saveData()
        }
    }
}
```

### Why guard let?

1. **Early exit** if self is nil
2. **Strong self** for rest of closure (prevents deallocation mid-execution)
3. **Cleaner code** (no optional chaining)

---

## Capture List Combinations

### Multiple Captures

```swift
class ViewController: UIViewController {
    var viewModel: ViewModel?
    var count = 0

    func setupClosure() {
        someClosure { [weak self, weak viewModel, count] in
            // self: Optional
            // viewModel: Optional
            // count: Value (copy)

            guard let self = self else { return }

            self.updateCount(count)
            viewModel?.refresh()
        }
    }
}
```

---

## Complete Example: Repository List

```swift
class RepositoryListViewController: UIViewController {

    var repositories: [Repository] = []
    var currentTask: URLSessionDataTask?

    func fetchRepositories() {
        currentTask = apiClient.fetch(endpoint: "/repos") { [weak self] result in
            // self is Optional
            guard let self = self else {
                print("ViewController deallocated, skipping update")
                return
            }

            switch result {
            case .success(let data):
                // Parse data
                let repos = try? JSONDecoder().decode([Repository].self, from: data)

                // Update on main thread
                DispatchQueue.main.async { [weak self] in
                    self?.repositories = repos ?? []
                    self?.tableView.reloadData()
                }

            case .failure(let error):
                print("Error: \(error)")
            }
        }
    }

    deinit {
        print("✅ ViewController deallocated")
        currentTask?.cancel()
    }
}
```

---

## Quick Reference

### When to use [weak self]

✅ Network requests
✅ Timers
✅ Animations
✅ Dispatch queues
✅ Closures stored as properties
✅ Delegate callbacks

### When to use [unowned self]

⚠️ Closure lifetime < object lifetime
⚠️ You're CERTAIN self exists
⚠️ You want non-optional self

**Warning:** Use sparingly, crashes if wrong!

### When NOT to use weak/unowned

✅ Short-lived closures (button actions)
✅ Closures not stored
✅ No circular reference

```swift
// ✅ No need for [weak self]
button.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)

// ✅ No need for [weak self]
[1, 2, 3].map { $0 * 2 }

// ❌ Need [weak self] - closure stored!
self.onComplete = {
    self.finish()  // Retain cycle!
}
```

---

## Testing for Memory Leaks

### Check if deinit is called

```swift
class TestViewController: UIViewController {
    var closure: (() -> Void)?

    func setup() {
        closure = { [weak self] in
            self?.doSomething()
        }
    }

    deinit {
        print("✅ TestViewController deallocated")
        // If this prints, no leak!
        // If this doesn't print, LEAK!
    }
}

// Test
var vc: TestViewController? = TestViewController()
vc?.setup()
vc = nil  // Should print deinit message
```

### Use Instruments

1. Open Instruments
2. Select "Leaks" template
3. Run your app
4. Look for red bars (memory leaks)

---

## Common Mistakes

### ❌ Mistake 1: Forgetting [weak self]

```swift
class MyClass {
    var closure: (() -> Void)?

    func setup() {
        closure = {
            self.doWork()  // ❌ Retain cycle!
        }
    }
}
```

### ❌ Mistake 2: Using self after guard

```swift
someTask { [weak self] in
    guard let self = self else { return }

    DispatchQueue.main.async {
        self.updateUI()  // ❌ 'self' is strong now, potential retain cycle in nested closure!
    }
}
```

**Fix:**
```swift
someTask { [weak self] in
    guard let self = self else { return }

    DispatchQueue.main.async { [weak self] in  // ✅ weak again
        self?.updateUI()
    }
}
```

### ❌ Mistake 3: Unnecessary weak

```swift
// ❌ Unnecessary - no retain cycle
[1, 2, 3].forEach { [weak self] num in
    self?.print(num)
}

// ✅ Correct - no weak needed
[1, 2, 3].forEach { num in
    self.print(num)
}
```

---

## Summary

| Concept | Syntax | Behavior |
|---------|--------|----------|
| **No capture list** | `{ self.doWork() }` | Captures by reference (strong) |
| **Value capture** | `{ [a] in print(a) }` | Copies value at closure creation |
| **Weak self** | `{ [weak self] in self?.doWork() }` | Optional, prevents retain cycle |
| **Unowned self** | `{ [unowned self] in self.doWork() }` | Non-optional, crashes if nil |
| **Guard let** | `guard let self = self else { return }` | Strong self for rest of closure |

---

## Best Practices

### ✅ Do's

1. **Use [weak self] for stored closures**
   ```swift
   self.onComplete = { [weak self] in
       self?.finish()
   }
   ```

2. **Guard let pattern for safety**
   ```swift
   apiClient.fetch { [weak self] data in
       guard let self = self else { return }
       self.process(data)
   }
   ```

3. **Test with deinit**
   ```swift
   deinit {
       print("✅ Deallocated")
   }
   ```

### ❌ Don'ts

1. **Don't forget weak in network requests**
2. **Don't use unowned unless certain**
3. **Don't create unnecessary retain cycles**

---

## See Also

- [Memory Leak Detection](../advanced/memory_leak_detection.md)
- [ViewController Lifecycle](../beginner/lifecycle_viewcontroller.md)
- [SwiftUI View Lifecycle](../beginner/lifecycle_swiftui_view.md)

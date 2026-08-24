# SwiftUI State Management: @State, @Binding, @StateObject, @ObservedObject

## Overview

State management is the foundation of reactive UI in SwiftUI. Understanding the different property wrappers (@State, @Binding, @StateObject, @ObservedObject, @EnvironmentObject) and when to use each is critical for building robust SwiftUI applications.

## 📁 Code Examples in Project

**Complete working example:** [`Modules/Feature/UI/Samples/Beginner/StatePropertyWrappersView.swift`](../../../../github_repo_search_iOS_app/Modules/Feature/UI/Samples/Beginner/StatePropertyWrappersView.swift)

This file demonstrates:
- ✅ @State for local mutable state
- ✅ @Binding for two-way data flow
- ✅ @StateObject vs @ObservedObject
- ✅ State hoisting patterns
- ✅ Interactive examples with counters, toggles, forms

**Real usage in production code:**
- `Modules/Feature/UI/Home/View/HomeView.swift:14` - `@State private var homeViewModel = HomeViewModel()`
- `Modules/Feature/UI/Settings/View/SettingsView.swift` - `@AppStorage` for persistent settings
- `Modules/Feature/UI/Favorites/View/FavoritesView.swift` - `@State` for UI state
- `Modules/Feature/UI/UserSearch/View/UserSearchView.swift` - `@State` with ViewModels

## Why It Matters

- Most frequently asked SwiftUI technical topic
- Core concept for all reactive UI development
- Understanding this prevents common bugs and memory leaks
- Essential for data flow in SwiftUI applications
- Fundamental to the SwiftUI architecture

## Key Concepts

### 1. @State - Local View State

**What it is:**
- Property wrapper for simple value types owned by the view
- SwiftUI manages storage and lifecycle
- View automatically updates when state changes
- Should be private to the view

**When to use:**
- Simple local UI state (toggles, text fields, counters)
- Value types (Bool, Int, String, structs)
- State that doesn't need to be shared
- Temporary UI state

**Example:**
```swift
struct CounterView: View {
    @State private var count = 0

    var body: some View {
        VStack {
            Text("Count: \(count)")
            Button("Increment") {
                count += 1  // View updates automatically
            }
        }
    }
}
```

**How it works:**
```
User taps button
  → count changes
  → @State detects change
  → View re-renders
  → UI updates
```

### 2. @Binding - Two-Way Data Flow

**What it is:**
- Reference to another view's @State
- Creates two-way connection
- Child view can read AND write parent's state
- Denoted with $ prefix

**When to use:**
- Passing mutable state to child views
- Creating reusable components
- Form inputs that update parent state
- Shared UI controls

**Example:**
```swift
struct ParentView: View {
    @State private var isOn = false

    var body: some View {
        VStack {
            Text("Switch is \(isOn ? "ON" : "OFF")")
            ToggleButton(isOn: $isOn)  // Pass binding with $
        }
    }
}

struct ToggleButton: View {
    @Binding var isOn: Bool  // Receive binding

    var body: some View {
        Button(isOn ? "Turn OFF" : "Turn ON") {
            isOn.toggle()  // Modifies parent's state
        }
    }
}
```

**Data Flow:**
```
ParentView (@State)
    ↓ passes $isOn
ToggleButton (@Binding)
    ↓ modifies binding
ParentView state updates
    ↓
Both views re-render
```

### 3. @StateObject - Observable Object Ownership

**What it is:**
- Property wrapper for ObservableObject instances
- View owns and manages object's lifecycle
- Object persists across view updates
- Use when view creates the object

**When to use:**
- Creating ViewModel instances
- Object with complex business logic
- When view owns the data source
- First time object is created in view hierarchy

**Example:**
```swift
class CounterViewModel: ObservableObject {
    @Published var count = 0

    func increment() {
        count += 1
    }
}

struct CounterView: View {
    @StateObject private var viewModel = CounterViewModel()

    var body: some View {
        VStack {
            Text("Count: \(viewModel.count)")
            Button("Increment") {
                viewModel.increment()
            }
        }
    }
}
```

**Lifecycle:**
```
View created
  → @StateObject creates ViewModel (once)
View updates (parent re-renders)
  → @StateObject preserves same instance
  → @Published properties trigger UI updates
View destroyed
  → ViewModel deallocated
```

### 4. @ObservedObject - Shared Observable Object

**What it is:**
- Property wrapper for externally-owned ObservableObject
- Does NOT own the object
- View observes changes but doesn't manage lifecycle
- Object created elsewhere and passed in

**When to use:**
- ViewModel passed from parent
- Shared data between views
- Dependency-injected objects
- Objects created outside the view

**Example:**
```swift
struct ParentView: View {
    @StateObject private var viewModel = SharedViewModel()

    var body: some View {
        VStack {
            ChildViewA(viewModel: viewModel)  // Pass to child
            ChildViewB(viewModel: viewModel)  // Same instance
        }
    }
}

struct ChildViewA: View {
    @ObservedObject var viewModel: SharedViewModel  // Doesn't own

    var body: some View {
        Text("Count: \(viewModel.count)")
    }
}
```

**Data Flow:**
```
ParentView creates ViewModel (@StateObject)
    ↓
ChildViewA observes (@ObservedObject)
ChildViewB observes (@ObservedObject)
    ↓
ViewModel changes
    ↓
All observing views update
```

### 5. @EnvironmentObject - Dependency Injection

**What it is:**
- Global-like object accessible throughout view hierarchy
- Injected at root and available to descendants
- Alternative to passing through every view
- Must be provided or app crashes

**When to use:**
- App-wide settings or theme
- User authentication state
- Deep view hierarchies
- Avoid prop drilling

**Example:**
```swift
class AppSettings: ObservableObject {
    @Published var isDarkMode = false
}

@main
struct MyApp: App {
    @StateObject private var settings = AppSettings()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(settings)  // Inject here
        }
    }
}

struct DeepChildView: View {
    @EnvironmentObject var settings: AppSettings  // Access directly

    var body: some View {
        Toggle("Dark Mode", isOn: $settings.isDarkMode)
    }
}
```

**Data Flow:**
```
Root injects .environmentObject(settings)
    ↓
Any descendant view can access via @EnvironmentObject
    ↓
No need to pass through intermediate views
```

### 6. @Published - Observable Property

**What it is:**
- Property wrapper for ObservableObject properties
- Publishes changes to observers
- Triggers view updates automatically
- Works with Combine framework

**Example:**
```swift
class UserViewModel: ObservableObject {
    @Published var username = ""
    @Published var isLoggedIn = false

    func login() {
        isLoggedIn = true  // Automatically notifies observers
    }
}
```

## Decision Matrix: Which to Use?

```
┌─────────────────────────────────────────────────────────┐
│ Does the view CREATE and OWN the object?               │
│   YES → Use @StateObject                               │
│   NO  → Continue...                                     │
└─────────────────────────────────────────────────────────┘
                       ↓
┌─────────────────────────────────────────────────────────┐
│ Is it a simple value type (Bool, Int, String)?         │
│   YES → Use @State                                      │
│   NO  → Continue...                                     │
└─────────────────────────────────────────────────────────┘
                       ↓
┌─────────────────────────────────────────────────────────┐
│ Is it passed from parent and needs to be modified?     │
│   YES → Use @Binding                                    │
│   NO  → Continue...                                     │
└─────────────────────────────────────────────────────────┘
                       ↓
┌─────────────────────────────────────────────────────────┐
│ Is it injected globally in environment?                │
│   YES → Use @EnvironmentObject                         │
│   NO  → Use @ObservedObject                            │
└─────────────────────────────────────────────────────────┘
```

## Common Patterns

### Pattern 1: Parent-Child Communication

```swift
// Parent owns state
struct ParentView: View {
    @State private var text = ""

    var body: some View {
        VStack {
            Text("You typed: \(text)")
            ChildTextField(text: $text)  // Two-way binding
        }
    }
}

// Child modifies parent's state
struct ChildTextField: View {
    @Binding var text: String

    var body: some View {
        TextField("Enter text", text: $text)
    }
}
```

### Pattern 2: ViewModel Architecture

```swift
// ViewModel with business logic
class UserProfileViewModel: ObservableObject {
    @Published var user: User?
    @Published var isLoading = false

    func loadUser() async {
        isLoading = true
        // API call
        isLoading = false
    }
}

// View owns ViewModel
struct UserProfileView: View {
    @StateObject private var viewModel = UserProfileViewModel()

    var body: some View {
        if viewModel.isLoading {
            ProgressView()
        } else if let user = viewModel.user {
            Text(user.name)
        }
    }
}
```

### Pattern 3: Shared State

```swift
class CartManager: ObservableObject {
    @Published var items: [Item] = []

    func addItem(_ item: Item) {
        items.append(item)
    }
}

struct ParentView: View {
    @StateObject private var cart = CartManager()  // Create once

    var body: some View {
        VStack {
            ProductListView(cart: cart)
            CartView(cart: cart)
        }
    }
}

struct ProductListView: View {
    @ObservedObject var cart: CartManager  // Observe shared instance

    var body: some View {
        Button("Add to Cart") {
            cart.addItem(product)
        }
    }
}

struct CartView: View {
    @ObservedObject var cart: CartManager  // Same instance

    var body: some View {
        Text("Items: \(cart.items.count)")
    }
}
```

## Common Mistakes

### Mistake 1: Using @ObservedObject Instead of @StateObject

```swift
// WRONG - Creates new instance on every re-render
struct MyView: View {
    @ObservedObject var viewModel = ViewModel()  // BAD!

    var body: some View {
        Text("\(viewModel.count)")
    }
}

// CORRECT - Preserves instance across re-renders
struct MyView: View {
    @StateObject private var viewModel = ViewModel()  // GOOD!

    var body: some View {
        Text("\(viewModel.count)")
    }
}
```

**Why it matters:**
- @ObservedObject creates new instance every time parent re-renders
- State is lost
- Memory leak potential
- Performance issues

### Mistake 2: Forgetting $ for Binding

```swift
// WRONG
ChildView(isOn: isOn)  // Passes value, not binding

// CORRECT
ChildView(isOn: $isOn)  // Passes binding
```

### Mistake 3: Making @State Public

```swift
// WRONG - State should be private
struct MyView: View {
    @State var count = 0  // BAD!

    var body: some View {
        Text("\(count)")
    }
}

// CORRECT
struct MyView: View {
    @State private var count = 0  // GOOD!

    var body: some View {
        Text("\(count)")
    }
}
```

### Mistake 4: Not Using @MainActor with ObservableObject

```swift
// GOOD PRACTICE
@MainActor
class UserViewModel: ObservableObject {
    @Published var user: User?

    func loadUser() async {
        // API call
        user = fetchedUser  // Safe on main thread
    }
}
```

## Best Practices

1. **Always use @StateObject for ownership**
   ```swift
   @StateObject private var viewModel = ViewModel()
   ```

2. **Keep @State private**
   ```swift
   @State private var isShowing = false
   ```

3. **Use @Binding for child view inputs**
   ```swift
   struct ChildView: View {
       @Binding var text: String
   }
   ```

4. **Prefer @StateObject over @ObservedObject for creation**
   - @StateObject when view creates it
   - @ObservedObject when passed from parent

5. **Use @EnvironmentObject sparingly**
   - Only for truly global state
   - Prefer explicit passing for testability

6. **Mark ObservableObject classes with @MainActor**
   ```swift
   @MainActor
   class ViewModel: ObservableObject { }
   ```

7. **Use @Published for observable properties**
   ```swift
   @Published var items: [Item] = []
   ```

## Memory Management

### Reference Counting

```swift
class MyViewModel: ObservableObject {
    @Published var data: String = ""

    init() {
        print("ViewModel created")
    }

    deinit {
        print("ViewModel destroyed")
    }
}

struct MyView: View {
    @StateObject private var viewModel = MyViewModel()

    var body: some View {
        Text(viewModel.data)
    }
}

// Lifecycle:
// View appears → "ViewModel created"
// View disappears → "ViewModel destroyed"
```

### Retain Cycles

```swift
// PROBLEM - Retain cycle
class ViewModel: ObservableObject {
    var closure: (() -> Void)?

    init() {
        closure = {
            self.doSomething()  // Strong reference to self
        }
    }
}

// SOLUTION - Weak capture
class ViewModel: ObservableObject {
    var closure: (() -> Void)?

    init() {
        closure = { [weak self] in
            self?.doSomething()  // Weak reference
        }
    }
}
```

### Q1: Should I use `@State` or `@StateObject` with a ViewModel?
**Answer:**
* **Modern iOS 17+ (Swift Observation Framework — Recommended):**  
  When your ViewModel uses the `@Observable` macro:
  ```swift
  @Observable @MainActor class HomeViewModel { ... }
  ```
  👉 **ALWAYS USE `@State`:**
  ```swift
  struct HomeView: View {
      @State private var homeViewModel = HomeViewModel() // ✅ Correct for @Observable
  }
  ```
  In iOS 17+, Apple redesigned `@State` to directly manage the lifecycle of reference types (`class`) that use `@Observable`. `@StateObject` is deprecated for `@Observable` classes! (See [Apple Developer: Migrating from ObservableObject to @Observable](https://developer.apple.com/documentation/swiftui/migrating-from-the-observable-object-protocol-to-the-observable-macro)).

* **Legacy iOS 13–16 (Combine-based):**  
  When your ViewModel conforms to `ObservableObject` and uses `@Published`:
  ```swift
  class HomeViewModel: ObservableObject { @Published var data = "" }
  ```
  👉 **MUST USE `@StateObject`:**
  ```swift
  struct HomeView: View {
      @StateObject private var homeViewModel = HomeViewModel() // Legacy iOS 13-16
  }
  ```

---

### Q2: When should you use @StateObject vs @ObservedObject? (Legacy iOS 13-16)
**Answer:**
- @StateObject when the view creates and owns the object
- @ObservedObject when the object is created elsewhere and passed in
- @StateObject creates once, @ObservedObject can create multiple times if parent re-renders

### Q3: How does @Binding work?
**Answer:**
- @Binding creates a two-way connection to another view's @State
- Changes in child view update parent's state
- Changes in parent state update child view
- Use $ prefix to pass binding: $myState

### Q4: What is @Published and how does it work?
**Answer:**
- Property wrapper that publishes changes to ObservableObject observers
- When property changes, all views observing the object update
- Works with Combine framework
- Triggers re-render automatically

### Q5: Explain the data flow with @EnvironmentObject
**Answer:**
- Object injected at root using .environmentObject()
- Any descendant can access with @EnvironmentObject
- Avoids passing through intermediate views
- App crashes if not provided in hierarchy

### Q6: What happens if you use @ObservedObject instead of @StateObject for a view-owned object?
**Answer:**
- New instance created on every parent re-render
- State is lost
- Potential memory leaks
- Performance degradation
- Use @StateObject for view-owned objects

### Q7: How do you prevent retain cycles in ObservableObject?
**Answer:**
```swift
class ViewModel: ObservableObject {
    var closure: (() -> Void)?

    init() {
        closure = { [weak self] in  // Use [weak self]
            self?.doSomething()
        }
    }
}
```

### Q8: What's the difference between @State and @Binding?
**Answer:**
- @State owns the value, @Binding references someone else's @State
- @State is source of truth, @Binding is a reference
- @State is private, @Binding is passed from parent
- Use $ to convert @State to Binding

## Related Topics

- [Swift Optionals](./swift_optionals.md) - Understanding optional binding
- [Structs vs Classes](./structs_vs_classes.md) - When to use value vs reference types
- [View Modifiers](./view_modifiers_order.md) - How state affects rendering
- [Property Wrappers](../intermediate/property_wrappers.md) - Advanced property wrapper patterns
- [Combine Framework](../intermediate/combine_basics.md) - Reactive programming with Combine
- [Memory Management](../intermediate/arc_memory.md) - ARC and retain cycles

## Further Reading

- [Apple SwiftUI Documentation - State and Data Flow](https://developer.apple.com/documentation/swiftui/state-and-data-flow)
- [WWDC 2020 - Data Essentials in SwiftUI](https://developer.apple.com/videos/play/wwdc2020/10040/)
- [Hacking with Swift - Understanding @State](https://www.hackingwithswift.com/quick-start/swiftui/understanding-state)
- [Swift by Sundell - State Management in SwiftUI](https://www.swiftbysundell.com/articles/swiftui-state-management-guide/)

---

**Last Updated:** 2026-08-16
**Difficulty:** Beginner to Intermediate
**Estimated Reading Time:** 20 minutes
**Prerequisites:** Basic SwiftUI knowledge

---

## Quick Reference Card

```
┌──────────────────┬──────────────────┬─────────────────────┐
│ Property Wrapper │ Use Case         │ Example             │
├──────────────────┼──────────────────┼─────────────────────┤
│ @State           │ Local UI state   │ @State var count=0  │
│ @Binding         │ Parent state ref │ @Binding var isOn   │
│ @StateObject     │ Create ViewModel │ @StateObject var vm │
│ @ObservedObject  │ Passed ViewModel │ @ObservedObject vm  │
│ @EnvironmentObj  │ Global injection │ @EnvironmentObject  │
│ @Published       │ Observable prop  │ @Published var data │
└──────────────────┴──────────────────┴─────────────────────┘
```

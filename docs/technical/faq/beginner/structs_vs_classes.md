# Structs vs Classes in Swift

## Overview

One of the most important design decisions in Swift is choosing between structs and classes. Swift encourages the use of structs (value types) over classes (reference types) for most use cases, which is different from many other object-oriented languages.

**Key Concept**: Structs are value types (copied when passed around), while classes are reference types (shared when passed around).

## Why It Matters

Understanding structs vs classes is essential because:
- **Fundamental Design Decision**: Affects how your data behaves throughout your app
- **Performance**: Value types can be more efficient in many cases
- **Thread Safety**: Value types are inherently thread-safe
- **SwiftUI**: All SwiftUI views are structs
- **Technical Essential**: Asked in 100% of iOS technical assessments

> "One of the most common technical questions covers the difference between struct and class (memory, mutability, reference vs. value semantics)" - Top iOS Technical Questions 2025

## Key Concepts

### Comprehensive Comparison Table

| Feature | Struct (Value Type) | Class (Reference Type) |
|---------|-------------------|----------------------|
| **Type** | Value type | Reference type |
| **Memory** | Stack (usually) | Heap |
| **Passing** | Creates a copy | Shares reference |
| **Inheritance** | ❌ No | ✅ Yes |
| **Protocol Conformance** | ✅ Yes | ✅ Yes |
| **Deinitializers** | ❌ No | ✅ Yes (deinit) |
| **Identity Operator** | ❌ No (==) | ✅ Yes (===) |
| **Mutability** | Immutable by default | Always mutable |
| **Thread Safety** | Safer (copy semantics) | Requires synchronization |
| **ARC** | ❌ Not needed | ✅ Reference counted |
| **Memberwise Init** | ✅ Automatic | ❌ Must implement |
| **SwiftUI Views** | ✅ Required | ❌ Not allowed |

### 1. Value Semantics (Structs)

When you assign or pass a struct, you get an independent copy:

```swift
struct Point {
    var x: Int
    var y: Int
}

var point1 = Point(x: 10, y: 20)
var point2 = point1  // Creates a COPY

point2.x = 30

print(point1.x)  // 10 - unchanged
print(point2.x)  // 30 - modified
```

### 2. Reference Semantics (Classes)

When you assign or pass a class, you get a reference to the same instance:

```swift
class User {
    var name: String
    init(name: String) { self.name = name }
}

let user1 = User(name: "Alice")
let user2 = user1  // Both reference the SAME instance

user2.name = "Bob"

print(user1.name)  // "Bob" - also changed!
print(user2.name)  // "Bob"
```

### 3. Memory Allocation

**Structs** (Stack):
- Allocated on the stack (fast)
- Automatically deallocated when out of scope
- No memory management overhead

**Classes** (Heap):
- Allocated on the heap (slower)
- Requires ARC for memory management
- Additional overhead for reference counting

### 4. Mutability

**Structs**:
```swift
struct Point {
    var x: Int
    var y: Int

    // Must mark as mutating
    mutating func moveBy(dx: Int, dy: Int) {
        x += dx
        y += dy
    }
}

let point = Point(x: 0, y: 0)
// point.moveBy(dx: 5, dy: 5)  // Error! 'point' is immutable (let)

var mutablePoint = Point(x: 0, y: 0)
mutablePoint.moveBy(dx: 5, dy: 5)  // ✅ Works with var
```

**Classes**:
```swift
class User {
    var name: String
    init(name: String) { self.name = name }
}

let user = User(name: "Alice")
user.name = "Bob"  // ✅ Works! The reference is constant, not the properties
```

## Code Examples

### Example 1: SwiftUI Views (Always Structs)

```swift
import SwiftUI

// SwiftUI views MUST be structs
struct ProfileView: View {
    let user: User

    var body: some View {
        VStack {
            Text(user.name)
            Text(user.email)
        }
    }
}

// This would be an error:
// class ProfileView: View { }  // ❌ Error: Class cannot conform to View
```

### Example 2: Model Objects

```swift
// Value-type model (preferred for simple data)
struct Article {
    var title: String
    var author: String
    var publishDate: Date
    var content: String
}

// Reference-type model (when you need identity/sharing)
class AppSettings {
    var isDarkMode: Bool
    var fontSize: Int

    init(isDarkMode: Bool = false, fontSize: Int = 14) {
        self.isDarkMode = isDarkMode
        self.fontSize = fontSize
    }
}

// Shared settings across app
let settings = AppSettings()
```

### Example 3: Copy-on-Write Behavior

```swift
struct User {
    var name: String
    var friends: [String]
}

var user1 = User(name: "Alice", friends: ["Bob", "Charlie"])
var user2 = user1

// Arrays use copy-on-write optimization
// No copy until modification
user2.friends.append("David")  // Now a copy is made

print(user1.friends.count)  // 2
print(user2.friends.count)  // 3
```

### Example 4: Identity vs Equality

```swift
class Person {
    var name: String
    init(name: String) { self.name = name }
}

let person1 = Person(name: "Alice")
let person2 = Person(name: "Alice")
let person3 = person1

// Reference equality (same instance?)
print(person1 === person2)  // false (different instances)
print(person1 === person3)  // true (same instance)

// Structs only have value equality
struct Point {
    var x: Int
    var y: Int
}

let point1 = Point(x: 1, y: 2)
let point2 = Point(x: 1, y: 2)

// point1 === point2  // ❌ Error: === only for classes
print(point1 == point2)  // true (if Point conforms to Equatable)
```

### Example 5: ViewModel Pattern (Class)

```swift
import SwiftUI

// ViewModels are classes because:
// 1. Need to be shared between views
// 2. Need reference semantics
// 3. Use @Published for reactive updates
class ProfileViewModel: ObservableObject {
    @Published var user: User
    @Published var isLoading = false

    init(user: User) {
        self.user = user
    }

    func updateProfile(name: String) {
        isLoading = true
        // API call...
        user.name = name
        isLoading = false
    }
}

// User data is a struct
struct User {
    var name: String
    var email: String
}
```

## When to Use Which

### Use Structs When:

✅ **Default Choice** - Prefer structs unless you have a specific reason for a class

✅ **Simple Data Models**
```swift
struct Product {
    var name: String
    var price: Double
    var category: String
}
```

✅ **SwiftUI Views** (Required)
```swift
struct ContentView: View {
    var body: some View {
        Text("Hello")
    }
}
```

✅ **Value Semantics Needed**
```swift
struct Coordinate {
    var latitude: Double
    var longitude: Double
}

var coord1 = Coordinate(latitude: 40.7, longitude: -74.0)
var coord2 = coord1  // Independent copy
```

✅ **Thread Safety Important**
```swift
// Structs are thread-safe by default
struct Settings {
    var fontSize: Int
    var isDarkMode: Bool
}
```

### Use Classes When:

✅ **Need Inheritance**
```swift
class Vehicle {
    var wheels: Int
    init(wheels: Int) { self.wheels = wheels }
}

class Car: Vehicle {
    var doors: Int
    init(doors: Int) {
        self.doors = doors
        super.init(wheels: 4)
    }
}
```

✅ **Need Reference Semantics / Shared State**
```swift
// Shared app-wide settings
class AppState {
    var isLoggedIn = false
    var currentUser: User?
}

let appState = AppState()  // Single shared instance
```

✅ **ViewModels** (ObservableObject)
```swift
class UserViewModel: ObservableObject {
    @Published var users: [User] = []

    func fetchUsers() {
        // API call
    }
}
```

✅ **Need Deinitializers**
```swift
class DatabaseConnection {
    init() {
        // Open connection
    }

    deinit {
        // Clean up resources
        print("Closing database connection")
    }
}
```

✅ **Interoperability with Objective-C**
```swift
// Must be a class to expose to Objective-C
@objc class LegacyManager: NSObject {
    @objc func doSomething() { }
}
```

## Common Mistakes

### 1. Using Classes When Structs Are Better
```swift
// Bad ❌ - Unnecessary class for simple data
class Point {
    var x: Int
    var y: Int
    init(x: Int, y: Int) {
        self.x = x
        self.y = y
    }
}

// Good ✅ - Struct for simple value
struct Point {
    var x: Int
    var y: Int
}
```

### 2. Forgetting `mutating` Keyword
```swift
struct Counter {
    var count = 0

    // Bad ❌ - Missing mutating
    func increment() {
        count += 1  // Error!
    }

    // Good ✅
    mutating func increment() {
        count += 1
    }
}
```

### 3. Unexpected Reference Sharing
```swift
class Settings {
    var fontSize: Int = 14
}

let settings1 = Settings()
let settings2 = settings1  // Sharing reference!

settings2.fontSize = 20
print(settings1.fontSize)  // 20 - Surprise! ⚠️
```

### 4. Using Struct for ObservableObject
```swift
// Bad ❌ - Cannot use struct
struct UserViewModel: ObservableObject {  // Error!
    @Published var name = ""
}

// Good ✅ - Use class
class UserViewModel: ObservableObject {
    @Published var name = ""
}
```

### 5. Not Understanding Copy-on-Write
```swift
var array1 = [1, 2, 3]
var array2 = array1  // Not actually copied yet!

// Copy happens only on modification
array2.append(4)  // Now copied

// This is efficient, but can be confusing
```

## Best Practices

### 1. Default to Structs
```swift
// Start with struct
struct User {
    var name: String
    var email: String
}

// Only use class if you need specific class features
```

### 2. Make Structs Immutable When Possible
```swift
// Prefer immutable properties
struct User {
    let id: UUID
    let name: String
    var email: String  // Only mutable if needed
}
```

### 3. Use Value Types for Models
```swift
// Models should typically be structs
struct Product {
    let id: Int
    let name: String
    let price: Double
}
```

### 4. Use Classes for Managers and Services
```swift
// Services are typically classes (shared, lifecycle)
class NetworkManager {
    static let shared = NetworkManager()
    private init() {}

    func fetchData() async throws -> Data {
        // ...
    }
}
```

### 5. Consider Protocol-Oriented Design
```swift
protocol Drawable {
    func draw()
}

// Both structs and classes can conform
struct Circle: Drawable {
    func draw() { }
}

class Rectangle: Drawable {
    func draw() { }
}
```

## Technical Questions

### Basic Questions

**Q1: What's the main difference between struct and class?**
> Structs are value types (copied when assigned) while classes are reference types (shared when assigned). Structs are allocated on the stack, classes on the heap.

**Q2: Why does SwiftUI use structs for views?**
> SwiftUI views are immutable value types that describe the UI at a point in time. This makes it easy for SwiftUI to compare views and efficiently update only what changed.

**Q3: Can structs inherit from other structs?**
> No, structs don't support inheritance. Only classes support inheritance. However, both can conform to protocols.

**Q4: Do structs use ARC?**
> No, structs are value types and don't need reference counting. Only classes use ARC.

**Q5: What's the mutating keyword for?**
> Methods in a struct that modify its properties must be marked with `mutating`. This signals that the method changes the struct's state.

### Intermediate Questions

**Q6: What is copy-on-write and which types use it?**
> Copy-on-write is an optimization where collections (Array, Dictionary, Set) delay copying until modification. This makes passing large collections efficient while maintaining value semantics.

**Q7: How do you check if two class instances are the same?**
> Use the identity operator `===` to check if two variables reference the same instance. Use `==` to check value equality.

**Q8: What are the performance implications of choosing struct vs class?**
> Structs are generally faster for small types (stack allocation, no ARC overhead). Classes are better for large types that would be expensive to copy. Classes have reference counting overhead.

**Q9: Can you have a struct inside a class or vice versa?**
> Yes, you can nest structs in classes and classes in structs. The containing type's semantics (value/reference) apply to the whole.

**Q10: What happens to a class property in a struct?**
> The struct still has value semantics, but its class property is a reference. Copying the struct creates a new struct that references the same class instance.

## Real-World Scenarios

### Scenario 1: User Profile (Struct)
```swift
// User data - simple value type
struct UserProfile {
    let id: UUID
    var name: String
    var email: String
    var avatar: URL?
}
```

### Scenario 2: Network Manager (Class)
```swift
// Shared service - needs to be a class
class NetworkManager {
    static let shared = NetworkManager()
    private init() {}

    private var session: URLSession = .shared

    func request<T: Codable>(_ endpoint: String) async throws -> T {
        // Network call
    }
}
```

### Scenario 3: SwiftUI View (Struct)
```swift
struct ProductCard: View {
    let product: Product  // Struct

    var body: some View {
        VStack {
            Text(product.name)
            Text("$\(product.price)")
        }
    }
}
```

### Scenario 4: ViewModel (Class)
```swift
class ProductListViewModel: ObservableObject {
    @Published var products: [Product] = []  // Array of structs
    @Published var isLoading = false

    func loadProducts() async {
        isLoading = true
        // Fetch products
        isLoading = false
    }
}
```

## Related Topics

- [Swift Optionals](./swift_optionals.md) - Optional struct and class properties
- [Memory Management](../intermediate/memory_management.md) - ARC for classes
- [SwiftUI State Management](./state_basics.md) - Value types in SwiftUI
- [Property Wrappers](../intermediate/property_wrappers.md) - @StateObject vs @ObservedObject

## Further Reading

- [Apple Swift Language Guide - Structures and Classes](https://docs.swift.org/swift-book/LanguageGuide/ClassesAndStructures.html)
- [Swift by Sundell - Value and Reference Types](https://www.swiftbysundell.com/articles/value-and-reference-types-in-swift/)
- [WWDC - Protocol-Oriented Programming](https://developer.apple.com/videos/play/wwdc2015/408/)

## Comparison with Other Languages

| Swift Struct | Kotlin Data Class | Java Record |
|-------------|------------------|-------------|
| Value type | Reference type | Reference type |
| Stack allocation | Heap allocation | Heap allocation |
| No inheritance | No inheritance | No inheritance |
| Immutable by default | Can be mutable | Immutable |
| Copy semantics | Reference semantics | Reference semantics |

Note: Kotlin's data classes are reference types despite being similar to Swift structs in usage.

---

**Level**: Beginner
**Estimated Time to Master**: 2-3 days
**Prerequisites**: Basic Swift syntax, [Optionals](./swift_optionals.md)
**Next Topic**: [View Modifiers Order](./view_modifiers_order.md)

---

*Last Updated: 2026-08-15*
*iOS Version: iOS 15+*
*Swift Version: Swift 5.5+*

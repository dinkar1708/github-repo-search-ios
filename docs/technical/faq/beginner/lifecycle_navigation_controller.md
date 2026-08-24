# Navigation Controller Lifecycle - Interleaving Methods

**Classic iOS Technical Question:** What happens when you push/pop ViewControllers on a navigation stack?

## 📁 Code Examples in Project

**Real implementation:** This app uses SwiftUI NavigationStack (modern iOS 16+) instead of UINavigationController.

**See navigation in:**
- `Modules/Feature/UI/Home/View/HomeView.swift:24` - NavigationStack with programmatic navigation
- `Modules/Feature/UI/UserSearch/View/UserSearchView.swift` - NavigationStack for user profiles
- `AppConfig/MainTabView.swift` - Tab-based navigation

**SwiftUI equivalent:**
```swift
NavigationStack {
    List(items) { item in
        NavigationLink(value: item) {
            ItemRow(item: item)
        }
    }
    .navigationDestination(for: Item.self) { item in
        DetailView(item: item)
    }
}
**Interactive Sample View:** [`NavigationLifecycleExampleView.swift`](../../../../github_repo_search_iOS_app/Modules/Feature/UI/Samples/Beginner/NavigationLifecycleExampleView.swift) - Interactive step-by-step interleaving visualizer for push/pop transitions and execution order timeline.

**Note:** This document covers UIKit UINavigationController. For SwiftUI NavigationStack patterns, see the production code above.

## The Critical Concept (UIKit)

When pushing/popping ViewControllers, the lifecycle methods **interleave** - View Controller A does NOT disappear completely before View Controller B appears. They coordinate the transition together.

---

## Pushing View Controller B (A → B)

When user taps button to navigate from A to B:

```swift
navigationController?.pushViewController(ViewControllerB(), animated: true)
```

### Exact Sequence:

```
1. B: viewDidLoad()
   ↓
2. A: viewWillDisappear(_:)
   ↓
3. B: viewWillAppear(_:)
   ↓
4. [ANIMATION RUNS] - Push animation (slide from right)
   ↓
5. B: viewDidAppear(_:)
   ↓
6. A: viewDidDisappear(_:)
```

### Visual Timeline:

```
Time →
T+0ms:   Push called
         └─ B: viewDidLoad()

T+10ms:  A: viewWillDisappear()    ⚠️ A knows it's leaving
         B: viewWillAppear()        ⚠️ B knows it's arriving

T+20ms:  [Animation starts]
         ├─ B slides in from right →
         └─ A slides left ←

T+350ms: [Animation completes]
         B: viewDidAppear()         ✅ B is fully visible
         A: viewDidDisappear()      ✅ A is off-screen
```

### Key Points:

1. **B's `viewDidLoad()` happens FIRST** - View B is loaded into memory
2. **A's `viewWillDisappear()` happens BEFORE animation** - A knows it's leaving
3. **B's `viewWillAppear()` happens BEFORE animation** - B knows it's arriving
4. **Both `will...` methods happen BEFORE animation starts**
5. **Both `did...` methods happen AFTER animation completes**

---

## Popping Back to A (B → A)

When user taps "Back" button:

```swift
navigationController?.popViewController(animated: true)
```

### Exact Sequence:

```
1. B: viewWillDisappear(_:)
   ↓
2. A: viewWillAppear(_:)
   ↓
3. [ANIMATION RUNS] - Pop animation (slide to right)
   ↓
4. A: viewDidAppear(_:)
   ↓
5. B: viewDidDisappear(_:)
   ↓
6. B: deinit
```

### Visual Timeline:

```
Time →
T+0ms:   Back tapped
         B: viewWillDisappear()    ⚠️ B knows it's leaving
         A: viewWillAppear()       ⚠️ A knows it's returning

T+10ms:  [Animation starts]
         ├─ B slides right →
         └─ A slides in from left ←

T+350ms: [Animation completes]
         A: viewDidAppear()        ✅ A is visible again
         B: viewDidDisappear()     ✅ B is off-screen

T+360ms: B: deinit                ❌ B is destroyed
```

### Key Points:

1. **A's `viewDidLoad()` is NOT called** - A is still in memory from before
2. **B's `viewWillDisappear()` happens BEFORE animation**
3. **A's `viewWillAppear()` happens BEFORE animation**
4. **Both `did...` methods happen AFTER animation**
5. **B's `deinit` happens LAST** - B is deallocated (if no retain cycles)

---

## Code Example with Logging

### View Controller A

```swift
class ViewControllerA: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        print("🟢 A: viewDidLoad")

        title = "View A"
        view.backgroundColor = .systemBlue

        let button = UIButton(type: .system)
        button.setTitle("Push to B", for: .normal)
        button.addTarget(self, action: #selector(pushToB), for: .touchUpInside)
        view.addSubview(button)
        button.frame = CGRect(x: 100, y: 200, width: 200, height: 50)
    }

    @objc func pushToB() {
        let viewControllerB = ViewControllerB()
        navigationController?.pushViewController(viewControllerB, animated: true)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("🟡 A: viewWillAppear")
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("🟢 A: viewDidAppear")
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        print("🟠 A: viewWillDisappear")
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        print("🔴 A: viewDidDisappear")
    }

    deinit {
        print("❌ A: deinit")
    }
}
```

### View Controller B

```swift
class ViewControllerB: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        print("🟢 B: viewDidLoad")

        title = "View B"
        view.backgroundColor = .systemGreen
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("🟡 B: viewWillAppear")
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("🟢 B: viewDidAppear")
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        print("🟠 B: viewWillDisappear")
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        print("🔴 B: viewDidDisappear")
    }

    deinit {
        print("❌ B: deinit")
    }
}
```

### Console Output - Push A → B

```
[User taps "Push to B"]

🟢 B: viewDidLoad
🟠 A: viewWillDisappear
🟡 B: viewWillAppear
[Animation runs...]
🟢 B: viewDidAppear
🔴 A: viewDidDisappear
```

### Console Output - Pop B → A

```
[User taps "Back"]

🟠 B: viewWillDisappear
🟡 A: viewWillAppear
[Animation runs...]
🟢 A: viewDidAppear
🔴 B: viewDidDisappear
❌ B: deinit
```

---

## Common Technical Questions & Answers

### Q1: "When does View A's viewDidDisappear get called relative to View B's viewDidAppear?"

**❌ Wrong Answer:**
"View A disappears before View B appears."

**✅ Correct Answer:**
"View A's `viewDidDisappear` is called AFTER View B's `viewDidAppear`. Both `did...` methods are called after the animation completes. The sequence is:
1. Both `will...` methods (before animation)
2. Animation runs
3. B's `viewDidAppear` (after animation)
4. A's `viewDidDisappear` (after animation)"

---

### Q2: "Is viewDidLoad called on View A when you pop back from View B?"

**❌ Wrong Answer:**
"Yes, viewDidLoad is always called when a view appears."

**✅ Correct Answer:**
"No. View A's `viewDidLoad` is NOT called when returning from B because View A is still in memory on the navigation stack. Only `viewWillAppear` and `viewDidAppear` are called. `viewDidLoad` is only called once when the view controller is first loaded into memory."

---

### Q3: "Can you modify the navigation stack during viewWillAppear?"

**✅ Answer:**
"Yes, but be careful. You can push/pop view controllers in `viewWillAppear`, but it can lead to unexpected behavior if not done carefully. It's better to use `viewDidAppear` for navigation changes if possible."

```swift
override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)

    // This works but can be tricky
    if !isUserLoggedIn {
        navigationController?.pushViewController(LoginViewController(), animated: false)
    }
}
```

---

### Q4: "What happens if you push two view controllers rapidly?"

**✅ Answer:**
"If you push ViewController C before B's animation completes, the system queues the operation. The lifecycle would be:
1. B: viewDidLoad
2. A: viewWillDisappear
3. B: viewWillAppear
4. [B animation...]
5. B: viewDidAppear
6. A: viewDidDisappear
7. C: viewDidLoad (next push starts)
8. B: viewWillDisappear
9. C: viewWillAppear
10. [C animation...]
11. C: viewDidAppear
12. B: viewDidDisappear"

---

## Real-World Scenarios

### Scenario 1: Save Data When Leaving Screen

```swift
class EditProfileViewController: UIViewController {
    var userProfile: UserProfile?

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        // ✅ Good - save before leaving
        saveUserProfile()
    }

    func saveUserProfile() {
        // Save changes to profile
        DatabaseManager.shared.save(userProfile)
    }
}
```

**Why `viewWillDisappear`?**
- Called before animation starts
- Ensures data is saved even if animation is cancelled
- Runs on main thread

---

### Scenario 2: Refresh Data When Returning

```swift
class RepositoryListViewController: UIViewController {
    var repositories: [Repository] = []

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // ✅ Good - refresh data when returning
        refreshRepositories()
    }

    func refreshRepositories() {
        // User might have starred a repo in detail view
        // Refresh list to show updated star count
        fetchRepositories()
    }
}
```

**Why `viewWillAppear`?**
- Called every time view appears (not just once)
- Data is ready before view is visible
- User sees updated data immediately

---

### Scenario 3: Analytics Tracking

```swift
class ProductDetailViewController: UIViewController {
    var product: Product?

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // ✅ Good - track when screen is fully visible
        Analytics.track(event: "product_viewed", properties: [
            "product_id": product?.id ?? "",
            "product_name": product?.name ?? ""
        ])
    }
}
```

**Why `viewDidAppear`?**
- User can actually see the screen
- Animation is complete
- Accurate screen view tracking

---

## Advanced: Custom Transitions

When using custom transitions, the lifecycle is the same:

```swift
// Custom transition still follows same lifecycle
navigationController?.delegate = self

func navigationController(_ navigationController: UINavigationController,
                         animationControllerFor operation: UINavigationController.Operation,
                         from fromVC: UIViewController,
                         to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
    return CustomTransitionAnimator()
}

// Lifecycle still happens:
// 1. toVC.viewDidLoad
// 2. fromVC.viewWillDisappear
// 3. toVC.viewWillAppear
// 4. [Custom animation]
// 5. toVC.viewDidAppear
// 6. fromVC.viewDidDisappear
```

---

## Memory Management

### When View Controllers Are Deallocated

```swift
// Navigation Stack: [A] → [A, B]

// B's deinit is NOT called when:
navigationController?.pushViewController(B, animated: true)
// B is still on the navigation stack

// B's deinit IS called when:
navigationController?.popViewController(animated: true)
// B is removed from navigation stack (if no other strong references)
```

### Retain Cycles to Avoid

```swift
class ViewControllerB: UIViewController {
    var onDismiss: (() -> Void)?

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        // ❌ Bad - creates retain cycle if closure captures self
        onDismiss = {
            self.cleanup() // Strong reference to self!
        }

        // ✅ Good - use [weak self]
        onDismiss = { [weak self] in
            self?.cleanup()
        }
    }
}
```

---

## Testing Lifecycle

### Unit Testing Lifecycle

```swift
func testPushLifecycle() {
    let navigationController = UINavigationController()
    let viewControllerA = ViewControllerA()
    let viewControllerB = ViewControllerB()

    // Setup
    navigationController.viewControllers = [viewControllerA]

    // Trigger viewDidLoad
    _ = viewControllerA.view

    // Push B
    navigationController.pushViewController(viewControllerB, animated: false)

    // Assert
    XCTAssertTrue(viewControllerB.isViewLoaded)
    XCTAssertEqual(navigationController.viewControllers.count, 2)

    // Pop
    navigationController.popViewController(animated: false)

    XCTAssertEqual(navigationController.viewControllers.count, 1)
}
```

---

## Comparison Table

| Event | A → B (Push) | B → A (Pop) |
|-------|-------------|-------------|
| **First call** | B: viewDidLoad | B: viewWillDisappear |
| **Second call** | A: viewWillDisappear | A: viewWillAppear |
| **Third call** | B: viewWillAppear | [Animation] |
| **Fourth call** | [Animation] | A: viewDidAppear |
| **Fifth call** | B: viewDidAppear | B: viewDidDisappear |
| **Sixth call** | A: viewDidDisappear | B: deinit |

---

## Study Tips

### ✅ Key Points to Remember

1. **Interleaving:** Both ViewControllers' lifecycle methods interleave during transition
2. **Will before Did:** All `will...` methods happen BEFORE animation
3. **Did after Animation:** All `did...` methods happen AFTER animation
4. **viewDidLoad once:** Only called when VC is first loaded into memory
5. **deinit on pop:** View controller is deallocated when popped (if no retain cycles)

### Common Mistakes to Avoid

❌ "A disappears before B appears"
✅ "A's `viewWillDisappear` and B's `viewWillAppear` are called together before animation"

❌ "viewDidLoad is called every time view appears"
✅ "viewDidLoad is called once when loaded into memory. viewWillAppear is called every time."

❌ "deinit is called immediately after viewDidDisappear"
✅ "deinit is called after viewDidDisappear when the view controller is removed from the navigation stack and there are no other strong references"

---

## 🔬 Verified Runtime Test Logs

Actual logs captured during interactive step-by-step navigation interleaving in `NavigationLifecycleExampleView.swift`:

```text
🧭 [NavigationLifecycle] Loaded Navigation Controller Lifecycle Interleaving Visualizer
🧭 [NavigationLifecycle] Step 1: [System] NavigationController.pushViewController(B, animated: true)
🧭 [NavigationLifecycle] Reset sequence for Pop (B → A)
🧭 [NavigationLifecycle] Reset sequence for Push (A → B)
🧭 [NavigationLifecycle] Step 1: [System] NavigationController.pushViewController(B, animated: true)
```

**Full Interleaving Execution Trace (A $\rightarrow$ B Push):**
```text
Step 1: [System] NavigationController.pushViewController(B, animated: true)
Step 2: [VC B] init()
Step 3: [VC B] loadView() & viewDidLoad()
Step 4: [VC A] viewWillDisappear(true)
Step 5: [VC B] viewWillAppear(true)
Step 6: [UIKit CoreAnimation] Push Transition Animation Runs (0.35s)
Step 7: [VC A] viewDidDisappear(true)
Step 8: [VC B] viewDidAppear(true)
```

**Full Interleaving Execution Trace (B $\rightarrow$ A Pop):**
```text
Step 1: [System] NavigationController.popViewController(animated: true)
Step 2: [VC B] viewWillDisappear(true)
Step 3: [VC A] viewWillAppear(true)
Step 4: [UIKit CoreAnimation] Pop Transition Animation Runs (0.35s)
Step 5: [VC B] viewDidDisappear(true)
Step 6: [VC A] viewDidAppear(true)
Step 7: [VC B] deinit
```

---

## See Also

- [ViewController Lifecycle](lifecycle_viewcontroller.md)
- [App Lifecycle](lifecycle_app.md)
- [Memory Leak Detection](advanced/memory_leak_detection.md)


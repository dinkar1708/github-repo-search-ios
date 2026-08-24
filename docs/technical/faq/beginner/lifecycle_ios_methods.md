# iOS Lifecycle Methods - Complete Guide

This guide covers all lifecycle methods in iOS for UIViewController, SwiftUI Views, App Lifecycle, and Scene Lifecycle.

## 📁 Code Examples in Project

**Interactive Sample View:** [`LifecycleMethodsOverviewView.swift`](../../../../github_repo_search_iOS_app/Modules/Feature/UI/Samples/Beginner/LifecycleMethodsOverviewView.swift) - Interactive framework comparison matrix (UIKit, SwiftUI, App & Scene) and technical interview knowledge check quiz.

## Table of Contents
1. [UIViewController Lifecycle (UIKit)](#uiviewcontroller-lifecycle-uikit)
2. [SwiftUI View Lifecycle](#swiftui-view-lifecycle)
3. [App Lifecycle](#app-lifecycle)
4. [Scene Lifecycle](#scene-lifecycle)
5. [View Lifecycle (UIView)](#view-lifecycle-uiview)
6. [Comparison Table](#comparison-table)

---

## UIViewController Lifecycle (UIKit)

### Complete Lifecycle Order

```
ViewController Created
  ↓
init()
  ↓
loadView() - Loads view hierarchy
  ↓
viewDidLoad() - View loaded into memory ⭐ MOST COMMON
  ↓
viewWillAppear(_ animated:) - About to appear
  ↓
viewWillLayoutSubviews() - Layout about to happen
  ↓
viewDidLayoutSubviews() - Layout finished
  ↓
viewDidAppear(_ animated:) - View visible on screen
  ↓
[View is visible - user interacts]
  ↓
viewWillDisappear(_ animated:) - About to leave screen
  ↓
viewDidDisappear(_ animated:) - No longer visible
  ↓
viewWillUnload() [DEPRECATED]
  ↓
deinit - ViewController deallocated
```

### 1. init / init(coder:)

**When:** ViewController is created

```swift
class MyViewController: UIViewController {
    // Programmatic creation
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        print("ViewController initialized programmatically")
    }

    // Storyboard creation
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        print("ViewController initialized from storyboard")
    }
}
```

**Use for:**
- Initialize properties
- Set default values
- Dependency injection

**Don't:**
- Access view properties (view not loaded yet)
- Perform heavy work

---

### 2. loadView()

**When:** View hierarchy is being loaded

```swift
override func loadView() {
    super.loadView()
    // OR create custom view
    // view = CustomView()

    print("View hierarchy loaded")
}
```

**Use for:**
- Custom view creation (without storyboards/XIBs)
- Replacing the entire view hierarchy

**Don't:**
- Call `super.loadView()` if creating custom view
- Access outlets (not connected yet)

**Example - Custom View:**
```swift
override func loadView() {
    let customView = UIView()
    customView.backgroundColor = .white
    view = customView // Set as root view
}
```

---

### 3. viewDidLoad() ⭐ MOST IMPORTANT

**When:** View loaded into memory (called ONCE per ViewController instance)

```swift
override func viewDidLoad() {
    super.viewDidLoad()

    print("View loaded - called ONCE")

    // Setup UI
    setupUI()

    // Configure views
    tableView.delegate = self
    tableView.dataSource = self

    // Add observers
    NotificationCenter.default.addObserver(
        self,
        selector: #selector(dataChanged),
        name: .dataDidChange,
        object: nil
    )

    // Initial data load
    viewModel.fetchInitialData()
}
```

**Use for:**
- One-time setup
- Configure views
- Add observers
- Set delegates
- Initial data loading
- Setup navigation bar

**Don't:**
- Perform layout calculations (frame sizes not final)
- Animate views (view not visible yet)

---

### 4. viewWillAppear(_ animated:)

**When:** View is about to appear on screen

**Called:** Every time view appears (not just once)

```swift
override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)

    print("View will appear")

    // Refresh data
    tableView.reloadData()

    // Update UI
    updateUserInterface()

    // Start animations
    navigationController?.setNavigationBarHidden(false, animated: animated)

    // Analytics
    trackScreenView()
}
```

**Use for:**
- Refresh data from database/network
- Update UI with latest data
- Start animations
- Show/hide navigation bar
- Analytics tracking
- Resume tasks

**Don't:**
- Heavy computation (blocks UI)
- Long network requests

---

### 5. viewWillLayoutSubviews()

**When:** View is about to layout its subviews

**Called:** Multiple times (whenever layout changes)

```swift
override func viewWillLayoutSubviews() {
    super.viewWillLayoutSubviews()

    print("About to layout subviews")
}
```

**Use for:**
- Prepare for layout changes
- Rarely needed

---

### 6. viewDidLayoutSubviews()

**When:** View has laid out its subviews

**Called:** Multiple times (after layout)

```swift
override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()

    print("Subviews laid out")

    // Now frames are final
    print("TableView frame: \(tableView.frame)")

    // Update constraints or manual layout
    customView.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: 200)
}
```

**Use for:**
- Adjust layout based on final frame sizes
- Manual layout calculations
- Update constraints

---

### 7. viewDidAppear(_ animated:)

**When:** View is now visible on screen

**Called:** After animation completes

```swift
override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)

    print("View did appear - visible to user")

    // Start animations
    startPulseAnimation()

    // Begin video playback
    videoPlayer.play()

    // Request permissions
    requestLocationPermission()

    // Show tutorial
    if isFirstLaunch {
        showTutorial()
    }
}
```

**Use for:**
- Start animations
- Begin video/audio playback
- Show alerts/dialogs
- Request permissions
- Start timers

---

### 8. viewWillDisappear(_ animated:)

**When:** View is about to leave the screen

```swift
override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)

    print("View will disappear")

    // Save data
    saveUserInput()

    // Stop animations
    stopPulseAnimation()

    // Pause media
    videoPlayer.pause()

    // Dismiss keyboard
    view.endEditing(true)
}
```

**Use for:**
- Save user input
- Stop animations
- Pause media playback
- Dismiss keyboard
- Commit changes

---

### 9. viewDidDisappear(_ animated:)

**When:** View is no longer visible

```swift
override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)

    print("View did disappear")

    // Stop timers
    timer?.invalidate()

    // Cancel network requests (if needed)
    currentTask?.cancel()

    // Release resources
    releaseHeavyResources()
}
```

**Use for:**
- Stop timers
- Cancel tasks
- Release resources
- Clean up

---

### 10. deinit

**When:** ViewController is being deallocated

```swift
deinit {
    print("ViewController deallocated")

    // Remove observers
    NotificationCenter.default.removeObserver(self)

    // Cancel tasks
    currentTask?.cancel()

    // Clean up
}
```

**Use for:**
- Remove observers
- Cancel operations
- Final cleanup

---

## SwiftUI View Lifecycle

### Lifecycle Events

```
View Created
  ↓
init() - View initialized
  ↓
body - View rendered
  ↓
.onAppear - View appeared on screen
  ↓
[View is visible]
  ↓
.onChange - State changed
  ↓
body - Re-rendered
  ↓
.onDisappear - View leaving screen
```

### 1. init()

**When:** View struct is created

```swift
struct UserListView: View {
    let users: [User]

    init(users: [User]) {
        self.users = users
        print("View initialized with \(users.count) users")
    }

    var body: some View {
        List(users) { user in
            Text(user.name)
        }
    }
}
```

**Use for:**
- Initialize properties
- Setup initial state
- Transform input data

**Don't:**
- Heavy computation
- Side effects

---

### 2. body

**When:** SwiftUI renders the view

**Called:** Every time state changes

```swift
struct ContentView: View {
    @State private var count = 0

    var body: some View {
        print("Body rendered - count: \(count)")

        return VStack {
            Text("Count: \(count)")
            Button("Increment") {
                count += 1 // Triggers body re-render
            }
        }
    }
}
```

**Use for:**
- Declare UI structure
- Use state/bindings
- Apply modifiers

**Don't:**
- Side effects (network calls, database writes)
- Heavy computation (use computed properties)

---

### 3. .onAppear

**When:** View appears on screen

```swift
struct UserProfileView: View {
    @StateObject private var viewModel = UserProfileViewModel()

    var body: some View {
        VStack {
            Text(viewModel.userName)
        }
        .onAppear {
            print("View appeared")
            viewModel.loadUserData()
        }
    }
}
```

**Use for:**
- Load data
- Start animations
- Analytics tracking
- Start timers

**Similar to:** `viewWillAppear` in UIKit

---

### 4. .onDisappear

**When:** View leaves the screen

```swift
struct VideoPlayerView: View {
    @State private var player = AVPlayer()

    var body: some View {
        VideoPlayer(player: player)
            .onAppear {
                player.play()
            }
            .onDisappear {
                print("View disappeared")
                player.pause()
            }
    }
}
```

**Use for:**
- Clean up resources
- Stop animations
- Save state
- Pause media

**Similar to:** `viewDidDisappear` in UIKit

---

### 5. .task { }

**When:** View appears (async version of onAppear)

```swift
struct RepositoryListView: View {
    @StateObject private var viewModel = RepositoryViewModel()

    var body: some View {
        List(viewModel.repositories) { repo in
            Text(repo.name)
        }
        .task {
            // Async work
            await viewModel.fetchRepositories()
        }
        .task(id: viewModel.searchQuery) {
            // Re-runs when searchQuery changes
            await viewModel.search()
        }
    }
}
```

**Use for:**
- Async data loading
- Network requests
- Database queries
- Long-running tasks

**Auto-cancels:** When view disappears

---

### 6. .onChange(of:)

**When:** State value changes

```swift
struct SearchView: View {
    @State private var searchText = ""
    @State private var results: [Result] = []

    var body: some View {
        VStack {
            TextField("Search", text: $searchText)

            List(results) { result in
                Text(result.name)
            }
        }
        .onChange(of: searchText) { oldValue, newValue in
            print("Search text changed: \(oldValue) → \(newValue)")
            performSearch(query: newValue)
        }
    }
}
```

**Use for:**
- React to state changes
- Trigger side effects
- Update dependent state
- Validation

---

### 7. .onReceive

**When:** Publisher emits a value

```swift
struct TimerView: View {
    @State private var currentTime = Date()
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        Text(currentTime, style: .time)
            .onReceive(timer) { time in
                currentTime = time
            }
    }
}
```

**Use for:**
- Listen to Combine publishers
- React to notifications
- Handle timers

---

## App Lifecycle

### 1. UIKit App Delegate

```swift
@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    // 1. App launching
    func application(_ application: UIApplication,
                    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        print("App launched")

        // Setup
        setupAnalytics()
        configureAppearance()
        registerForNotifications()

        return true
    }

    // 2. App became active
    func applicationDidBecomeActive(_ application: UIApplication) {
        print("App became active")
        // Resume tasks
        // Refresh data
    }

    // 3. App will resign active (call, control center)
    func applicationWillResignActive(_ application: UIApplication) {
        print("App will resign active")
        // Pause tasks
        // Save state
    }

    // 4. App entered background
    func applicationDidEnterBackground(_ application: UIApplication) {
        print("App entered background")
        // Save data
        // Release resources
    }

    // 5. App will enter foreground
    func applicationWillEnterForeground(_ application: UIApplication) {
        print("App will enter foreground")
        // Prepare UI
        // Refresh data
    }

    // 6. App will terminate
    func applicationWillTerminate(_ application: UIApplication) {
        print("App will terminate")
        // Save data
        // Clean up
    }
}
```

### 2. SwiftUI App Lifecycle

```swift
@main
struct MyApp: App {
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            switch newPhase {
            case .active:
                print("App is active")
                // App in foreground and receiving events
            case .inactive:
                print("App is inactive")
                // App in foreground but not receiving events
                // (e.g., during phone call, control center)
            case .background:
                print("App is in background")
                // App not visible, save data
            @unknown default:
                break
            }
        }
    }
}
```

---

## Scene Lifecycle

### UIKit Scene Delegate

```swift
class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    // 1. Scene connecting
    func scene(_ scene: UIScene,
              willConnectTo session: UISceneSession,
              options connectionOptions: UIScene.ConnectionOptions) {
        print("Scene will connect")

        guard let windowScene = scene as? UIWindowScene else { return }

        // Create window
        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = MainViewController()
        window.makeKeyAndVisible()
        self.window = window
    }

    // 2. Scene became active
    func sceneDidBecomeActive(_ scene: UIScene) {
        print("Scene became active")
        // Resume tasks
    }

    // 3. Scene will resign active
    func sceneWillResignActive(_ scene: UIScene) {
        print("Scene will resign active")
        // Pause tasks
    }

    // 4. Scene entered background
    func sceneDidEnterBackground(_ scene: UIScene) {
        print("Scene entered background")
        // Save data
    }

    // 5. Scene will enter foreground
    func sceneWillEnterForeground(_ scene: UIScene) {
        print("Scene will enter foreground")
        // Refresh UI
    }

    // 6. Scene disconnected
    func sceneDidDisconnect(_ scene: UIScene) {
        print("Scene disconnected")
        // Release resources
    }
}
```

---

## View Lifecycle (UIView)

```swift
class CustomView: UIView {

    // 1. View initialized
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    func setup() {
        print("View initialized")
    }

    // 2. View added to superview
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        print("View added to superview")
    }

    // 3. View added to window
    override func didMoveToWindow() {
        super.didMoveToWindow()
        print("View added to window: \(window != nil)")
    }

    // 4. Layout subviews
    override func layoutSubviews() {
        super.layoutSubviews()
        print("Layout subviews - frame: \(frame)")
    }

    // 5. Draw
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        print("Drawing view")
        // Custom drawing
    }

    // 6. View removed
    override func removeFromSuperview() {
        print("View removed from superview")
        super.removeFromSuperview()
    }
}
```

---

## Comparison Table

### UIKit vs SwiftUI Lifecycle

| UIKit ViewController | SwiftUI View | When |
|---------------------|--------------|------|
| `init` | `init()` | Creation |
| `viewDidLoad()` | First `body` call | Initial setup |
| `viewWillAppear` | `.onAppear` | About to appear |
| `viewDidAppear` | `.onAppear` | Visible on screen |
| `viewWillDisappear` | `.onDisappear` | About to disappear |
| `viewDidDisappear` | `.onDisappear` | No longer visible |
| - | `.task { }` | Async work on appear |
| - | `.onChange(of:)` | State changes |
| `deinit` | - | Deallocation |

### App Lifecycle

| UIKit AppDelegate | SwiftUI | When |
|------------------|---------|------|
| `didFinishLaunching` | App `init()` | App starts |
| `didBecomeActive` | `scenePhase == .active` | App active |
| `willResignActive` | `scenePhase == .inactive` | Losing focus |
| `didEnterBackground` | `scenePhase == .background` | Background |
| `willEnterForeground` | `scenePhase → .active` | Returning to foreground |

---

## Common Use Cases

### Load Data on View Appear

**UIKit:**
```swift
override func viewDidLoad() {
    super.viewDidLoad()
    // One-time setup
}

override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    // Refresh data each time
    loadData()
}
```

**SwiftUI:**
```swift
struct MyView: View {
    @StateObject private var viewModel = MyViewModel()

    var body: some View {
        List(viewModel.items) { item in
            Text(item.name)
        }
        .task {
            await viewModel.loadData()
        }
    }
}
```

### Save Data on Disappear

**UIKit:**
```swift
override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    saveUserData()
}
```

**SwiftUI:**
```swift
.onDisappear {
    saveUserData()
}
```

### React to State Changes

**UIKit:**
```swift
var userName: String = "" {
    didSet {
        updateUI()
    }
}
```

**SwiftUI:**
```swift
@State private var userName = ""

// Auto-updates UI when userName changes!
TextField("Name", text: $userName)

// Or manually react
.onChange(of: userName) { oldValue, newValue in
    validateName(newValue)
}
```

---

## Best Practices

### ✅ Do's

1. **Always call super**
   ```swift
   override func viewDidLoad() {
       super.viewDidLoad() // ← Always first
       // Your code
   }
   ```

2. **Use appropriate lifecycle method**
   - One-time setup → `viewDidLoad()`
   - Refresh data → `viewWillAppear()`
   - Start animations → `viewDidAppear()`

3. **Clean up in deinit/onDisappear**
   ```swift
   deinit {
       NotificationCenter.default.removeObserver(self)
   }
   ```

4. **Use .task for async work in SwiftUI**
   ```swift
   .task {
       await loadData() // Auto-cancelled on disappear
   }
   ```

### ❌ Don'ts

1. **Don't access view in init**
   ```swift
   // ❌ Bad
   override init(...) {
       super.init(...)
       view.backgroundColor = .red // Crash!
   }
   ```

2. **Don't perform heavy work in viewDidLoad**
   ```swift
   // ❌ Bad
   override func viewDidLoad() {
       super.viewDidLoad()
       loadHugeDataset() // Blocks UI
   }
   ```

3. **Don't forget to remove observers**
   ```swift
   // ❌ Bad - memory leak
   override func viewDidLoad() {
       NotificationCenter.default.addObserver(...)
       // Missing removeObserver in deinit!
   }
   ```

---

## 🔬 Verified Runtime Test Logs & Simulation Output

Consolidated runtime execution logs verified across all lifecycle test suites:

```text
🟢 APP LIFECYCLE: Active (Foreground)
📱 [AppLifecycle] AppLifecycleExampleView appeared - Initial phase: 🟢 Active
📱 [AppLifecycle] Background Task Started: beginBackgroundTask(expirationHandler: ...)
📱 [AppLifecycle] Background task progress: 25s remaining ... 0s remaining
📱 [AppLifecycle] Background Task Ended: endBackgroundTask(identifier)

🪟 [SceneLifecycle] Scene initialized - Restored note: ""
🪟 [SceneLifecycle] Saved to @SceneStorage: "dddddd"

🏛️ [ViewControllerLifecycle] [Embedded View] 0. init() -> 1. loadView() -> 2. viewDidLoad() -> 3. viewWillAppear -> 4. viewWillLayoutSubviews -> 5. viewDidLayoutSubviews -> 6. viewDidAppear -> 7. viewWillDisappear -> 8. viewDidDisappear -> 9. deinit (Deallocated)

🧩 [SwiftUIViewLifecycle] Parent onAppear -> Child onAppear -> Reset .id(E749) -> Child onDisappear -> Child onAppear -> 🔄 .onChange(counter: 0 -> 1)

🧭 [NavigationLifecycle] Loaded Navigation Controller Lifecycle Interleaving Visualizer
🧭 [NavigationLifecycle] Step 1: [System] NavigationController.pushViewController(B, animated: true)

📚 [LifecycleOverview] Opened Lifecycle Methods Overview
📚 [LifecycleOverview] Switched domain to: SwiftUI / App & Scene / UIKit (VC)

🟡 APP LIFECYCLE: Inactive
🔴 APP LIFECYCLE: Background
```

---

## See Also

- [App Launch Lifecycle](../app_launch_lifecycle.md)
- [Screen Rotation Data Handling](screen_rotation_data_handling.md)
- [Memory Leak Detection](advanced/memory_leak_detection.md)


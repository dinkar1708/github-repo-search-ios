# iOS App Lifecycle

Complete guide to iOS App lifecycle methods and states.

## 📁 Code Examples in Project

**Real implementation:** [`LauncherView.swift:12-30`](../../../../github_repo_search_iOS_app/AppConfig/LauncherView.swift#L12-L30)
```swift
@main
struct LauncherView: App {
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            SplashView()
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            switch newPhase {
            case .active:
                print("🟢 APP LIFECYCLE: Active (Foreground)")
            case .inactive:
                print("🟡 APP LIFECYCLE: Inactive")
            case .background:
                print("🔴 APP LIFECYCLE: Background")
            @unknown default:
                print("⚪️ APP LIFECYCLE: Unknown")
            }
        }
    }
}
```

**Interactive Sample View:** [`AppLifecycleExampleView.swift`](../../../../github_repo_search_iOS_app/Modules/Feature/UI/Samples/Beginner/AppLifecycleExampleView.swift) - Interactive live scenePhase tracker, state simulator, and background task demo.

**Related files:**
- `github_repo_search_iOS_app/AppConfig/LauncherView.swift` - SwiftUI app lifecycle with scenePhase monitoring
- `github_repo_search_iOS_app/AppConfig/MainTabView.swift` - Main tab navigation & samples list
- `github_repo_search_iOS_app/Modules/Feature/UI/Samples/Beginner/AppLifecycleExampleView.swift` - Live App Lifecycle Sample View

## App Lifecycle States

```
Not Running
  ↓
App Launches → Inactive → Active (Foreground)
  ↓                         ↓
Background ←----------------┘
  ↓
Suspended
  ↓
Terminated
```

## UIKit - AppDelegate Methods

### 1. application(_:didFinishLaunchingWithOptions:)

**When:** App has launched (first method called)

```swift
@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication,
                    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        print("✅ App launched")

        // Global setup
        setupAnalytics()
        configureAppearance()
        registerForNotifications()
        setupDependencies()

        // Setup window (if not using SceneDelegate)
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = MainViewController()
        window?.makeKeyAndVisible()

        return true
    }

    func setupAnalytics() {
        // Firebase, Mixpanel, etc.
    }

    func configureAppearance() {
        UINavigationBar.appearance().tintColor = .systemBlue
    }

    func registerForNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            print("Notifications authorized: \(granted)")
        }
    }
}
```

**Use for:**
- One-time global setup
- Initialize analytics
- Configure UI appearance
- Register for notifications
- Setup third-party SDKs
- Dependency injection setup

---

### 2. applicationDidBecomeActive(_:)

**When:** App became active (foreground and receiving events)

```swift
func applicationDidBecomeActive(_ application: UIApplication) {
    print("✅ App became active")

    // Resume tasks
    resumeTimers()
    refreshData()
    restartAnimations()

    // Clear badge
    application.applicationIconBadgeNumber = 0

    // Track session
    Analytics.trackAppOpened()
}
```

**Use for:**
- Resume paused tasks
- Refresh data from server
- Restart animations/timers
- Clear notification badge
- Start location updates
- Track analytics

---

### 3. applicationWillResignActive(_:)

**When:** App about to lose focus (phone call, control center, etc.)

```swift
func applicationWillResignActive(_ application: UIApplication) {
    print("⚠️ App will resign active")

    // Pause tasks
    pauseTimers()
    pauseMedia()
    saveGameState()

    // Dismiss keyboard
    application.windows.first?.endEditing(true)
}
```

**Use for:**
- Pause ongoing tasks
- Pause media playback
- Stop timers
- Save game state
- Dismiss keyboard
- Pause animations

---

### 4. applicationDidEnterBackground(_:)

**When:** App entered background (not visible)

**Time limit:** ~30 seconds to finish tasks (can request more time)

```swift
func applicationDidEnterBackground(_ application: UIApplication) {
    print("📱 App entered background")

    // Save data
    saveUserData()
    CoreDataManager.shared.saveContext()

    // Release resources
    releaseMemory()

    // Request background time if needed
    var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    backgroundTask = application.beginBackgroundTask {
        // Time expired
        application.endBackgroundTask(backgroundTask)
        backgroundTask = .invalid
    }

    // Perform background work
    performBackgroundSync {
        application.endBackgroundTask(backgroundTask)
        backgroundTask = .invalid
    }
}

func saveUserData() {
    UserDefaults.standard.set(currentState, forKey: "appState")
    UserDefaults.standard.synchronize()
}

func releaseMemory() {
    // Release cached images, large objects
    ImageCache.shared.clearMemoryCache()
}
```

**Use for:**
- Save user data
- Save Core Data context
- Release memory (caches)
- Stop location updates (if not needed)
- Cancel network requests
- Request background time for long tasks

---

### 5. applicationWillEnterForeground(_:)

**When:** App returning from background to foreground

```swift
func applicationWillEnterForeground(_ application: UIApplication) {
    print("🔄 App will enter foreground")

    // Prepare UI
    refreshUI()

    // Refresh data
    checkForUpdates()

    // Restore state
    restoreUserState()

    // Check authentication
    if authTokenExpired() {
        showLoginScreen()
    }
}

func checkForUpdates() {
    // Check if data is stale
    if dataIsStale() {
        fetchLatestData()
    }
}
```

**Use for:**
- Refresh UI
- Update data from server
- Restore state
- Check authentication
- Refresh tokens

---

### 6. applicationWillTerminate(_:)

**When:** App is about to terminate

**Note:** Not called if app is suspended in background

```swift
func applicationWillTerminate(_ application: UIApplication) {
    print("❌ App will terminate")

    // Save data (last chance!)
    saveUserData()
    CoreDataManager.shared.saveContext()

    // Clean up
    cleanup()
}
```

**Use for:**
- Final save of user data
- Save Core Data
- Clean up resources

**Warning:** Limited time (~5 seconds), don't rely on this

---

## SwiftUI - App Lifecycle

### Using @main and scenePhase

```swift
@main
struct MyApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var appState = AppState()

    init() {
        print("✅ App struct initialized")
        // Global setup
        setupAppearance()
        setupAnalytics()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            handleScenePhaseChange(from: oldPhase, to: newPhase)
        }
    }

    func handleScenePhaseChange(from oldPhase: ScenePhase, to newPhase: ScenePhase) {
        switch newPhase {
        case .active:
            print("✅ App is ACTIVE")
            handleActive()

        case .inactive:
            print("⚠️ App is INACTIVE")
            handleInactive()

        case .background:
            print("📱 App is in BACKGROUND")
            handleBackground()

        @unknown default:
            break
        }
    }

    func handleActive() {
        // App in foreground and receiving events
        appState.refreshData()
        appState.resumeTasks()

        // Analytics
        Analytics.trackAppOpened()
    }

    func handleInactive() {
        // App in foreground but NOT receiving events
        // (e.g., control center, phone call, app switcher)
        appState.pauseTasks()
        appState.saveDraft()
    }

    func handleBackground() {
        // App not visible to user
        appState.saveData()
        appState.releaseResources()
    }

    func setupAppearance() {
        // Configure global appearance
    }

    func setupAnalytics() {
        // Initialize analytics
    }
}

// App State Manager
class AppState: ObservableObject {
    @Published var isActive = false

    func refreshData() {
        // Refresh data from server
    }

    func resumeTasks() {
        // Resume paused tasks
    }

    func pauseTasks() {
        // Pause ongoing tasks
    }

    func saveDraft() {
        // Save user's work
    }

    func saveData() {
        // Save to disk
    }

    func releaseResources() {
        // Clear caches
    }
}
```

### ScenePhase Values

| ScenePhase | Description | Similar to AppDelegate |
|------------|-------------|----------------------|
| `.active` | App in foreground, receiving events | `didBecomeActive` |
| `.inactive` | App in foreground, NOT receiving events | `willResignActive` |
| `.background` | App in background, not visible | `didEnterBackground` |

---

## App Lifecycle Scenarios

### Scenario 1: Cold Start (App Launch)

```
User taps app icon
  ↓
didFinishLaunching → Inactive → Active
```

**Methods called:**
1. `application(_:didFinishLaunchingWithOptions:)`
2. `applicationDidBecomeActive(_:)`

---

### Scenario 2: Phone Call Received

```
Active → Inactive → Background (if call answered)
       → Active (if call rejected)
```

**Methods called:**
1. `applicationWillResignActive(_:)`
2. `applicationDidEnterBackground(_:)` (if answered)
   OR
   `applicationDidBecomeActive(_:)` (if rejected)

---

### Scenario 3: User Presses Home Button

```
Active → Inactive → Background → Suspended
```

**Methods called:**
1. `applicationWillResignActive(_:)`
2. `applicationDidEnterBackground(_:)`

---

### Scenario 4: Return from Background

```
Background → Inactive → Active
```

**Methods called:**
1. `applicationWillEnterForeground(_:)`
2. `applicationDidBecomeActive(_:)`

---

### Scenario 5: App Switcher

```
Active → Inactive (showing app switcher)
       → Active (if user returns to app)
       → Background (if user switches away)
```

**Methods called:**
1. `applicationWillResignActive(_:)`
2. `applicationDidBecomeActive(_:)` OR `applicationDidEnterBackground(_:)`

---

## Background Execution

### Request Background Time

```swift
func applicationDidEnterBackground(_ application: UIApplication) {
    var backgroundTask: UIBackgroundTaskIdentifier = .invalid

    backgroundTask = application.beginBackgroundTask {
        // Expiration handler - called when time is up
        print("⏰ Background time expired")
        application.endBackgroundTask(backgroundTask)
        backgroundTask = .invalid
    }

    // Perform background work
    DispatchQueue.global(qos: .background).async {
        // Upload data, sync, etc.
        self.syncDataWithServer { success in
            // End task when done
            application.endBackgroundTask(backgroundTask)
            backgroundTask = .invalid
        }
    }
}
```

### Background Modes

Enable in Project Settings → Capabilities → Background Modes:

- **Audio, AirPlay, Picture in Picture** - Play audio in background
- **Location updates** - Continuous location
- **Voice over IP** - VoIP calls
- **Background fetch** - Periodic content updates
- **Remote notifications** - Silent push notifications
- **Background processing** - Longer background tasks

---

## Complete Example: Repository App

```swift
@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    let repositoryManager = RepositoryManager.shared

    func application(_ application: UIApplication,
                    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        print("✅ App launched")

        // Setup
        setupDependencies()
        setupAnalytics()
        migrateDataIfNeeded()

        return true
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        print("✅ Active")

        // Refresh repositories
        repositoryManager.refreshStarredRepositories()

        // Clear badge
        application.applicationIconBadgeNumber = 0

        // Track
        Analytics.track(event: "app_opened")
    }

    func applicationWillResignActive(_ application: UIApplication) {
        print("⚠️ Will resign active")

        // Save draft search
        repositoryManager.saveDraftSearch()
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        print("📱 Background")

        // Save data
        CoreDataStack.shared.saveContext()

        // Cancel ongoing requests
        repositoryManager.cancelOngoingRequests()

        // Clear memory cache
        ImageCache.shared.clearMemoryCache()

        // Request background time for sync
        var backgroundTask: UIBackgroundTaskIdentifier = .invalid
        backgroundTask = application.beginBackgroundTask {
            application.endBackgroundTask(backgroundTask)
        }

        repositoryManager.syncFavorites { success in
            application.endBackgroundTask(backgroundTask)
        }
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        print("🔄 Foreground")

        // Check for updates
        repositoryManager.checkForNewStars()

        // Refresh data if stale
        if repositoryManager.isDataStale {
            repositoryManager.refreshAllData()
        }
    }

    func applicationWillTerminate(_ application: UIApplication) {
        print("❌ Terminate")

        // Final save
        CoreDataStack.shared.saveContext()
    }

    func setupDependencies() {
        // Setup DI container
    }

    func setupAnalytics() {
        // Firebase, etc.
    }

    func migrateDataIfNeeded() {
        // Data migration
    }
}
```

---

## Best Practices

### ✅ Do's

1. **Save data in `didEnterBackground`**
   ```swift
   func applicationDidEnterBackground(_ application: UIApplication) {
       saveAllData()
   }
   ```

2. **Refresh data in `willEnterForeground`**
   ```swift
   func applicationWillEnterForeground(_ application: UIApplication) {
       if dataIsStale() {
           refreshData()
       }
   }
   ```

3. **Pause tasks in `willResignActive`**
   ```swift
   func applicationWillResignActive(_ application: UIApplication) {
       pauseAllTasks()
       saveUserProgress()
   }
   ```

4. **Use background tasks for long operations**
   ```swift
   let task = application.beginBackgroundTask { }
   // Do work
   application.endBackgroundTask(task)
   ```

### ❌ Don'ts

1. **Don't rely on `willTerminate`**
   ```swift
   // ❌ Bad - not always called
   func applicationWillTerminate(_ application: UIApplication) {
       saveData() // Might not be called!
   }
   ```

2. **Don't perform long operations in `didFinishLaunching`**
   ```swift
   // ❌ Bad - blocks app launch
   func application(...didFinishLaunchingWithOptions...) -> Bool {
       downloadLargeFile() // Blocks launch!
       return true
   }
   ```

3. **Don't forget to end background tasks**
   ```swift
   // ❌ Bad - app will be killed
   let task = application.beginBackgroundTask { }
   // ... work ...
   // Missing: application.endBackgroundTask(task)
   ```

---

## Testing App Lifecycle

### Simulate Background/Foreground

In Xcode Debugger:
```
Cmd + Shift + H - Simulate home button (background)
Cmd + Shift + H H - Show app switcher
```

### Debug Console

```swift
func applicationDidEnterBackground(_ application: UIApplication) {
    print("📱 BACKGROUND - Time remaining: \(application.backgroundTimeRemaining)")
}
```

---

## 🔬 Verified Runtime Test Logs

The following actual logs were captured during simulator runtime execution in `AppLifecycleExampleView.swift` & `LauncherView.swift`:

```text
🟢 APP LIFECYCLE: Active (Foreground)
📱 [AppLifecycle] AppLifecycleExampleView appeared - Initial phase: 🟢 Active
📱 [AppLifecycle] Background Task Started: beginBackgroundTask(expirationHandler: ...)
📱 [AppLifecycle] Background task progress: 25s remaining
📱 [AppLifecycle] Background task progress: 20s remaining
📱 [AppLifecycle] Background task progress: 15s remaining
📱 [AppLifecycle] Background task progress: 10s remaining
📱 [AppLifecycle] Background task progress: 5s remaining
📱 [AppLifecycle] Background task progress: 0s remaining
📱 [AppLifecycle] Background Task Ended: endBackgroundTask(identifier)
🟡 APP LIFECYCLE: Inactive
🔴 APP LIFECYCLE: Background
```

> [!NOTE]
> **Understanding Simulator Diagnostics**:
> - `🟢 APP LIFECYCLE: Active`: Root ScenePhase transitioned to foreground.
> - `beginBackgroundTask`: Requests up to 30s background execution time from iOS.
> - `endBackgroundTask`: Must always be called when work completes to prevent OS watchdog termination.

---

## See Also

- [ViewController Lifecycle](lifecycle_viewcontroller.md)
- [SwiftUI View Lifecycle](lifecycle_swiftui_view.md)
- [Scene Lifecycle](lifecycle_scene.md)
- [App Launch Lifecycle](../app_launch_lifecycle.md)


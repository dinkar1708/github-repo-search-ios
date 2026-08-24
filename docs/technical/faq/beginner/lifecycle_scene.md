# iOS Scene Lifecycle

Complete guide to Scene lifecycle in iOS 13+ apps with multiple windows support.

## 📁 Code Examples in Project

**Real implementation:** [`AppConfig/LauncherView.swift:12-30`](../../../../github_repo_search_iOS_app/AppConfig/LauncherView.swift#L12-L30)

This app uses SwiftUI's modern `@Environment(\.scenePhase)` for scene lifecycle:
```swift
@Environment(\.scenePhase) private var scenePhase

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
```

**Note:** This app uses SwiftUI lifecycle (`@main struct LauncherView: App`) instead of UIKit SceneDelegate. The SwiftUI approach is simpler and more modern.

**Interactive Sample View:** [`SceneLifecycleExampleView.swift`](../../../../github_repo_search_iOS_app/Modules/Feature/UI/Samples/Beginner/SceneLifecycleExampleView.swift) - Demonstrates multi-scene phase transitions, window simulation, and `@SceneStorage` state restoration.

## What is a Scene?

A **Scene** represents a single UI instance of your app (one window). Starting from iOS 13, apps support **multiple scenes** (multiple windows of same app).

```
One App = Multiple Scenes (Windows)
  ├─ Scene 1 (iPad Split View - Left)
  ├─ Scene 2 (iPad Split View - Right)
  └─ Scene 3 (External Display)
```

---

## Scene vs App Lifecycle

### Pre-iOS 13 (App-based)
```
UIApplicationDelegate
  └─ Single app instance
```

### iOS 13+ (Scene-based)
```
UIApplicationDelegate (App-level events)
  └─ UISceneDelegate (Scene-level events)
      ├─ Scene 1
      ├─ Scene 2
      └─ Scene 3
```

---

## Scene Lifecycle Methods

### Complete Flow

```
App Launched
  ↓
scene(_:willConnectTo:options:)
  ↓
sceneWillEnterForeground(_:)
  ↓
sceneDidBecomeActive(_:)
  ↓
[Scene is active]
  ↓
sceneWillResignActive(_:)
  ↓
sceneDidEnterBackground(_:)
  ↓
sceneDidDisconnect(_:)
```

---

## 1. scene(_:willConnectTo:options:)

**When:** New scene is being added to app

**Called:** First method when scene connects

```swift
class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene,
              willConnectTo session: UISceneSession,
              options connectionOptions: UIScene.ConnectionOptions) {

        print("✅ Scene will connect")

        guard let windowScene = scene as? UIWindowScene else { return }

        // Create window
        let window = UIWindow(windowScene: windowScene)

        // Set root view controller
        let rootViewController = MainTabBarController()
        window.rootViewController = rootViewController

        // Make window visible
        window.makeKeyAndVisible()

        self.window = window

        // Handle URL if app opened via URL
        if let urlContext = connectionOptions.urlContexts.first {
            handleURL(urlContext.url)
        }

        // Handle user activity (Handoff, Spotlight)
        if let userActivity = connectionOptions.userActivities.first {
            handleUserActivity(userActivity)
        }
    }

    func handleURL(_ url: URL) {
        print("Opened with URL: \(url)")
        // Handle deep link
    }

    func handleUserActivity(_ userActivity: NSUserActivity) {
        print("Opened with activity: \(userActivity.activityType)")
        // Handle Handoff, Spotlight
    }
}
```

### Use For:
- Create and configure window
- Set root view controller
- Handle launch options (URL, user activity)
- Restore scene state

---

## 2. sceneDidBecomeActive(_:)

**When:** Scene became active (foreground and receiving events)

```swift
func sceneDidBecomeActive(_ scene: UIScene) {
    print("✅ Scene became active")

    // Resume tasks
    resumePausedTasks()

    // Refresh data
    refreshData()

    // Restart animations
    startAnimations()

    // Clear badge
    UIApplication.shared.applicationIconBadgeNumber = 0

    // Track analytics
    Analytics.trackSceneActive()
}
```

### Use For:
- Resume paused tasks
- Refresh data
- Restart animations/timers
- Clear notification badges
- Track analytics

---

## 3. sceneWillResignActive(_:)

**When:** Scene about to lose focus (phone call, control center, etc.)

```swift
func sceneWillResignActive(_ scene: UIScene) {
    print("⚠️ Scene will resign active")

    // Pause ongoing tasks
    pauseTasks()

    // Pause media
    pauseMediaPlayback()

    // Save game state
    saveGameState()
}
```

### Use For:
- Pause ongoing tasks
- Pause media playback
- Save game/app state
- Stop timers

---

## 4. sceneDidEnterBackground(_:)

**When:** Scene entered background (not visible)

```swift
func sceneDidEnterBackground(_ scene: UIScene) {
    print("📱 Scene entered background")

    // Save data
    CoreDataStack.shared.saveContext()

    // Release resources
    releaseMemoryIntensiveResources()

    // Cancel network requests
    cancelNonEssentialRequests()

    // Schedule background tasks
    scheduleBackgroundRefresh()
}

func releaseMemoryIntensiveResources() {
    // Release cached images, large objects
    ImageCache.shared.clearMemoryCache()
}

func scheduleBackgroundRefresh() {
    // Schedule BGTaskScheduler tasks
}
```

### Use For:
- Save user data
- Save Core Data
- Release memory (caches)
- Cancel network requests
- Schedule background tasks

---

## 5. sceneWillEnterForeground(_:)

**When:** Scene returning from background to foreground

```swift
func sceneWillEnterForeground(_ scene: UIScene) {
    print("🔄 Scene will enter foreground")

    // Refresh UI
    refreshUserInterface()

    // Check for updates
    checkForUpdates()

    // Restore state
    restoreState()

    // Reload data if stale
    if isDataStale() {
        reloadData()
    }
}
```

### Use For:
- Refresh UI
- Update data from server
- Restore state
- Check authentication

---

## 6. sceneDidDisconnect(_:)

**When:** Scene disconnected (user closed the scene/window)

**Note:** Scene may reconnect later (not permanently destroyed)

```swift
func sceneDidDisconnect(_ scene: UIScene) {
    print("❌ Scene disconnected")

    // Release scene-specific resources
    releaseSceneResources()

    // Save state for restoration
    saveSceneState()

    // Clean up
    window = nil
}

func releaseSceneResources() {
    // Release resources specific to this scene
    // Keep app-level data intact (other scenes might need it)
}

func saveSceneState() {
    // Save state so scene can be restored later
    UserDefaults.standard.set(currentState, forKey: "sceneState")
}
```

### Use For:
- Release scene-specific resources
- Save state for restoration
- Clean up scene data

**Warning:** Don't delete app-wide data (other scenes might be active!)

---

## Scene Configuration

### Info.plist Configuration

```xml
<key>UIApplicationSceneManifest</key>
<dict>
    <key>UIApplicationSupportsMultipleScenes</key>
    <true/>

    <key>UISceneConfigurations</key>
    <dict>
        <key>UIWindowSceneSessionRoleApplication</key>
        <array>
            <dict>
                <key>UISceneConfigurationName</key>
                <string>Default Configuration</string>

                <key>UISceneDelegateClassName</key>
                <string>$(PRODUCT_MODULE_NAME).SceneDelegate</string>

                <key>UISceneStoryboardFile</key>
                <string>Main</string>
            </dict>
        </array>
    </dict>
</dict>
```

---

## App Delegate Integration

### AppDelegate Methods for Scenes

```swift
@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    // 1. Scene configuration
    func application(_ application: UIApplication,
                    configurationForConnecting connectingSceneSession: UISceneSession,
                    options: UIScene.ConnectionOptions) -> UISceneConfiguration {

        print("🔧 Configuring scene")

        // Return scene configuration
        return UISceneConfiguration(
            name: "Default Configuration",
            sessionRole: connectingSceneSession.role
        )
    }

    // 2. Scene discarded
    func application(_ application: UIApplication,
                    didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {

        print("🗑 Scenes discarded: \(sceneSessions.count)")

        // Clean up resources for discarded scenes
        for session in sceneSessions {
            cleanupScene(session)
        }
    }

    func cleanupScene(_ session: UISceneSession) {
        // Clean up permanent resources for this scene
    }
}
```

---

## SwiftUI Scene Lifecycle

### Using @Environment(\.scenePhase)

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
                print("✅ Scene is active")
                handleActive()

            case .inactive:
                print("⚠️ Scene is inactive")
                handleInactive()

            case .background:
                print("📱 Scene is in background")
                handleBackground()

            @unknown default:
                break
            }
        }
    }

    func handleActive() {
        // Scene active - refresh data
    }

    func handleInactive() {
        // Scene inactive - pause tasks
    }

    func handleBackground() {
        // Scene in background - save data
    }
}
```

---

## Multiple Scenes Example

### Supporting Multiple Windows (iPad)

```swift
class SceneDelegate: UIWindowSceneDelegate {

    var window: UIWindow?
    var sceneIdentifier: String?

    func scene(_ scene: UIScene,
              willConnectTo session: UISceneSession,
              options connectionOptions: UIScene.ConnectionOptions) {

        guard let windowScene = scene as? UIWindowScene else { return }

        // Unique identifier for this scene
        sceneIdentifier = session.persistentIdentifier

        // Create window
        let window = UIWindow(windowScene: windowScene)

        // Different content for different scenes?
        if let userActivity = connectionOptions.userActivities.first,
           userActivity.activityType == "com.app.repository.detail" {
            // Open detail in this scene
            window.rootViewController = createDetailViewController()
        } else {
            // Default main view
            window.rootViewController = createMainViewController()
        }

        window.makeKeyAndVisible()
        self.window = window
    }

    func createMainViewController() -> UIViewController {
        // Main content
        return MainTabBarController()
    }

    func createDetailViewController() -> UIViewController {
        // Detail content
        return RepositoryDetailViewController()
    }
}
```

### Request New Scene (iPad)

```swift
func openInNewWindow(repository: Repository) {
    // Create user activity
    let userActivity = NSUserActivity(activityType: "com.app.repository.detail")
    userActivity.userInfo = ["repositoryID": repository.id]

    // Request new scene
    UIApplication.shared.requestSceneSessionActivation(
        nil,  // nil = new scene
        userActivity: userActivity,
        options: nil
    ) { error in
        if let error = error {
            print("Error creating scene: \(error)")
        }
    }
}
```

---

## State Restoration

### Save Scene State

```swift
func stateRestorationActivity(for scene: UIScene) -> NSUserActivity? {
    let activity = NSUserActivity(activityType: "com.app.sceneState")

    activity.userInfo = [
        "currentTab": currentTab,
        "selectedRepository": selectedRepositoryID
    ]

    return activity
}
```

### Restore Scene State

```swift
func scene(_ scene: UIScene,
          willConnectTo session: UISceneSession,
          options connectionOptions: UIScene.ConnectionOptions) {

    // Restore from user activity
    if let userActivity = session.stateRestorationActivity ?? connectionOptions.userActivities.first {
        restoreState(from: userActivity)
    }
}

func restoreState(from activity: NSUserActivity) {
    if let currentTab = activity.userInfo?["currentTab"] as? Int {
        tabBarController.selectedIndex = currentTab
    }

    if let repoID = activity.userInfo?["selectedRepository"] as? String {
        showRepository(id: repoID)
    }
}
```

---

## Complete Example

```swift
class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    var sceneID: String = ""

    // MARK: - 1. Scene Connecting
    func scene(_ scene: UIScene,
              willConnectTo session: UISceneSession,
              options connectionOptions: UIScene.ConnectionOptions) {

        print("✅ Scene connecting")

        guard let windowScene = scene as? UIWindowScene else { return }

        sceneID = session.persistentIdentifier

        // Setup window
        setupWindow(windowScene: windowScene)

        // Handle launch options
        handleLaunchOptions(connectionOptions)

        // Restore state
        if let userActivity = session.stateRestorationActivity {
            restoreState(from: userActivity)
        }
    }

    func setupWindow(windowScene: UIWindowScene) {
        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = createRootViewController()
        window.makeKeyAndVisible()
        self.window = window
    }

    func createRootViewController() -> UIViewController {
        let mainVC = MainTabBarController()
        return UINavigationController(rootViewController: mainVC)
    }

    // MARK: - 2. Scene Active
    func sceneDidBecomeActive(_ scene: UIScene) {
        print("✅ Scene \(sceneID) active")

        // Resume tasks
        NotificationCenter.default.post(name: .sceneDidBecomeActive, object: nil)

        // Refresh data
        refreshData()
    }

    // MARK: - 3. Scene Resign Active
    func sceneWillResignActive(_ scene: UIScene) {
        print("⚠️ Scene \(sceneID) will resign active")

        // Pause tasks
        NotificationCenter.default.post(name: .sceneWillResignActive, object: nil)
    }

    // MARK: - 4. Scene Background
    func sceneDidEnterBackground(_ scene: UIScene) {
        print("📱 Scene \(sceneID) background")

        // Save data
        saveData()

        // Release resources
        releaseResources()
    }

    // MARK: - 5. Scene Foreground
    func sceneWillEnterForeground(_ scene: UIScene) {
        print("🔄 Scene \(sceneID) foreground")

        // Refresh UI
        refreshUI()
    }

    // MARK: - 6. Scene Disconnect
    func sceneDidDisconnect(_ scene: UIScene) {
        print("❌ Scene \(sceneID) disconnected")

        // Save state
        saveState()

        // Clean up
        window = nil
    }

    // MARK: - State Restoration
    func stateRestorationActivity(for scene: UIScene) -> NSUserActivity? {
        let activity = NSUserActivity(activityType: "com.app.scene")
        activity.userInfo = ["sceneID": sceneID]
        return activity
    }

    // MARK: - Helper Methods
    func handleLaunchOptions(_ options: UIScene.ConnectionOptions) {
        // Handle URL
        if let url = options.urlContexts.first?.url {
            handleURL(url)
        }

        // Handle user activity
        if let activity = options.userActivities.first {
            handleUserActivity(activity)
        }
    }

    func refreshData() {
        // Refresh data
    }

    func saveData() {
        // Save data
    }

    func releaseResources() {
        // Release memory
    }

    func refreshUI() {
        // Update UI
    }

    func saveState() {
        // Save scene state
    }
}
```

---

## Scene vs App Lifecycle

| Event | AppDelegate | SceneDelegate |
|-------|-------------|---------------|
| **App launches** | `didFinishLaunching` | - |
| **Scene connects** | - | `scene(_:willConnectTo:)` |
| **Becomes active** | `didBecomeActive` | `sceneDidBecomeActive` |
| **Resigns active** | `willResignActive` | `sceneWillResignActive` |
| **Background** | `didEnterBackground` | `sceneDidEnterBackground` |
| **Foreground** | `willEnterForeground` | `sceneWillEnterForeground` |
| **Scene disconnects** | - | `sceneDidDisconnect` |
| **App terminates** | `willTerminate` | - |

---

## Best Practices

### ✅ Do's

1. **Support both App and Scene delegates**
   ```swift
   // AppDelegate for app-level
   // SceneDelegate for scene-level
   ```

2. **Save state for restoration**
   ```swift
   func stateRestorationActivity(for scene: UIScene) -> NSUserActivity?
   ```

3. **Release scene-specific resources in didDisconnect**
   ```swift
   func sceneDidDisconnect(_ scene: UIScene) {
       releaseSceneResources()
   }
   ```

4. **Use NotificationCenter for communication**
   ```swift
   NotificationCenter.default.post(name: .sceneDidBecomeActive, object: nil)
   ```

### ❌ Don'ts

1. **Don't delete app-wide data in sceneDidDisconnect**
   ```swift
   // ❌ Bad - other scenes might need this
   DatabaseManager.shared.deleteAll()

   // ✅ Good - only scene-specific data
   releaseSceneResources()
   ```

2. **Don't assume single scene**
   ```swift
   // ❌ Bad
   let window = UIApplication.shared.windows.first

   // ✅ Good
   if let windowScene = scene as? UIWindowScene {
       let window = UIWindow(windowScene: windowScene)
   }
   ```

---

## 🔬 Verified Runtime Test Logs

Actual logs captured during multi-window testing & `@SceneStorage` state restoration in `SceneLifecycleExampleView.swift`:

```text
🪟 [SceneLifecycle] Scene initialized - Restored note: ""
🪟 [SceneLifecycle] Saved to @SceneStorage: "dddddd"
🪟 [SceneLifecycle] Scene transitioned: Scene Resigned Active
🪟 [SceneLifecycle] Scene transitioned: Scene Connected & Active
```

> [!NOTE]
> **Simulator Notes:**
> - When typing into `@SceneStorage` text fields on iOS Simulator, CoreHaptics logs benign file lookup warnings (`hapticpatternlibrary.plist`) because macOS keyboards lack iPhone Taptic Engine hardware.
> - Data written to `@SceneStorage` persists automatically across simulator app relaunches per scene.

---

## See Also

- [App Lifecycle](lifecycle_app.md)
- [ViewController Lifecycle](lifecycle_viewcontroller.md)
- [SwiftUI View Lifecycle](lifecycle_swiftui_view.md)


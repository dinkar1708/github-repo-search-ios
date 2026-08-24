# UIViewController Lifecycle Methods

Complete guide to UIViewController lifecycle methods in UIKit.

## 📁 Code Examples in Project

**Interactive Sample View:** [`ViewControllerLifecycleExampleView.swift`](../../../../github_repo_search_iOS_app/Modules/Feature/UI/Samples/Beginner/ViewControllerLifecycleExampleView.swift) - Live UIKit `UIViewController` embedded in SwiftUI via `UIViewControllerRepresentable` with real-time lifecycle tracking, modal sheets, and layout phases.

## Lifecycle Flow

```
ViewController Created
  ↓
init()
  ↓
loadView()
  ↓
viewDidLoad() ⭐ MOST COMMON
  ↓
viewWillAppear(_:)
  ↓
viewWillLayoutSubviews()
  ↓
viewDidLayoutSubviews()
  ↓
viewDidAppear(_:)
  ↓
[View is visible - user interacts]
  ↓
viewWillDisappear(_:)
  ↓
viewDidDisappear(_:)
  ↓
deinit
```

---

## 1. init() / init(coder:)

**When:** View controller is created

**Called:** Once per instance

```swift
class MyViewController: UIViewController {

    let viewModel: MyViewModel

    // Programmatic initialization
    init(viewModel: MyViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)

        print("✅ Init called")
    }

    // Storyboard initialization
    required init?(coder: NSCoder) {
        self.viewModel = MyViewModel()
        super.init(coder: coder)

        print("✅ Init from storyboard")
    }
}
```

### Use For:
- Initialize properties
- Dependency injection
- Set default values

### Don't:
- Access view (`self.view`) - not loaded yet
- Perform heavy operations
- Setup UI elements

---

## 2. loadView()

**When:** View hierarchy is loading

**Called:** Once (before viewDidLoad)

```swift
override func loadView() {
    // Option 1: Use default behavior
    super.loadView()

    // Option 2: Create custom root view
    let customView = CustomView()
    view = customView  // Set as root view
}
```

### Use For:
- Creating custom view hierarchy (no storyboards)
- Replace default view with custom view

### Don't:
- Call `super.loadView()` if creating custom view
- Access outlets (not connected yet)

### Example: Custom View

```swift
class MyViewController: UIViewController {

    override func loadView() {
        // Create custom root view
        let myView = UIView()
        myView.backgroundColor = .white

        // Add subviews
        let label = UILabel()
        label.text = "Hello"
        myView.addSubview(label)

        // Set as root view
        view = myView
    }
}
```

---

## 3. viewDidLoad() ⭐ MOST IMPORTANT

**When:** View loaded into memory

**Called:** Once per view controller instance

```swift
override func viewDidLoad() {
    super.viewDidLoad()

    print("✅ View loaded")

    // Setup UI
    setupNavigationBar()
    setupTableView()
    setupConstraints()

    // Configure delegates
    tableView.delegate = self
    tableView.dataSource = self

    // Add observers
    NotificationCenter.default.addObserver(
        self,
        selector: #selector(handleNotification),
        name: .dataUpdated,
        object: nil
    )

    // Load initial data
    viewModel.loadData()

    // Setup gesture recognizers
    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
    view.addGestureRecognizer(tapGesture)
}

func setupNavigationBar() {
    title = "My Screen"
    navigationItem.rightBarButtonItem = UIBarButtonItem(
        barButtonSystemItem: .add,
        target: self,
        action: #selector(addTapped)
    )
}
```

### Use For: ⭐
- One-time setup
- Configure UI elements
- Set delegates and data sources
- Add observers
- Register for notifications
- Setup gesture recognizers
- Initial data loading
- Setup constraints

### Don't:
- Layout calculations (frames not final yet)
- Start animations (view not visible)
- Show alerts (view not on screen)

---

## 4. viewWillAppear(_:)

**When:** View about to appear on screen

**Called:** Every time view appears

```swift
override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)

    print("🟡 View will appear")

    // Refresh data
    refreshData()
    tableView.reloadData()

    // Update UI
    updateNavigationBar()
    updateStatusBar()

    // Show/hide navigation bar
    navigationController?.setNavigationBarHidden(false, animated: animated)

    // Register for keyboard notifications
    registerKeyboardNotifications()

    // Track analytics
    Analytics.trackScreen("UserProfile")
}

func refreshData() {
    // Reload data from database
    users = DatabaseManager.shared.fetchUsers()

    // Or fetch from network
    viewModel.refreshUsers()
}

func updateNavigationBar() {
    // Update title, buttons based on current state
    navigationItem.rightBarButtonItem?.isEnabled = hasUnsavedChanges
}
```

### Use For: ⭐
- Refresh data (called every time)
- Update UI with latest data
- Show/hide navigation bar
- Register for keyboard notifications
- Start animations
- Analytics tracking
- Resume paused tasks

### Don't:
- Heavy computation (blocks UI)
- Long network requests (use background threads)

---

## 5. viewWillLayoutSubviews()

**When:** View about to layout its subviews

**Called:** Multiple times (before layout)

```swift
override func viewWillLayoutSubviews() {
    super.viewWillLayoutSubviews()

    print("🔵 Will layout subviews")

    // Prepare for layout
}
```

### Use For:
- Prepare for layout changes
- Rarely needed

---

## 6. viewDidLayoutSubviews()

**When:** View has laid out its subviews

**Called:** Multiple times (after layout, rotation, etc.)

```swift
override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()

    print("🟣 Did layout subviews")

    // Frames are now final
    print("View frame: \(view.frame)")

    // Manual layout
    customView.frame = CGRect(
        x: 0,
        y: 0,
        width: view.bounds.width,
        height: 200
    )

    // Update constraints if needed
    updateConstraintsForCurrentOrientation()
}

func updateConstraintsForCurrentOrientation() {
    if view.bounds.width > view.bounds.height {
        // Landscape
        applyLandscapeConstraints()
    } else {
        // Portrait
        applyPortraitConstraints()
    }
}
```

### Use For:
- Manual layout (setting frames)
- Adjust layout based on final frame sizes
- Update constraints dynamically
- Geometry-dependent calculations

---

## 7. viewDidAppear(_:)

**When:** View is now visible on screen

**Called:** After animation completes

```swift
override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)

    print("✅ View did appear")

    // Start animations
    startPulseAnimation()

    // Begin playback
    videoPlayer.play()

    // Show tutorial (first launch)
    if UserDefaults.standard.bool(forKey: "isFirstLaunch") {
        showTutorial()
    }

    // Request permissions
    requestLocationPermission()

    // Show alert
    if hasError {
        showErrorAlert()
    }

    // Start timer
    startRefreshTimer()

    // Focus text field
    searchTextField.becomeFirstResponder()
}
```

### Use For: ⭐
- Start animations
- Begin video/audio playback
- Show alerts or modals
- Request permissions
- Start timers
- Focus text fields (show keyboard)
- Analytics (screen fully visible)

---

## 8. viewWillDisappear(_:)

**When:** View about to leave screen

**Called:** Before disappearing

```swift
override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)

    print("🟠 View will disappear")

    // Save user input
    saveCurrentState()

    // Stop animations
    stopAllAnimations()

    // Pause media
    videoPlayer.pause()

    // Dismiss keyboard
    view.endEditing(true)

    // Unregister keyboard notifications
    unregisterKeyboardNotifications()

    // Stop timers
    refreshTimer?.invalidate()
}

func saveCurrentState() {
    // Save form data
    UserDefaults.standard.set(nameTextField.text, forKey: "userName")

    // Or save to database
    DatabaseManager.shared.saveUser(currentUser)
}
```

### Use For: ⭐
- Save user input
- Stop animations
- Pause media playback
- Dismiss keyboard
- Unregister keyboard notifications
- Stop timers
- Commit changes

---

## 9. viewDidDisappear(_:)

**When:** View no longer visible

**Called:** After disappearing

```swift
override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)

    print("🔴 View did disappear")

    // Stop tasks
    cancelNetworkRequests()

    // Release resources
    releaseHeavyResources()

    // Clear caches
    imageCache.clearMemoryCache()
}

func cancelNetworkRequests() {
    // Cancel ongoing API calls
    currentTask?.cancel()
}

func releaseHeavyResources() {
    // Release large objects, images, etc.
    largeDataSet = nil
    cachedImages.removeAll()
}
```

### Use For:
- Cancel network requests (if needed)
- Release resources
- Clean up temporary data
- Stop background tasks

---

## 10. deinit

**When:** View controller is being deallocated

**Called:** When VC is removed from memory

```swift
deinit {
    print("❌ Deinit called")

    // Remove observers
    NotificationCenter.default.removeObserver(self)

    // Cancel operations
    operationQueue.cancelAllOperations()

    // Clean up
    cleanup()
}
```

### Use For: ⭐
- Remove NotificationCenter observers
- Cancel operations/tasks
- Break retain cycles
- Final cleanup

### Warning:
- Should be called automatically
- If NOT called, you have a memory leak (retain cycle)

---

## Complete Example

```swift
class RepositoryDetailViewController: UIViewController {

    // MARK: - Properties
    let repository: Repository
    let viewModel: RepositoryDetailViewModel

    private var tableView: UITableView!
    private var refreshTimer: Timer?

    // MARK: - 1. Init
    init(repository: Repository) {
        self.repository = repository
        self.viewModel = RepositoryDetailViewModel(repository: repository)

        super.init(nibName: nil, bundle: nil)

        print("✅ Init")
    }

    required init?(coder: NSCoder) {
        fatalError("Storyboard not supported")
    }

    // MARK: - 2. Load View
    override func loadView() {
        super.loadView()
        print("🔵 Load view")
    }

    // MARK: - 3. View Did Load
    override func viewDidLoad() {
        super.viewDidLoad()
        print("✅ View did load")

        // Setup UI
        setupNavigationBar()
        setupTableView()

        // Load data
        viewModel.loadDetails()

        // Add observers
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(dataUpdated),
            name: .repositoryUpdated,
            object: nil
        )
    }

    func setupNavigationBar() {
        title = repository.name
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .action,
            target: self,
            action: #selector(shareTapped)
        )
    }

    func setupTableView() {
        tableView = UITableView(frame: view.bounds)
        tableView.delegate = self
        tableView.dataSource = self
        view.addSubview(tableView)
    }

    // MARK: - 4. View Will Appear
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("🟡 View will appear")

        // Refresh data
        viewModel.refreshData()
        tableView.reloadData()

        // Analytics
        Analytics.trackScreen("RepositoryDetail", properties: [
            "repo_id": repository.id
        ])
    }

    // MARK: - 5. View Did Layout Subviews
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        print("🟣 Did layout subviews")

        // Update table view frame
        tableView.frame = view.bounds
    }

    // MARK: - 6. View Did Appear
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("✅ View did appear")

        // Start refresh timer
        startRefreshTimer()
    }

    func startRefreshTimer() {
        refreshTimer = Timer.scheduledTimer(
            withTimeInterval: 60,
            repeats: true
        ) { [weak self] _ in
            self?.viewModel.refreshData()
        }
    }

    // MARK: - 7. View Will Disappear
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        print("🟠 View will disappear")

        // Stop timer
        refreshTimer?.invalidate()

        // Dismiss keyboard
        view.endEditing(true)
    }

    // MARK: - 8. View Did Disappear
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        print("🔴 View did disappear")

        // Cancel requests
        viewModel.cancelRequests()
    }

    // MARK: - 9. Deinit
    deinit {
        print("❌ Deinit")

        // Remove observers
        NotificationCenter.default.removeObserver(self)

        // Clean up
        refreshTimer?.invalidate()
    }

    // MARK: - Actions
    @objc func shareTapped() {
        // Share repository
    }

    @objc func dataUpdated() {
        tableView.reloadData()
    }
}
```

---

## Quick Reference Table

| Method | Called | Frequency | Use For |
|--------|--------|-----------|---------|
| `init` | VC created | Once | Initialize properties |
| `loadView()` | Loading view | Once | Custom view hierarchy |
| `viewDidLoad()` | View loaded | Once | One-time setup |
| `viewWillAppear` | Before appearing | Every time | Refresh data |
| `viewWillLayoutSubviews` | Before layout | Multiple | Prepare layout |
| `viewDidLayoutSubviews` | After layout | Multiple | Manual layout |
| `viewDidAppear` | After appearing | Every time | Start animations |
| `viewWillDisappear` | Before disappearing | Every time | Save state |
| `viewDidDisappear` | After disappearing | Every time | Clean up |
| `deinit` | VC deallocated | Once | Remove observers |

---

## Best Practices

### ✅ Do's

1. **Always call super first**
   ```swift
   override func viewDidLoad() {
       super.viewDidLoad() // ← Always
       // Your code
   }
   ```

2. **Use viewDidLoad for one-time setup**
3. **Use viewWillAppear to refresh data**
4. **Save state in viewWillDisappear**
5. **Remove observers in deinit**

### ❌ Don'ts

1. **Don't access view in init**
   ```swift
   // ❌ Crash!
   init() {
       super.init(nibName: nil, bundle: nil)
       view.backgroundColor = .red
   }
   ```

2. **Don't perform heavy work in viewDidLoad**
3. **Don't forget to remove NotificationCenter observers**

---

## 🔬 Verified Runtime Test Logs

Actual logs captured during real UIKit `UIViewController` embedded lifecycle and presentation testing in `ViewControllerLifecycleExampleView.swift`:

```text
🏛️ [ViewControllerLifecycle] [Embedded View] 0. init()
🏛️ [ViewControllerLifecycle] [Embedded View] 1. loadView()
🏛️ [ViewControllerLifecycle] [Embedded View] 2. viewDidLoad()
🏛️ [ViewControllerLifecycle] [Embedded View] 3. viewWillAppear(animated: false)
🏛️ [ViewControllerLifecycle] [Embedded View] 4. viewWillLayoutSubviews()
🏛️ [ViewControllerLifecycle] [Embedded View] 5. viewDidLayoutSubviews()
🏛️ [ViewControllerLifecycle] [Embedded View] 6. viewDidAppear(animated: true)
🏛️ [ViewControllerLifecycle] [Embedded View] 7. viewWillDisappear(animated: false)
🏛️ [ViewControllerLifecycle] [Embedded View] 8. viewDidDisappear(animated: false)
🏛️ [ViewControllerLifecycle] [Embedded View] 9. deinit (Deallocated)
```

> [!NOTE]
> **Key Observations from Test Logs**:
> 1. **Mounting:** Follows the strict order `init()` $\rightarrow$ `loadView()` $\rightarrow$ `viewDidLoad()` $\rightarrow$ `viewWillAppear` $\rightarrow$ `viewWillLayoutSubviews` $\rightarrow$ `viewDidLayoutSubviews` $\rightarrow$ `viewDidAppear`.
> 2. **Unmounting:** When the controller is removed, `viewWillDisappear` $\rightarrow$ `viewDidDisappear` $\rightarrow$ `deinit` executes cleanly, proving zero memory retain cycles.

---

## See Also

- [Navigation Controller Lifecycle](lifecycle_navigation_controller.md)
- [App Lifecycle](lifecycle_app.md)
- [SwiftUI View Lifecycle](lifecycle_swiftui_view.md)


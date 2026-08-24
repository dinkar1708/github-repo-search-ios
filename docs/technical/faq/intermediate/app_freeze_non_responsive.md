# iOS App Freeze & Non-Responsive Scenarios

Complete guide to understanding why iOS apps freeze, common scenarios, and how to prevent them.

## What is App Freeze?

An app **freezes** when it stops responding to user input. The screen appears "stuck" and touch events don't work.

**Cause:** Main thread is blocked - it's busy doing heavy work instead of responding to user interactions.

### ⚠️ Critical Understanding

**These code examples don't crash or throw exceptions!**

The code runs successfully and completes without errors. The problem is:
- ✅ Code executes successfully
- ✅ No exceptions thrown
- ✅ No crashes
- ❌ **BUT user is completely blocked**
- ❌ **Screen freezes**
- ❌ **Can't tap buttons, scroll, or interact**
- ❌ **App appears "stuck" or "hanging"**

**Example:**
```swift
// ❌ This code works perfectly... but freezes UI!
func loadData() {
    // This takes 5 seconds - no error, but user can't do anything!
    let data = try? Data(contentsOf: url)  // ✅ Works, ❌ But blocks UI
    let repos = parseJSON(data)             // ✅ Works, ❌ But blocks UI

    // App was frozen for 5 seconds - user frustrated!
    tableView.reloadData()
}
```

**From User's Perspective:**
```
User taps button
  ↓
Screen freezes (shows last frame)
  ↓
User tries to tap, scroll, swipe → Nothing happens! 😡
  ↓
User thinks: "App is broken" or "App crashed"
  ↓
(5 seconds later)
  ↓
Screen suddenly updates
  ↓
User: "This app is terrible!"
```

**Key Point:** Silent freeze is worse than a crash because:
1. No error message to user
2. App looks broken but hasn't crashed
3. User doesn't know if app is working or dead
4. Can lead to force quit and bad reviews

### Simple Example: sleep() Freezes UI

```swift
// ❌ This code runs perfectly, no errors, BUT freezes UI!
@objc func buttonTapped() {
    print("Button tapped")

    // ✅ This works perfectly - no exceptions
    // ❌ BUT freezes UI for 3 seconds
    sleep(3)

    print("Done sleeping")

    // User was completely blocked for 3 seconds!
    label.text = "Done"
}
```

**What User Experiences:**
1. User taps button
2. Screen **freezes** (shows exact same frame)
3. User tries to tap again → **Nothing happens**
4. User tries to scroll → **Nothing happens**
5. User thinks "App is broken!"
6. **3 seconds later** → Screen suddenly updates
7. User: "Worst app ever!" 😡

**Code Perspective:**
- ✅ No compiler errors
- ✅ No runtime exceptions
- ✅ Code executes successfully
- ✅ print statements work
- ❌ **BUT UI is completely frozen**

**This is the problem we're solving in all scenarios below!**

---

## Main Thread: The UI Thread

### What is the Main Thread?

The **main thread** (also called UI thread) is responsible for:
- Handling user interactions (touches, gestures)
- Updating the UI
- Animations
- Layout calculations

```
Main Thread (60 FPS = 16.67ms per frame)
  ├─ Handle touch events
  ├─ Update UI
  ├─ Layout views
  ├─ Render frame
  └─ Repeat every 16.67ms
```

### The Golden Rule

**Never block the main thread for more than 16ms!**

If main thread is busy for > 16ms, app drops frames and appears frozen.

---

## Important: Main Thread ↔ Background Thread Rules

### ✅ GOOD: Main → Background → Main Pattern

```swift
// Running on main thread
func fetchData() {
    print("Step 1: On main thread")

    // ✅ GOOD: Dispatch from main to background
    DispatchQueue.global(qos: .userInitiated).async {
        print("Step 2: On background thread - safe!")

        // Heavy work here (network, parsing, etc.)
        let data = self.performHeavyWork()

        // ✅ GOOD: Return to main thread for UI updates
        DispatchQueue.main.async {
            print("Step 3: Back on main thread")
            self.updateUI(with: data)  // ✅ Safe!
        }
    }
}
```

**This is the CORRECT pattern!** No crashes, no freezes.

### ❌ BAD: UI Updates from Background Thread

```swift
// ❌ BAD: This will crash or show purple warning
DispatchQueue.global().async {
    // On background thread
    let data = fetchData()

    // ❌ CRASH/WARNING: Updating UI from background thread!
    self.tableView.reloadData()
    self.label.text = "Done"
    self.view.backgroundColor = .red
}
```

**Error:**
```
⚠️ Main Thread Checker: UI API called on a background thread
[UITableView reloadData] must be called from main thread only
```

### ❌ BAD: Heavy Work on Main Thread

```swift
// ❌ BAD: This blocks main thread
func loadData() {
    // Still on main thread
    let data = try? Data(contentsOf: url)  // Blocks for 2+ seconds!
    let repos = parseJSON(data)             // Blocks for 1+ second!

    // App FROZEN for 3+ seconds
    tableView.reloadData()
}
```

### The Correct Flow Diagram

```
┌─────────────────────────────────────────────────┐
│          MAIN THREAD (UI Thread)                │
│  - Handle user touches                          │
│  - Update UI                                    │
│  - Animations                                   │
└─────────────────────────────────────────────────┘
         │
         │ ✅ Dispatch to background (GOOD!)
         ↓
┌─────────────────────────────────────────────────┐
│       BACKGROUND THREAD (Worker Thread)         │
│  - Network requests                             │
│  - JSON parsing                                 │
│  - Database queries                             │
│  - Image processing                             │
│  - Heavy computations                           │
└─────────────────────────────────────────────────┘
         │
         │ ✅ Dispatch back to main (GOOD!)
         ↓
┌─────────────────────────────────────────────────┐
│          MAIN THREAD (UI Thread)                │
│  - Update UI with results                       │
│  - Reload table view                            │
│  - Show/hide loading indicators                 │
└─────────────────────────────────────────────────┘
```

### Quick Reference: What's Safe Where?

| Operation | Main Thread | Background Thread |
|-----------|-------------|-------------------|
| **Touch events** | ✅ Always | ❌ Never |
| **Update UI** | ✅ Always | ❌ Never |
| **Network calls** | ❌ Never | ✅ Always |
| **JSON parsing** | ❌ Never (if large) | ✅ Always |
| **Database queries** | ❌ Never (if large) | ✅ Always |
| **Image processing** | ❌ Never | ✅ Always |
| **Dispatch to other thread** | ✅ Yes | ✅ Yes |

### Real-World Example: Complete Pattern

```swift
class RepositoryViewController: UIViewController {

    var repositories: [Repository] = []

    // Called when user taps refresh button
    @objc func refreshTapped() {
        // ✅ Step 1: On main thread (button action)
        print("1. On main thread - user tapped refresh")

        // Show loading indicator (UI update - safe on main thread)
        activityIndicator.startAnimating()

        // ✅ Step 2: Dispatch to background thread
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }

            print("2. On background thread - doing heavy work")

            // ✅ Safe: Heavy work on background thread
            let url = URL(string: "https://api.github.com/repos")!
            let data = try? Data(contentsOf: url)  // Network call - OK here!

            // Parse JSON (heavy computation - OK here!)
            let decoder = JSONDecoder()
            let repos = try? decoder.decode([Repository].self, from: data!)

            print("3. Still on background - work done")

            // ✅ Step 3: Dispatch BACK to main thread for UI updates
            DispatchQueue.main.async {
                print("4. Back on main thread - updating UI")

                // ✅ Safe: UI updates on main thread
                self.repositories = repos ?? []
                self.tableView.reloadData()
                self.activityIndicator.stopAnimating()

                print("5. Done - UI updated")
            }
        }

        print("6. Main thread continues immediately - no freeze!")
        // Main thread is free to handle user interactions
    }
}
```

**Console Output:**
```
1. On main thread - user tapped refresh
6. Main thread continues immediately - no freeze!
2. On background thread - doing heavy work
3. Still on background - work done
4. Back on main thread - updating UI
5. Done - UI updated
```

**Key Point:** Main thread continues immediately at step 6, while background thread does heavy work (steps 2-3).

### Modern Swift Concurrency Pattern

```swift
// ✅ Even better with async/await
func refreshData() async {
    // Show loading
    await MainActor.run {
        activityIndicator.startAnimating()
    }

    // Heavy work (automatically on background)
    let repos = try? await apiClient.fetchRepositories()

    // Update UI (back to main thread)
    await MainActor.run {
        self.repositories = repos ?? []
        self.tableView.reloadData()
        activityIndicator.stopAnimating()
    }
}

// Call it
Task {
    await refreshData()
}
```

**Remember:**
- Main → Background = ✅ GOOD (prevents freezing)
- Background → Main = ✅ GOOD (for UI updates)
- Background → UI directly = ❌ BAD (crash/warning)
- Main thread → Heavy work = ❌ BAD (freezes app)

---

## Common Scenarios That Cause App Freeze

### 1. Heavy Computation on Main Thread

#### ❌ Scenario: Parsing Large JSON

```swift
class RepositoryViewController: UIViewController {

    func loadData() {
        // ❌ BAD: Blocking main thread
        let jsonData = fetchLargeJSON() // Takes 2 seconds - ✅ WORKS, ❌ BLOCKS UI
        let repositories = parseJSON(jsonData) // Takes 3 seconds - ✅ WORKS, ❌ BLOCKS UI

        // ✅ Code executed successfully, no errors!
        // ❌ BUT app was FROZEN for 5 seconds!

        tableView.reloadData()
    }
}
```

**What Happens:**
- ✅ Code runs successfully, no exceptions
- ✅ JSON parsed correctly
- ❌ **BUT user is completely blocked for 5 seconds**
- User sees frozen screen, can't tap or scroll
- Loading spinner (if any) doesn't even animate!

**Result:** App freezes for 5 seconds. Code works, but UX is terrible!

#### ✅ Solution: Use Background Thread

```swift
func loadData() {
    DispatchQueue.global(qos: .userInitiated).async {
        // Heavy work on background thread
        let jsonData = self.fetchLargeJSON()
        let repositories = self.parseJSON(jsonData)

        // Update UI on main thread
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
}
```

---

### 2. Network Request on Main Thread

#### ❌ Scenario: Synchronous Network Call

```swift
func fetchRepositories() {
    // ❌ BAD: Synchronous network call on main thread
    let url = URL(string: "https://api.github.com/repos")!
    let data = try? Data(contentsOf: url) // ✅ WORKS, ❌ BLOCKS UI for 2-5 seconds!

    // ✅ Network request succeeds, data received
    // ❌ BUT app was completely FROZEN during request

    let repos = try? JSONDecoder().decode([Repository].self, from: data!)
    repositories = repos ?? []
}
```

**What Happens:**
- ✅ Network request succeeds
- ✅ Data downloaded successfully
- ✅ No errors or crashes
- ❌ **BUT user is blocked for entire duration (2-5 seconds)**
- User sees frozen screen, thinks app is broken
- Can't even tap "Cancel" or go back!

**Result:** App completely frozen during network request. Code works perfectly, user experience terrible!

#### ✅ Solution: Async Network Call

```swift
func fetchRepositories() {
    URLSession.shared.dataTask(with: url) { data, response, error in
        guard let data = data else { return }

        let repos = try? JSONDecoder().decode([Repository].self, from: data)

        DispatchQueue.main.async {
            self.repositories = repos ?? []
            self.tableView.reloadData()
        }
    }.resume()
}
```

---

### 3. Database Operations on Main Thread

#### ❌ Scenario: Core Data Fetch on Main Thread

```swift
func loadUsers() {
    // ❌ BAD: Heavy database query on main thread
    let fetchRequest: NSFetchRequest<User> = User.fetchRequest()
    fetchRequest.predicate = NSPredicate(format: "age > 18")

    let users = try? context.fetch(fetchRequest) // Blocks if large dataset

    // App frozen during fetch
    self.users = users ?? []
}
```

**Result:** App freezes while fetching thousands of records.

#### ✅ Solution: Background Context

```swift
func loadUsers() {
    let backgroundContext = persistentContainer.newBackgroundContext()

    backgroundContext.perform {
        let fetchRequest: NSFetchRequest<User> = User.fetchRequest()
        let users = try? backgroundContext.fetch(fetchRequest)

        DispatchQueue.main.async {
            self.users = users ?? []
        }
    }
}
```

---

### 4. Image Processing on Main Thread

#### ❌ Scenario: Resizing Large Images

```swift
func processImage(_ image: UIImage) {
    // ❌ BAD: Heavy image processing on main thread
    let resized = image.resize(to: CGSize(width: 1000, height: 1000))
    let filtered = resized.applyFilter(.blur)
    let compressed = filtered.jpegData(compressionQuality: 0.8)

    // App frozen during image processing

    imageView.image = UIImage(data: compressed!)
}
```

**Result:** App freezes during image processing (especially for large images).

#### ✅ Solution: Background Thread

```swift
func processImage(_ image: UIImage) {
    DispatchQueue.global(qos: .userInitiated).async {
        let resized = image.resize(to: CGSize(width: 1000, height: 1000))
        let filtered = resized.applyFilter(.blur)

        DispatchQueue.main.async {
            self.imageView.image = filtered
        }
    }
}
```

---

### 5. File I/O on Main Thread

#### ❌ Scenario: Reading Large File

```swift
func loadFile() {
    // ❌ BAD: Reading large file on main thread
    let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    let fileURL = url.appendingPathComponent("large_file.json")

    let data = try? Data(contentsOf: fileURL) // Blocks main thread

    // App frozen during file read

    processData(data)
}
```

**Result:** App freezes while reading large file from disk.

#### ✅ Solution: Background Thread

```swift
func loadFile() {
    DispatchQueue.global(qos: .utility).async {
        let data = try? Data(contentsOf: fileURL)

        DispatchQueue.main.async {
            self.processData(data)
        }
    }
}
```

---

### 6. Infinite Loop / Long-Running Loop

#### ❌ Scenario: Processing Large Array

```swift
func processRepositories() {
    // ❌ BAD: Long loop on main thread
    for repo in repositories {
        // Complex processing
        let processed = performHeavyCalculation(repo) // 10ms each
        processedRepos.append(processed)
    }

    // If 1000 repositories × 10ms = 10 seconds FROZEN!

    tableView.reloadData()
}
```

**Result:** App frozen for entire loop duration.

#### ✅ Solution: Batch Processing on Background Thread

```swift
func processRepositories() {
    DispatchQueue.global(qos: .userInitiated).async {
        var processed: [Repository] = []

        for repo in self.repositories {
            let result = self.performHeavyCalculation(repo)
            processed.append(result)
        }

        DispatchQueue.main.async {
            self.processedRepos = processed
            self.tableView.reloadData()
        }
    }
}
```

---

### 7. viewDidLoad Doing Heavy Work

#### ❌ Scenario: Loading Everything in viewDidLoad

```swift
override func viewDidLoad() {
    super.viewDidLoad()

    // ❌ BAD: All heavy work in viewDidLoad
    loadDataFromDatabase()      // 1 second
    fetchFromNetwork()          // 2 seconds
    processImages()             // 3 seconds
    generateReports()           // 2 seconds

    // View controller takes 8 seconds to appear!
    // App appears FROZEN
}
```

**Result:** User sees blank/frozen screen for 8 seconds.

#### ✅ Solution: Move Heavy Work to Background

```swift
override func viewDidLoad() {
    super.viewDidLoad()

    // Light setup only
    setupUI()

    // Heavy work on background
    loadDataAsync()
}

func loadDataAsync() {
    DispatchQueue.global(qos: .userInitiated).async {
        self.loadDataFromDatabase()
        self.processImages()

        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
}
```

---

### 8. Expensive Layout Calculations

#### ❌ Scenario: Complex viewDidLayoutSubviews

```swift
override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()

    // ❌ BAD: Heavy calculations on every layout pass
    for i in 0..<1000 {
        let view = subviews[i]
        // Complex calculations
        let frame = calculateComplexFrame(for: view) // 5ms
        view.frame = frame
    }

    // Called multiple times, freezes on rotation, keyboard, etc.
}
```

**Result:** App freezes during layout (rotation, keyboard appearance).

#### ✅ Solution: Optimize Layout

```swift
// Use Auto Layout instead
// Or cache calculations
var cachedFrames: [CGRect] = []

override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()

    // Use cached frames
    for (index, view) in subviews.enumerated() {
        view.frame = cachedFrames[index]
    }
}
```

---

### 9. Synchronous Wait / Sleep

#### ❌ Scenario: Using sleep() on Main Thread

```swift
func showLoadingAnimation() {
    showSpinner()

    // ❌ BAD: Sleep on main thread
    sleep(3) // App FROZEN for 3 seconds!

    hideSpinner()
}
```

**Result:** App completely frozen, spinner doesn't even animate!

#### ✅ Solution: Use DispatchQueue.asyncAfter

```swift
func showLoadingAnimation() {
    showSpinner()

    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
        self.hideSpinner()
    }
}
```

---

### 10. Excessive UI Updates

#### ❌ Scenario: Updating UI in Tight Loop

```swift
func updateProgress() {
    // ❌ BAD: Updating UI 1000 times per second
    for i in 0...1000 {
        progressBar.progress = Float(i) / 1000.0
        // Triggers layout/render 1000 times!
    }

    // App freezes during updates
}
```

**Result:** App freezes, progress bar stutters.

#### ✅ Solution: Throttle Updates

```swift
func updateProgress() {
    DispatchQueue.global(qos: .userInitiated).async {
        for i in 0...1000 {
            // Update UI only every 10th iteration
            if i % 10 == 0 {
                DispatchQueue.main.async {
                    self.progressBar.progress = Float(i) / 1000.0
                }
            }

            // Do actual work
            self.processItem(i)
        }
    }
}
```

---

## iOS Watchdog: When iOS Kills Your App

iOS has a **watchdog** that monitors app responsiveness. If your app is unresponsive for too long, iOS **kills it**.

### Watchdog Timeouts

| Event | Timeout | What Happens |
|-------|---------|--------------|
| **App Launch** | 20 seconds | App killed if not responsive |
| **Resume from Background** | 10 seconds | App killed |
| **Main Thread Hang** | 10-20 seconds | App killed |
| **viewWillAppear** | ~1 second | Janky experience |

### Crash Report

```
Exception Type:  00000020
Exception Codes: 0x8badf00d
Exception Note:  SIMULATED (this is NOT a crash)

Application Specific Information:
com.example.app failed to launch in time

Elapsed total CPU time (seconds): 22.340 (user 21.890, system 0.450)
```

**0x8badf00d** = "ate bad food" = watchdog timeout!

---

## How to Detect App Freeze

### 1. User Experience

**Symptoms:**
- Screen doesn't respond to touch
- Animations stop
- Scrolling stutters
- App feels "laggy"

### 2. Xcode Debug Gauge

**While debugging:**
1. Run app in Xcode
2. Open Debug Navigator (Cmd+7)
3. Watch "CPU" and "Threads"
4. Main thread at 100% = frozen!

### 3. Instruments - Time Profiler

**Steps:**
1. Product → Profile (Cmd+I)
2. Select "Time Profiler"
3. Record while using app
4. Look for heavy call stacks on Main Thread

### 4. Instruments - Hangs

**Steps:**
1. Product → Profile
2. Select "System Trace"
3. Look for "Main Thread Hangs"

---

## How to Prevent App Freeze

### Rule 1: Keep Main Thread Free

```swift
// ✅ GOOD Pattern
func doWork() {
    DispatchQueue.global(qos: .userInitiated).async {
        // Heavy work on background thread
        let result = self.heavyComputation()

        // Update UI on main thread
        DispatchQueue.main.async {
            self.updateUI(with: result)
        }
    }
}
```

### Rule 2: Use Async/Await

```swift
// ✅ Modern Swift Concurrency
func loadData() async {
    // Automatically runs on background
    let data = try await apiClient.fetchData()

    // Update UI
    await MainActor.run {
        self.repositories = data
        self.tableView.reloadData()
    }
}
```

### Rule 3: Optimize Algorithms

```swift
// ❌ BAD: O(n²) algorithm
for item1 in items {
    for item2 in items {
        compare(item1, item2)
    }
}

// ✅ GOOD: O(n) algorithm
let itemSet = Set(items)
for item in items {
    if itemSet.contains(item) {
        process(item)
    }
}
```

### Rule 4: Lazy Loading

```swift
// ✅ Load data as needed, not all at once
class RepositoryListViewController: UIViewController {

    func tableView(_ tableView: UITableView,
                   willDisplay cell: UITableViewCell,
                   forRowAt indexPath: IndexPath) {

        // Load image only when cell appears
        loadImage(for: indexPath)
    }
}
```

### Rule 5: Pagination

```swift
// ✅ Load data in chunks
func loadRepositories(page: Int) {
    apiClient.fetch(page: page, limit: 20) { repos in
        self.repositories.append(contentsOf: repos)
        self.tableView.reloadData()
    }
}
```

---

## Complete Good Example

```swift
class RepositoryListViewController: UIViewController {

    var repositories: [Repository] = []
    var currentTask: URLSessionDataTask?

    override func viewDidLoad() {
        super.viewDidLoad()

        // ✅ Light setup only
        setupUI()

        // ✅ Load data asynchronously
        loadRepositories()
    }

    func setupUI() {
        // Quick UI setup
        tableView.register(RepositoryCell.self, forCellReuseIdentifier: "cell")
    }

    func loadRepositories() {
        // ✅ Show loading indicator
        showLoadingIndicator()

        // ✅ Network call on background thread (URLSession handles this)
        currentTask = apiClient.fetchRepositories { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success(let data):
                // ✅ Heavy parsing on background thread
                DispatchQueue.global(qos: .userInitiated).async {
                    let repos = try? JSONDecoder().decode([Repository].self, from: data)

                    // ✅ Update UI on main thread
                    DispatchQueue.main.async {
                        self.repositories = repos ?? []
                        self.tableView.reloadData()
                        self.hideLoadingIndicator()
                    }
                }

            case .failure(let error):
                DispatchQueue.main.async {
                    self.showError(error)
                    self.hideLoadingIndicator()
                }
            }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        // ✅ Cancel ongoing work
        currentTask?.cancel()
    }
}
```

---

## Testing for Responsiveness

### 1. Simulate Slow Network

**Settings → Developer → Network Link Conditioner**
- Enable "3G" or "LTE" profile
- Test app responsiveness

### 2. Main Thread Checker

**Xcode Scheme → Run → Diagnostics**
- Enable "Main Thread Checker"
- Xcode warns if you update UI on background thread

### 3. Performance Testing

```swift
func testPerformance() {
    measure {
        // Code to test
        viewController.loadRepositories()
    }

    // Should complete in < 1 second
}
```

---

## Quick Reference

### ❌ Operations That Block Main Thread

- Synchronous network calls
- Large JSON parsing
- Heavy database queries
- Image processing
- File I/O
- Encryption/decryption
- Complex calculations
- sleep() / Thread.sleep()

### ✅ How to Fix

Use background threads:
- `DispatchQueue.global(qos: .userInitiated).async`
- `URLSession` (async by default)
- `Task { }` (Swift Concurrency)
- `OperationQueue`

---

## Summary

**Main Thread Rule:** Keep main thread free for UI!

**Common Causes:**
1. Heavy computation on main thread
2. Synchronous network calls
3. Large database queries
4. Image processing
5. File I/O
6. Infinite loops
7. Heavy viewDidLoad
8. Complex layouts
9. Synchronous waits
10. Excessive UI updates

**Solution:** Move heavy work to background threads!

---

## See Also

- [Background Thread Execution Patterns](background_thread_execution_patterns.md)
- [Memory Leak Detection](../advanced/memory_leak_detection.md)
- [App Lifecycle](../beginner/lifecycle_app.md)

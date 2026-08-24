# SwiftUI View Lifecycle

Complete guide to SwiftUI View lifecycle events and modifiers.

## 📁 Code Examples in Project

**Real implementations:**

1. **`HomeView.swift:16-21`** - View init() customization
```swift
init() {
    // customize table view for modern appearance
    UITableViewCell.appearance().backgroundColor = .clear
    UITableView.appearance().backgroundColor = .clear
    UITableView.appearance().separatorStyle = .none
}
```

2. **`UserProfileView.swift`** - Full lifecycle with onAppear/onDisappear

3. **`SettingsView.swift`** - State management with @AppStorage

**Interactive Sample View:** [`SwiftUIViewLifecycleExampleView.swift`](../../../../github_repo_search_iOS_app/Modules/Feature/UI/Samples/Beginner/SwiftUIViewLifecycleExampleView.swift) - Live demonstration of child view mounting, explicit identity (`.id`), state observation (`.onChange`), and async `.task` cancellation.

**Related files:**
- `github_repo_search_iOS_app/Modules/Feature/UI/Home/View/HomeView.swift` - Repository search with lifecycle
- `github_repo_search_iOS_app/Modules/Feature/UI/UserProfile/View/UserProfileView.swift` - User profile lifecycle
- `github_repo_search_iOS_app/Modules/Feature/UI/Settings/View/SettingsView.swift` - Settings with @AppStorage
- `github_repo_search_iOS_app/Modules/Feature/UI/Favorites/View/FavoritesView.swift` - Favorites management
- `github_repo_search_iOS_app/Modules/Feature/UI/Samples/Beginner/SwiftUIViewLifecycleExampleView.swift` - Interactive Sample View

## Lifecycle Flow

```
View Created
  ↓
init()
  ↓
body (first render)
  ↓
.onAppear
  ↓
[View visible - user interacts]
  ↓
State changes → body (re-render)
  ↓
.onChange triggered
  ↓
.onDisappear
  ↓
View destroyed
```

---

## 1. init()

**When:** View struct is instantiated

**Called:** When view is created

```swift
struct UserProfileView: View {
    let user: User
    @State private var isLoading = false

    init(user: User) {
        self.user = user
        print("✅ View initialized for \(user.name)")

        // Can modify @State here
        _isLoading = State(initialValue: true)
    }

    var body: some View {
        Text(user.name)
    }
}
```

### Use For:
- Initialize properties
- Transform input data
- Set initial @State values

### Don't:
- Side effects (network calls, database writes)
- Heavy computation
- Access @StateObject (not initialized yet)

---

## 2. body

**When:** SwiftUI renders the view

**Called:** Every time state changes (many times!)

```swift
struct CounterView: View {
    @State private var count = 0

    var body: some View {
        print("🔄 Body rendered - count: \(count)")

        return VStack {
            Text("Count: \(count)")

            Button("Increment") {
                count += 1 // Triggers body re-render
            }
        }
    }
}
```

### Use For:
- Declare UI structure
- Use @State, @Binding, @ObservedObject
- Apply view modifiers
- Conditional rendering

### Don't: ⚠️
- Side effects (network calls)
- Database operations
- Heavy computation (use computed properties)
- Modify @State directly

```swift
// ❌ BAD - Don't do this!
var body: some View {
    count += 1 // Infinite loop!

    return Text("Count: \(count)")
}

// ✅ GOOD
var body: some View {
    Text("Count: \(count)")
        .onAppear {
            // Side effects here
            loadData()
        }
}
```

---

## 3. .onAppear

**When:** View appears on screen

**Called:** Every time view appears

```swift
struct RepositoryListView: View {
    @StateObject private var viewModel = RepositoryViewModel()

    var body: some View {
        List(viewModel.repositories) { repo in
            Text(repo.name)
        }
        .onAppear {
            print("✅ View appeared")

            // Load data
            viewModel.loadRepositories()

            // Analytics
            Analytics.trackScreen("RepositoryList")

            // Start timer
            viewModel.startRefreshTimer()
        }
    }
}
```

### Use For: ⭐
- Load data
- Start animations
- Analytics tracking
- Start timers
- Register observers
- Focus text fields

### Similar to UIKit:
`viewWillAppear` + `viewDidAppear`

---

## 4. .onDisappear

**When:** View leaves the screen

**Called:** When view is removed

```swift
struct VideoPlayerView: View {
    @State private var player = AVPlayer()

    var body: some View {
        VideoPlayer(player: player)
            .onAppear {
                player.play()
            }
            .onDisappear {
                print("🔴 View disappeared")

                // Pause playback
                player.pause()

                // Save position
                savePlaybackPosition()

                // Stop timer
                stopTimer()
            }
    }

    func savePlaybackPosition() {
        UserDefaults.standard.set(
            player.currentTime().seconds,
            forKey: "lastPlaybackPosition"
        )
    }
}
```

### Use For: ⭐
- Save state
- Stop animations
- Pause media
- Stop timers
- Clean up resources
- Cancel tasks

### Similar to UIKit:
`viewWillDisappear` + `viewDidDisappear`

---

## 5. .task { }

**When:** View appears (async version of onAppear)

**Called:** When view appears

**Auto-cancelled:** When view disappears

```swift
struct UserListView: View {
    @StateObject private var viewModel = UserViewModel()

    var body: some View {
        List(viewModel.users) { user in
            Text(user.name)
        }
        .task {
            // Async work - auto-cancelled on disappear
            await viewModel.fetchUsers()
        }
        .task(id: viewModel.searchQuery) {
            // Re-runs when searchQuery changes
            await viewModel.search()
        }
    }
}

class UserViewModel: ObservableObject {
    @Published var users: [User] = []
    @Published var searchQuery = ""

    func fetchUsers() async {
        let users = try? await apiClient.fetchUsers()
        self.users = users ?? []
    }

    func search() async {
        let results = try? await apiClient.search(query: searchQuery)
        self.users = results ?? []
    }
}
```

### Use For: ⭐
- Async data loading
- Network requests
- Database queries
- Long-running tasks
- Structured concurrency

### Benefits:
- Auto-cancelled when view disappears
- No need to manually cancel
- Uses Swift Concurrency
- Re-runs when id changes

---

## 6. .onChange(of:)

**When:** State value changes

**Called:** Every time the observed value changes

```swift
struct SearchView: View {
    @State private var searchText = ""
    @State private var results: [Result] = []
    @State private var searchCount = 0

    var body: some View {
        VStack {
            TextField("Search", text: $searchText)

            Text("Searched \(searchCount) times")

            List(results) { result in
                Text(result.name)
            }
        }
        .onChange(of: searchText) { oldValue, newValue in
            print("🔄 Search changed: \(oldValue) → \(newValue)")

            searchCount += 1

            // Trigger search
            performSearch(query: newValue)
        }
    }

    func performSearch(query: String) {
        // Perform search
    }
}
```

### Multiple onChange

```swift
struct ProfileEditView: View {
    @State private var name = ""
    @State private var email = ""
    @State private var age = 0

    var body: some View {
        Form {
            TextField("Name", text: $name)
            TextField("Email", text: $email)
            Stepper("Age: \(age)", value: $age)
        }
        .onChange(of: name) { _, newName in
            validateName(newName)
        }
        .onChange(of: email) { _, newEmail in
            validateEmail(newEmail)
        }
        .onChange(of: age) { _, newAge in
            validateAge(newAge)
        }
    }
}
```

### Use For: ⭐
- React to state changes
- Trigger side effects
- Validation
- Update dependent state
- Logging/analytics

---

## 7. .onReceive

**When:** Publisher emits a value

**Called:** Every time publisher emits

```swift
import Combine

struct TimerView: View {
    @State private var currentTime = Date()

    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack {
            Text(currentTime, style: .time)
                .font(.largeTitle)
        }
        .onReceive(timer) { time in
            print("⏰ Timer fired: \(time)")
            currentTime = time
        }
    }
}
```

### NotificationCenter Example

```swift
struct NotificationView: View {
    @State private var message = ""

    var body: some View {
        Text(message)
            .onReceive(NotificationCenter.default.publisher(
                for: UIApplication.didBecomeActiveNotification
            )) { _ in
                message = "App became active"
            }
    }
}
```

### Use For:
- Listen to Combine publishers
- React to NotificationCenter
- Handle timers
- Observe external changes

---

## 8. .onSubmit

**When:** User submits (e.g., Return key on keyboard)

```swift
struct LoginView: View {
    @State private var username = ""
    @State private var password = ""

    var body: some View {
        VStack {
            TextField("Username", text: $username)
                .onSubmit {
                    // Focus next field
                }

            SecureField("Password", text: $password)
                .onSubmit {
                    performLogin()
                }

            Button("Login", action: performLogin)
        }
    }

    func performLogin() {
        print("🔐 Login submitted")
    }
}
```

---

## Property Wrappers Lifecycle

### @State

```swift
struct CounterView: View {
    @State private var count = 0  // Survives view re-renders

    var body: some View {
        Button("Count: \(count)") {
            count += 1
        }
    }
}
```

**Lifecycle:**
- Created with view
- Survives body re-renders
- Destroyed with view

---

### @StateObject

```swift
struct UserListView: View {
    @StateObject private var viewModel = UserViewModel()  // Owned by view

    var body: some View {
        List(viewModel.users) { user in
            Text(user.name)
        }
    }
}
```

**Lifecycle:**
- Created on first render
- Survives view re-renders
- Survives rotation
- Destroyed when view is destroyed

---

### @ObservedObject

```swift
struct UserDetailView: View {
    @ObservedObject var viewModel: UserViewModel  // NOT owned by view

    var body: some View {
        Text(viewModel.user.name)
    }
}
```

**Lifecycle:**
- Not owned by this view
- Passed from parent
- Lifecycle managed by owner (parent)

---

### @Binding

```swift
struct ToggleView: View {
    @Binding var isOn: Bool  // Reference to parent's state

    var body: some View {
        Toggle("Switch", isOn: $isOn)
    }
}
```

**Lifecycle:**
- Two-way binding to parent's state
- Changes reflect in parent
- Lifecycle tied to source

---

## Complete Example

```swift
import SwiftUI
import Combine

struct RepositorySearchView: View {

    // MARK: - Properties
    @StateObject private var viewModel = SearchViewModel()
    @State private var searchText = ""
    @State private var showFilters = false

    // MARK: - 1. Init
    init() {
        print("✅ View initialized")
    }

    // MARK: - 2. Body
    var body: some View {
        print("🔄 Body rendered")

        return NavigationView {
            VStack {
                // Search bar
                TextField("Search repositories", text: $searchText)
                    .textFieldStyle(.roundedBorder)
                    .padding()
                    .onSubmit {
                        viewModel.search(query: searchText)
                    }

                // Filters
                if showFilters {
                    FilterView(filters: $viewModel.filters)
                }

                // Results
                if viewModel.isLoading {
                    ProgressView()
                } else {
                    List(viewModel.repositories) { repo in
                        RepositoryRow(repository: repo)
                    }
                }
            }
            .navigationTitle("Search")
            .toolbar {
                Button("Filters") {
                    showFilters.toggle()
                }
            }
        }
        // MARK: - 3. onAppear
        .onAppear {
            print("✅ View appeared")
            viewModel.startSession()
            Analytics.trackScreen("RepositorySearch")
        }
        // MARK: - 4. task
        .task {
            await viewModel.loadTrendingRepositories()
        }
        .task(id: searchText) {
            // Re-runs when searchText changes
            if !searchText.isEmpty {
                await viewModel.search(query: searchText)
            }
        }
        // MARK: - 5. onChange
        .onChange(of: viewModel.filters) { _, newFilters in
            print("🔄 Filters changed")
            viewModel.applyFilters(newFilters)
        }
        // MARK: - 6. onDisappear
        .onDisappear {
            print("🔴 View disappeared")
            viewModel.endSession()
        }
    }
}

// MARK: - ViewModel
@MainActor
class SearchViewModel: ObservableObject {
    @Published var repositories: [Repository] = []
    @Published var isLoading = false
    @Published var filters: SearchFilters = .default

    func startSession() {
        print("📊 Session started")
        Analytics.trackEvent("search_session_started")
    }

    func loadTrendingRepositories() async {
        isLoading = true
        defer { isLoading = false }

        let trending = try? await apiClient.fetchTrending()
        repositories = trending ?? []
    }

    func search(query: String) async {
        isLoading = true
        defer { isLoading = false }

        let results = try? await apiClient.search(query: query)
        repositories = results ?? []
    }

    func applyFilters(_ filters: SearchFilters) {
        // Apply filters to results
    }

    func endSession() {
        print("📊 Session ended")
        Analytics.trackEvent("search_session_ended")
    }
}
```

---

## UIKit vs SwiftUI Lifecycle

| UIKit | SwiftUI | When |
|-------|---------|------|
| `init` | `init()` | View created |
| `viewDidLoad` | First `body` call | Initial setup |
| `viewWillAppear` | `.onAppear` | Before appearing |
| `viewDidAppear` | `.onAppear` | After appearing |
| `viewWillDisappear` | `.onDisappear` | Before disappearing |
| `viewDidDisappear` | `.onDisappear` | After disappearing |
| - | `.task { }` | Async work |
| Property observer | `.onChange(of:)` | State changes |
| `deinit` | - | Destruction |

---

## Best Practices

### ✅ Do's

1. **Use .task for async work**
   ```swift
   .task {
       await loadData()
   }
   ```

2. **Use @StateObject for ownership**
   ```swift
   @StateObject private var viewModel = MyViewModel()
   ```

3. **Keep body pure (no side effects)**
   ```swift
   var body: some View {
       Text("Hello")
       // ✅ Pure, declarative
   }
   ```

4. **Use .onChange for side effects**
   ```swift
   .onChange(of: searchText) { _, newValue in
       performSearch(newValue)
   }
   ```

### ❌ Don'ts

1. **Don't mutate state in body**
   ```swift
   var body: some View {
       count += 1  // ❌ Infinite loop!
       return Text("\(count)")
   }
   ```

2. **Don't use @ObservedObject for ownership**
   ```swift
   // ❌ Bad - recreated on rotation
   @ObservedObject var viewModel = MyViewModel()

   // ✅ Good - survives rotation
   @StateObject private var viewModel = MyViewModel()
   ```

3. **Don't perform heavy work in init**
   ```swift
   init() {
       fetchDataFromAPI()  // ❌ Bad
   }
   ```

---

## 🔬 Verified Runtime Test Logs

Actual logs captured during view identity, state observation, and async cancellation testing in `SwiftUIViewLifecycleExampleView.swift`:

```text
🧩 [SwiftUIViewLifecycle] Parent SwiftUIViewLifecycleExampleView onAppear
🧩 [SwiftUIViewLifecycle] 🟢 Child View: .onAppear()
🧩 [SwiftUIViewLifecycle] Forced new View Identity via .id(E749)
🧩 [SwiftUIViewLifecycle] 🔴 Child View: .onDisappear()
🧩 [SwiftUIViewLifecycle] 🟢 Child View: .onAppear()
🧩 [SwiftUIViewLifecycle] 🔄 .onChange: counter modified from 0 to 1
⚡️ .task started
✅ .task completed successfully
🧩 [SwiftUIViewLifecycle] Parent SwiftUIViewLifecycleExampleView onDisappear
```

> [!NOTE]
> **Key Observations from Test Logs**:
> 1. Changing `.id(E749)` instantly unmounts the existing child view (`.onDisappear`) and reconstructs a brand new view identity with fresh state (`.onAppear`).
> 2. Mutating `@State private var counter` triggers `🔄 .onChange` with precise `(oldValue: 0, newValue: 1)` arguments.
> 3. Disappearing unmounts the view tree, triggering `.onDisappear` up the hierarchy and cooperatively cancelling ongoing `.task` instances.

---

## See Also

- [ViewController Lifecycle](lifecycle_viewcontroller.md)
- [App Lifecycle](lifecycle_app.md)
- [Screen Rotation Data Handling](screen_rotation_data_handling.md)


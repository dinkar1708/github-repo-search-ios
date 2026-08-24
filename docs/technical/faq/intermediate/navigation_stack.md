# NavigationStack & Data Passing in SwiftUI

## Overview

NavigationStack (iOS 16+) is Apple's modern replacement for NavigationView, providing type-safe, programmatic navigation with better state management. Understanding how to navigate between screens and pass data correctly is essential for building multi-screen iOS applications.

## Why It Matters

- Essential for any multi-screen iOS app
- One of the most frequently asked SwiftUI technical topics
- NavigationView is deprecated, NavigationStack is the standard
- Critical for proper data flow in applications
- Required for deep linking and complex navigation flows
- Foundation for state restoration

## Key Concepts

### 1. NavigationStack Basics

**Old Way (NavigationView - Deprecated):**
```swift
NavigationView {
    List(items) { item in
        NavigationLink(destination: DetailView(item: item)) {
            Text(item.name)
        }
    }
}
```

**New Way (NavigationStack - iOS 16+):**
```swift
NavigationStack {
    List(items) { item in
        NavigationLink(value: item) {
            Text(item.name)
        }
    }
    .navigationDestination(for: Item.self) { item in
        DetailView(item: item)
    }
}
```

**Key Differences:**
- NavigationLink uses `value` instead of `destination`
- Destination defined separately with `navigationDestination`
- Type-safe navigation with explicit types
- Better state management
- Supports programmatic navigation

### 2. Simple Navigation with Data

**Example: User List → User Detail**

```swift
struct User: Identifiable, Hashable {
    let id: String
    let name: String
    let email: String
}

struct UserListView: View {
    let users: [User] = [
        User(id: "1", name: "Alice", email: "alice@example.com"),
        User(id: "2", name: "Bob", email: "bob@example.com")
    ]

    var body: some View {
        NavigationStack {
            List(users) { user in
                NavigationLink(value: user) {
                    VStack(alignment: .leading) {
                        Text(user.name)
                            .font(.headline)
                        Text(user.email)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
            .navigationTitle("Users")
            .navigationDestination(for: User.self) { user in
                UserDetailView(user: user)
            }
        }
    }
}

struct UserDetailView: View {
    let user: User

    var body: some View {
        VStack(spacing: 20) {
            Text(user.name)
                .font(.largeTitle)
            Text(user.email)
                .font(.title3)
                .foregroundColor(.gray)
        }
        .navigationTitle("User Details")
    }
}
```

**Data Flow:**
```
UserListView (source)
    ↓ NavigationLink(value: user)
    ↓ navigationDestination(for: User.self)
UserDetailView(user: user) (destination)
```

### 3. Programmatic Navigation

**Using NavigationPath:**

```swift
@Observable
class NavigationCoordinator {
    var path = NavigationPath()

    func navigateToDetail(user: User) {
        path.append(user)
    }

    func navigateBack() {
        if !path.isEmpty {
            path.removeLast()
        }
    }

    func navigateToRoot() {
        path = NavigationPath()
    }
}

struct ContentView: View {
    @State private var coordinator = NavigationCoordinator()

    var body: some View {
        NavigationStack(path: $coordinator.path) {
            UserListView(coordinator: coordinator)
                .navigationDestination(for: User.self) { user in
                    UserDetailView(user: user, coordinator: coordinator)
                }
        }
    }
}

struct UserListView: View {
    let coordinator: NavigationCoordinator
    let users: [User] = [...]

    var body: some View {
        List(users) { user in
            Button(user.name) {
                coordinator.navigateToDetail(user: user)
            }
        }
    }
}
```

### 4. Multiple Destination Types

**Handling Different Data Types:**

```swift
enum Route: Hashable {
    case userDetail(User)
    case settings
    case profile(userId: String)
}

struct MainView: View {
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            VStack {
                Button("View User") {
                    path.append(Route.userDetail(user))
                }
                Button("Settings") {
                    path.append(Route.settings)
                }
            }
            .navigationDestination(for: Route.self) { route in
                switch route {
                case .userDetail(let user):
                    UserDetailView(user: user)
                case .settings:
                    SettingsView()
                case .profile(let userId):
                    ProfileView(userId: userId)
                }
            }
        }
    }
}
```

### 5. Passing Data Between Views

**Pattern 1: Direct Parameter Passing**
```swift
struct ParentView: View {
    let items: [Item] = [...]

    var body: some View {
        NavigationStack {
            List(items) { item in
                NavigationLink(value: item) {
                    Text(item.name)
                }
            }
            .navigationDestination(for: Item.self) { item in
                DetailView(item: item)  // Pass directly
            }
        }
    }
}

struct DetailView: View {
    let item: Item  // Receive as property

    var body: some View {
        Text(item.description)
    }
}
```

**Pattern 2: Passing Multiple Parameters**
```swift
struct UserProfile: Hashable {
    let userId: String
    let showEdit: Bool
}

NavigationLink(value: UserProfile(userId: "123", showEdit: true)) {
    Text("Edit Profile")
}
.navigationDestination(for: UserProfile.self) { profile in
    ProfileView(userId: profile.userId, isEditable: profile.showEdit)
}
```

**Pattern 3: Using Environment for Shared Data**
```swift
@Observable
class AppState {
    var currentUser: User?
    var settings: Settings
}

struct ParentView: View {
    @State private var appState = AppState()

    var body: some View {
        NavigationStack {
            ContentView()
                .environment(appState)  // Share with all children
        }
    }
}

struct ChildView: View {
    @Environment(AppState.self) private var appState  // Access anywhere

    var body: some View {
        Text(appState.currentUser?.name ?? "")
    }
}
```

### 6. Deep Linking

**Supporting Deep Links:**

```swift
struct ContentView: View {
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            HomeView()
                .navigationDestination(for: User.self) { user in
                    UserDetailView(user: user)
                }
                .navigationDestination(for: Post.self) { post in
                    PostDetailView(post: post)
                }
        }
        .onOpenURL { url in
            handleDeepLink(url)
        }
    }

    func handleDeepLink(_ url: URL) {
        // Example: myapp://user/123
        if url.pathComponents.contains("user"),
           let userId = url.pathComponents.last {
            // Fetch user and navigate
            Task {
                let user = try await fetchUser(id: userId)
                path.append(user)
            }
        }
    }
}
```

### 7. State Restoration

**Preserving Navigation State:**

```swift
struct ContentView: View {
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            HomeView()
                .navigationDestination(for: User.self) { user in
                    UserDetailView(user: user)
                }
        }
        .task {
            // Restore saved path
            if let savedPath = UserDefaults.standard.data(forKey: "navigationPath"),
               let decodedPath = try? JSONDecoder().decode(NavigationPath.CodableRepresentation.self, from: savedPath) {
                path = NavigationPath(decodedPath)
            }
        }
        .onChange(of: path) { oldValue, newValue in
            // Save path changes
            if let encoded = try? JSONEncoder().encode(newValue.codable) {
                UserDefaults.standard.set(encoded, forKey: "navigationPath")
            }
        }
    }
}
```

### 8. Navigation with ViewModel

**MVVM Pattern with Navigation:**

```swift
@MainActor
@Observable
class UserListViewModel {
    var users: [User] = []
    var path = NavigationPath()
    private let api: APIClient

    init(api: APIClient) {
        self.api = api
    }

    func loadUsers() async {
        users = try? await api.fetchUsers()
    }

    func navigateToUser(_ user: User) {
        path.append(user)
    }

    func navigateToSettings() {
        path.append(Route.settings)
    }
}

struct UserListView: View {
    @State private var viewModel = UserListViewModel(api: APIClient())

    var body: some View {
        NavigationStack(path: $viewModel.path) {
            List(viewModel.users) { user in
                Button(user.name) {
                    viewModel.navigateToUser(user)
                }
            }
            .toolbar {
                Button("Settings") {
                    viewModel.navigateToSettings()
                }
            }
            .navigationDestination(for: User.self) { user in
                UserDetailView(user: user)
            }
            .navigationDestination(for: Route.self) { route in
                routeView(for: route)
            }
        }
        .task {
            await viewModel.loadUsers()
        }
    }

    @ViewBuilder
    func routeView(for route: Route) -> some View {
        switch route {
        case .settings:
            SettingsView()
        }
    }
}
```

## Common Navigation Patterns

### Pattern 1: Master-Detail

```swift
struct MasterDetailView: View {
    @State private var selectedItem: Item?

    var body: some View {
        NavigationStack {
            List(items) { item in
                NavigationLink(value: item) {
                    ItemRow(item: item)
                }
            }
            .navigationTitle("Items")
            .navigationDestination(for: Item.self) { item in
                ItemDetailView(item: item)
            }
        }
    }
}
```

### Pattern 2: Multi-Step Flow

```swift
enum OnboardingStep: Hashable {
    case welcome
    case profile
    case preferences
    case complete
}

struct OnboardingView: View {
    @State private var path: [OnboardingStep] = [.welcome]

    var body: some View {
        NavigationStack(path: $path) {
            WelcomeView()
                .navigationDestination(for: OnboardingStep.self) { step in
                    switch step {
                    case .welcome:
                        WelcomeView()
                    case .profile:
                        ProfileSetupView()
                    case .preferences:
                        PreferencesView()
                    case .complete:
                        CompletionView()
                    }
                }
        }
    }

    func nextStep() {
        guard let current = path.last else { return }
        switch current {
        case .welcome:
            path.append(.profile)
        case .profile:
            path.append(.preferences)
        case .preferences:
            path.append(.complete)
        case .complete:
            break
        }
    }
}
```

### Pattern 3: Tab Navigation with Deep Links

```swift
struct TabRootView: View {
    @State private var userPath = NavigationPath()
    @State private var settingsPath = NavigationPath()

    var body: some View {
        TabView {
            NavigationStack(path: $userPath) {
                UserListView()
                    .navigationDestination(for: User.self) { user in
                        UserDetailView(user: user)
                    }
            }
            .tabItem {
                Label("Users", systemImage: "person.2")
            }

            NavigationStack(path: $settingsPath) {
                SettingsView()
                    .navigationDestination(for: SettingOption.self) { option in
                        SettingDetailView(option: option)
                    }
            }
            .tabItem {
                Label("Settings", systemImage: "gear")
            }
        }
    }
}
```

## Common Mistakes

### Mistake 1: Using NavigationView Instead of NavigationStack

```swift
// WRONG - Deprecated in iOS 16+
NavigationView {
    List(items) { item in
        NavigationLink(destination: DetailView(item: item)) {
            Text(item.name)
        }
    }
}

// CORRECT - Use NavigationStack
NavigationStack {
    List(items) { item in
        NavigationLink(value: item) {
            Text(item.name)
        }
    }
    .navigationDestination(for: Item.self) { item in
        DetailView(item: item)
    }
}
```

### Mistake 2: Forgetting Hashable Conformance

```swift
// WRONG - Won't work with NavigationLink(value:)
struct User: Identifiable {
    let id: String
    let name: String
}

// CORRECT - Must conform to Hashable
struct User: Identifiable, Hashable {
    let id: String
    let name: String
}
```

### Mistake 3: Multiple NavigationStacks

```swift
// WRONG - Nested NavigationStacks cause issues
NavigationStack {
    NavigationStack {  // Don't nest!
        ContentView()
    }
}

// CORRECT - Single NavigationStack
NavigationStack {
    ContentView()
}
```

### Mistake 4: Not Managing NavigationPath State

```swift
// WRONG - No control over navigation
NavigationStack {
    ContentView()
}

// CORRECT - Manage path for programmatic navigation
@State private var path = NavigationPath()

NavigationStack(path: $path) {
    ContentView()
}
```

## Best Practices

### 1. Type-Safe Routes with Enums

```swift
enum AppRoute: Hashable {
    case userDetail(User)
    case postDetail(Post)
    case settings
    case profile(userId: String)
}

// Centralized navigation handling
.navigationDestination(for: AppRoute.self) { route in
    switch route {
    case .userDetail(let user):
        UserDetailView(user: user)
    case .postDetail(let post):
        PostDetailView(post: post)
    case .settings:
        SettingsView()
    case .profile(let userId):
        ProfileView(userId: userId)
    }
}
```

### 2. Coordinator Pattern for Complex Navigation

```swift
@MainActor
@Observable
class NavigationCoordinator {
    var path = NavigationPath()

    func showUser(_ user: User) {
        path.append(AppRoute.userDetail(user))
    }

    func showSettings() {
        path.append(AppRoute.settings)
    }

    func goBack() {
        if !path.isEmpty {
            path.removeLast()
        }
    }

    func resetToRoot() {
        path = NavigationPath()
    }
}
```

### 3. Separate Navigation Logic from UI

```swift
// ViewModel handles navigation logic
@Observable
class UserViewModel {
    var path = NavigationPath()

    func selectUser(_ user: User) {
        // Business logic
        if user.isPremium {
            path.append(user)
        } else {
            path.append(Route.upgrade)
        }
    }
}
```

### 4. Test Navigation Paths

```swift
@Test
func testNavigationToUserDetail() {
    let coordinator = NavigationCoordinator()
    let user = User(id: "1", name: "Test")

    coordinator.showUser(user)

    #expect(coordinator.path.count == 1)
}
```

## Technical Questions

### Q1: What's the difference between NavigationView and NavigationStack?
**Answer:**
- NavigationView: Deprecated in iOS 16, uses destination in NavigationLink
- NavigationStack: Modern replacement, uses value-based navigation
- NavigationStack: Better state management with NavigationPath
- NavigationStack: Type-safe with navigationDestination(for:)
- NavigationStack: Supports programmatic navigation
- NavigationStack: Better deep linking support

### Q2: How do you pass data to the next screen in NavigationStack?
**Answer:**
```swift
// 1. Define data type (must be Hashable)
struct User: Hashable {
    let id: String
    let name: String
}

// 2. Use NavigationLink with value
NavigationLink(value: user) {
    Text(user.name)
}

// 3. Define destination
.navigationDestination(for: User.self) { user in
    DetailView(user: user)
}
```

### Q3: What is NavigationPath and when do you use it?
**Answer:**
- Type-erased container for navigation stack
- Holds sequence of values representing navigation path
- Use for programmatic navigation (push/pop)
- Use when you need to control navigation from code
- Enables state restoration
- Can be bound to @State for reactivity

### Q4: How do you implement deep linking with NavigationStack?
**Answer:**
```swift
@State private var path = NavigationPath()

var body: some View {
    NavigationStack(path: $path) {
        // Views
    }
    .onOpenURL { url in
        // Parse URL and append to path
        if let user = parseUserURL(url) {
            path.append(user)
        }
    }
}
```

### Q5: How do you navigate programmatically?
**Answer:**
```swift
@State private var path = NavigationPath()

// Navigate forward
path.append(destination)

// Navigate back
path.removeLast()

// Reset to root
path = NavigationPath()

// Navigate multiple levels
path.append(contentsOf: [screen1, screen2, screen3])
```

### Q6: What types can be used with NavigationLink value?
**Answer:**
- Must conform to Hashable protocol
- Can be struct, enum, class (if Hashable)
- Common: enums for route definitions
- Identifiable types automatically conform if ID is Hashable
- Can be simple types (String, Int) or complex models

### Q7: How do you handle navigation in TabView?
**Answer:**
```swift
// Separate NavigationPath for each tab
@State private var tab1Path = NavigationPath()
@State private var tab2Path = NavigationPath()

TabView {
    NavigationStack(path: $tab1Path) {
        Tab1View()
    }
    .tabItem { Label("Tab 1", systemImage: "1.circle") }

    NavigationStack(path: $tab2Path) {
        Tab2View()
    }
    .tabItem { Label("Tab 2", systemImage: "2.circle") }
}
```

### Q8: How do you restore navigation state?
**Answer:**
Use NavigationPath's Codable representation:
```swift
// Save
let representation = path.codable
let data = try? JSONEncoder().encode(representation)
UserDefaults.standard.set(data, forKey: "path")

// Restore
if let data = UserDefaults.standard.data(forKey: "path"),
   let representation = try? JSONDecoder().decode(
       NavigationPath.CodableRepresentation.self,
       from: data
   ) {
    path = NavigationPath(representation)
}
```

## Related Topics

- [SwiftUI State Management](../beginner/state_management.md) - Managing navigation state
- [Property Wrappers](./property_wrappers.md) - @State for NavigationPath
- [Async/Await](./async_await_concurrency.md) - Async navigation actions
- [Environment Objects](../beginner/state_management.md) - Sharing data across navigation

## Further Reading

- [Apple NavigationStack Documentation](https://developer.apple.com/documentation/swiftui/navigationstack)
- [WWDC 2022 - The SwiftUI cookbook for navigation](https://developer.apple.com/videos/play/wwdc2022/10054/)
- [Hacking with Swift - NavigationStack Guide](https://www.hackingwithswift.com/quick-start/swiftui/how-to-use-navigationstack-to-navigate-programmatically)
- [Swift by Sundell - Modern SwiftUI Navigation](https://www.swiftbysundell.com/articles/modern-swiftui-navigation/)

---

**Last Updated:** 2026-08-16
**Difficulty:** Intermediate
**Estimated Reading Time:** 25 minutes
**Prerequisites:** SwiftUI basics, State management

---

## Quick Reference

```swift
// Basic NavigationStack
NavigationStack {
    List(items) { item in
        NavigationLink(value: item) {
            Text(item.name)
        }
    }
    .navigationDestination(for: Item.self) { item in
        DetailView(item: item)
    }
}

// Programmatic navigation
@State private var path = NavigationPath()

NavigationStack(path: $path) {
    Button("Navigate") {
        path.append(destination)  // Push
    }
}

// Multiple destinations
.navigationDestination(for: User.self) { user in
    UserView(user: user)
}
.navigationDestination(for: Post.self) { post in
    PostView(post: post)
}

// Navigate back
path.removeLast()

// Reset to root
path = NavigationPath()
```

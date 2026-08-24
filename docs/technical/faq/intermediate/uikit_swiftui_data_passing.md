# Passing Data Between UIKit and SwiftUI

This guide covers all patterns for passing data between UIViewController (UIKit) and SwiftUI views.

## 1. UIViewController → SwiftUI (Using UIHostingController)

### Basic Data Passing

```swift
// SwiftUI View
struct UserProfileView: View {
    let userName: String
    let userId: Int

    var body: some View {
        VStack {
            Text("User: \(userName)")
            Text("ID: \(userId)")
        }
    }
}

// UIViewController
class ProfileViewController: UIViewController {
    let userName = "John Doe"
    let userId = 123

    override func viewDidLoad() {
        super.viewDidLoad()

        // Create SwiftUI view with data
        let swiftUIView = UserProfileView(userName: userName, userId: userId)

        // Wrap in UIHostingController
        let hostingController = UIHostingController(rootView: swiftUIView)

        // Add as child view controller
        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.view.frame = view.bounds
        hostingController.didMove(toParent: self)
    }
}
```

### Passing Observable Objects

```swift
// Observable data model
class UserViewModel: ObservableObject {
    @Published var name: String = ""
    @Published var email: String = ""
    @Published var repositories: [Repository] = []
}

// SwiftUI View
struct UserDetailView: View {
    @ObservedObject var viewModel: UserViewModel

    var body: some View {
        List {
            Text(viewModel.name)
            Text(viewModel.email)
            ForEach(viewModel.repositories) { repo in
                Text(repo.name)
            }
        }
    }
}

// UIViewController
class UserViewController: UIViewController {
    private let viewModel = UserViewModel()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Set data
        viewModel.name = "Jane Smith"
        viewModel.email = "jane@example.com"

        // Pass to SwiftUI
        let swiftUIView = UserDetailView(viewModel: viewModel)
        let hostingController = UIHostingController(rootView: swiftUIView)

        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.view.frame = view.bounds
        hostingController.didMove(toParent: self)

        // Update data later
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.viewModel.repositories = self.fetchRepositories()
        }
    }
}
```

### Passing Closures for Callbacks

```swift
// SwiftUI View with callback
struct RepositoryListView: View {
    let repositories: [Repository]
    let onRepositoryTapped: (Repository) -> Void

    var body: some View {
        List(repositories) { repo in
            Button(action: {
                onRepositoryTapped(repo)
            }) {
                Text(repo.name)
            }
        }
    }
}

// UIViewController
class RepositoryListViewController: UIViewController {
    private var repositories: [Repository] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        repositories = loadRepositories()

        // Pass data and callback
        let swiftUIView = RepositoryListView(
            repositories: repositories,
            onRepositoryTapped: { [weak self] repository in
                self?.showDetail(for: repository)
            }
        )

        let hostingController = UIHostingController(rootView: swiftUIView)
        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.view.frame = view.bounds
        hostingController.didMove(toParent: self)
    }

    private func showDetail(for repository: Repository) {
        let detailVC = RepositoryDetailViewController(repository: repository)
        navigationController?.pushViewController(detailVC, animated: true)
    }
}
```

## 2. SwiftUI → UIViewController (Using UIViewControllerRepresentable)

### Basic ViewController Wrapping

```swift
// UIViewController to wrap
class ImagePickerViewController: UIViewController {
    var selectedImage: UIImage?
    var onImageSelected: ((UIImage) -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Setup image picker
    }

    func imageSelected(_ image: UIImage) {
        selectedImage = image
        onImageSelected?(image)
    }
}

// SwiftUI Wrapper
struct ImagePickerView: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> ImagePickerViewController {
        let picker = ImagePickerViewController()

        picker.onImageSelected = { [weak picker] image in
            // Pass data back to SwiftUI
            self.selectedImage = image
            // Can also dismiss
            picker?.dismiss(animated: true)
        }

        return picker
    }

    func updateUIViewController(_ uiViewController: ImagePickerViewController, context: Context) {
        // Update ViewController when SwiftUI state changes
    }
}

// Usage in SwiftUI
struct ContentView: View {
    @State private var selectedImage: UIImage?
    @State private var showPicker = false

    var body: some View {
        VStack {
            if let image = selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            }

            Button("Pick Image") {
                showPicker = true
            }
        }
        .sheet(isPresented: $showPicker) {
            ImagePickerView(selectedImage: $selectedImage)
        }
    }
}
```

### Using Coordinator for Complex Communication

```swift
// Complex UIViewController
class SearchViewController: UIViewController, UISearchBarDelegate {
    var searchBar: UISearchBar!
    var onSearchTextChanged: ((String) -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()

        searchBar = UISearchBar()
        searchBar.delegate = self
        view.addSubview(searchBar)
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        onSearchTextChanged?(searchText)
    }
}

// SwiftUI Wrapper with Coordinator
struct SearchBarView: UIViewControllerRepresentable {
    @Binding var searchText: String
    let onSearch: (String) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> SearchViewController {
        let vc = SearchViewController()
        vc.onSearchTextChanged = context.coordinator.handleSearchTextChange
        return vc
    }

    func updateUIViewController(_ uiViewController: SearchViewController, context: Context) {
        // Update when SwiftUI state changes
        if uiViewController.searchBar.text != searchText {
            uiViewController.searchBar.text = searchText
        }
    }

    class Coordinator {
        let parent: SearchBarView

        init(_ parent: SearchBarView) {
            self.parent = parent
        }

        func handleSearchTextChange(_ text: String) {
            parent.searchText = text
            parent.onSearch(text)
        }
    }
}

// Usage
struct RepositorySearchView: View {
    @State private var searchText = ""
    @State private var results: [Repository] = []

    var body: some View {
        VStack {
            SearchBarView(searchText: $searchText) { query in
                searchRepositories(query: query)
            }

            List(results) { repo in
                Text(repo.name)
            }
        }
    }

    func searchRepositories(query: String) {
        // Perform search
        results = performSearch(query)
    }
}
```

## 3. Bidirectional Data Flow

### Using Combine for Two-Way Communication

```swift
import Combine

// Shared ViewModel
class RepositoryViewModel: ObservableObject {
    @Published var repositories: [Repository] = []
    @Published var selectedRepository: Repository?
    @Published var isLoading = false

    func fetchRepositories() {
        isLoading = true
        // API call
        DispatchQueue.global().async {
            let repos = self.loadFromAPI()
            DispatchQueue.main.async {
                self.repositories = repos
                self.isLoading = false
            }
        }
    }
}

// UIViewController using Combine
class MainViewController: UIViewController {
    private let viewModel = RepositoryViewModel()
    private var cancellables = Set<AnyCancellable>()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Subscribe to changes
        viewModel.$repositories
            .sink { [weak self] repositories in
                print("Repositories updated: \(repositories.count)")
                self?.updateTableView(with: repositories)
            }
            .store(in: &cancellables)

        viewModel.$isLoading
            .sink { [weak self] isLoading in
                self?.showLoadingIndicator(isLoading)
            }
            .store(in: &cancellables)

        // Fetch data
        viewModel.fetchRepositories()

        // Show SwiftUI view with same ViewModel
        showSwiftUIView()
    }

    func showSwiftUIView() {
        let swiftUIView = RepositoryListSwiftUIView(viewModel: viewModel)
        let hostingController = UIHostingController(rootView: swiftUIView)
        navigationController?.pushViewController(hostingController, animated: true)
    }
}

// SwiftUI View using same ViewModel
struct RepositoryListSwiftUIView: View {
    @ObservedObject var viewModel: RepositoryViewModel

    var body: some View {
        List(viewModel.repositories) { repo in
            Button(action: {
                viewModel.selectedRepository = repo
            }) {
                Text(repo.name)
            }
        }
        .overlay {
            if viewModel.isLoading {
                ProgressView()
            }
        }
    }
}
```

## 4. Passing Data Through Navigation

### Push SwiftUI View from UIViewController

```swift
// UIViewController
class HomeViewController: UIViewController {
    let userName = "Alice"
    let repositories: [Repository] = []

    @objc func showRepositories() {
        // Create SwiftUI view with data
        let swiftUIView = RepositoryListView(
            userName: userName,
            repositories: repositories
        )

        let hostingController = UIHostingController(rootView: swiftUIView)

        // Push to navigation stack
        navigationController?.pushViewController(hostingController, animated: true)
    }
}

// SwiftUI View
struct RepositoryListView: View {
    let userName: String
    let repositories: [Repository]

    var body: some View {
        List(repositories) { repo in
            Text(repo.name)
        }
        .navigationTitle(userName)
    }
}
```

### Push UIViewController from SwiftUI

```swift
// SwiftUI View
struct ProfileView: View {
    @State private var showSettings = false
    let userId: Int

    var body: some View {
        VStack {
            Text("Profile")

            Button("Settings") {
                showSettings = true
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsViewControllerWrapper(userId: userId)
        }
    }
}

// Wrapper for UIViewController
struct SettingsViewControllerWrapper: UIViewControllerRepresentable {
    let userId: Int

    func makeUIViewController(context: Context) -> UINavigationController {
        let settingsVC = SettingsViewController()

        // Pass data to UIViewController
        settingsVC.userId = userId
        settingsVC.loadUserSettings()

        return UINavigationController(rootViewController: settingsVC)
    }

    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {
        // Update if needed
    }
}

// UIViewController
class SettingsViewController: UIViewController {
    var userId: Int = 0

    func loadUserSettings() {
        print("Loading settings for user \(userId)")
        // Load and display settings
    }
}
```

### Accessing UIViewController Methods from SwiftUI

You can call UIViewController methods from SwiftUI using the Coordinator or through references.

```swift
// UIViewController with methods you want to call
class CameraViewController: UIViewController {
    func capturePhoto() {
        print("Capturing photo...")
        // Capture logic
    }

    func toggleFlash() {
        print("Toggling flash...")
        // Flash logic
    }

    func switchCamera() {
        print("Switching camera...")
        // Switch logic
    }
}

// SwiftUI Wrapper with method access
struct CameraView: UIViewControllerRepresentable {
    @Binding var isFlashOn: Bool

    // Expose ViewController reference through Coordinator
    class Coordinator {
        var viewController: CameraViewController?

        func capturePhoto() {
            viewController?.capturePhoto()
        }

        func toggleFlash() {
            viewController?.toggleFlash()
        }

        func switchCamera() {
            viewController?.switchCamera()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIViewController(context: Context) -> CameraViewController {
        let vc = CameraViewController()
        context.coordinator.viewController = vc
        return vc
    }

    func updateUIViewController(_ uiViewController: CameraViewController, context: Context) {
        // Update when SwiftUI state changes
        if isFlashOn {
            context.coordinator.toggleFlash()
        }
    }
}

// Usage in SwiftUI - Call ViewController methods
struct CameraControlView: View {
    @State private var isFlashOn = false
    @State private var coordinator: CameraView.Coordinator?

    var body: some View {
        VStack {
            CameraView(isFlashOn: $isFlashOn)
                .onAppear { setupCoordinator() }

            HStack(spacing: 20) {
                Button("Capture") {
                    coordinator?.capturePhoto()
                }

                Button("Flash") {
                    isFlashOn.toggle()
                    coordinator?.toggleFlash()
                }

                Button("Switch") {
                    coordinator?.switchCamera()
                }
            }
            .padding()
        }
    }

    func setupCoordinator() {
        // Access coordinator if needed
    }
}
```

### Alternative: Using Custom Bindings to Call Methods

```swift
// UIViewController
class VideoPlayerViewController: UIViewController {
    func play() { print("Playing") }
    func pause() { print("Paused") }
    func seek(to time: Double) { print("Seek to \(time)") }
}

// SwiftUI Wrapper with action handlers
struct VideoPlayerView: UIViewControllerRepresentable {
    let onPlay: () -> Void
    let onPause: () -> Void
    let onSeek: (Double) -> Void

    class Coordinator {
        let parent: VideoPlayerView
        var viewController: VideoPlayerViewController?

        init(_ parent: VideoPlayerView) {
            self.parent = parent
        }

        func play() {
            viewController?.play()
            parent.onPlay()
        }

        func pause() {
            viewController?.pause()
            parent.onPause()
        }

        func seek(to time: Double) {
            viewController?.seek(to: time)
            parent.onSeek(time)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> VideoPlayerViewController {
        let vc = VideoPlayerViewController()
        context.coordinator.viewController = vc
        return vc
    }

    func updateUIViewController(_ uiViewController: VideoPlayerViewController, context: Context) {}

    // Expose coordinator for external access
    static func makeCoordinator(
        onPlay: @escaping () -> Void,
        onPause: @escaping () -> Void,
        onSeek: @escaping (Double) -> Void
    ) -> Coordinator {
        let view = VideoPlayerView(onPlay: onPlay, onPause: onPause, onSeek: onSeek)
        return view.makeCoordinator()
    }
}

// Usage
struct VideoPlayerControlView: View {
    @State private var isPlaying = false
    @State private var currentTime: Double = 0

    var coordinator: VideoPlayerView.Coordinator?

    var body: some View {
        VStack {
            VideoPlayerView(
                onPlay: { isPlaying = true },
                onPause: { isPlaying = false },
                onSeek: { time in currentTime = time }
            )

            HStack {
                Button(isPlaying ? "Pause" : "Play") {
                    if isPlaying {
                        coordinator?.pause()
                    } else {
                        coordinator?.play()
                    }
                }

                Slider(value: $currentTime, in: 0...100) { _ in
                    coordinator?.seek(to: currentTime)
                }
            }
            .padding()
        }
    }
}
```

### Using Environment to Access ViewController

```swift
// Create environment key
struct ViewControllerKey: EnvironmentKey {
    static let defaultValue: UIViewController? = nil
}

extension EnvironmentValues {
    var viewController: UIViewController? {
        get { self[ViewControllerKey.self] }
        set { self[ViewControllerKey.self] = newValue }
    }
}

// UIViewController providing itself
class MainViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        let swiftUIView = ContentView()
            .environment(\.viewController, self)

        let hostingController = UIHostingController(rootView: swiftUIView)
        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.view.frame = view.bounds
        hostingController.didMove(toParent: self)
    }

    func presentDetail(for item: String) {
        let detailVC = DetailViewController()
        detailVC.item = item
        navigationController?.pushViewController(detailVC, animated: true)
    }
}

// SwiftUI view accessing ViewController
struct ContentView: View {
    @Environment(\.viewController) private var viewController

    var body: some View {
        Button("Show Detail") {
            if let mainVC = viewController as? MainViewController {
                mainVC.presentDetail(for: "Item 1")
            }
        }
    }
}
```

### Complete Example: Accessing ViewController Methods

```swift
// Full featured UIViewController
class DocumentViewController: UIViewController {
    var document: Document?

    func saveDocument() {
        print("Saving document...")
        document?.save()
    }

    func exportDocument(format: ExportFormat) {
        print("Exporting as \(format)")
        // Export logic
    }

    func shareDocument() {
        guard let doc = document else { return }

        let activityVC = UIActivityViewController(
            activityItems: [doc.fileURL],
            applicationActivities: nil
        )
        present(activityVC, animated: true)
    }
}

// SwiftUI wrapper with full method access
struct DocumentEditorView: UIViewControllerRepresentable {
    let document: Document
    @Binding var isSaved: Bool

    class Coordinator {
        var viewController: DocumentViewController?

        func save() {
            viewController?.saveDocument()
        }

        func export(format: ExportFormat) {
            viewController?.exportDocument(format: format)
        }

        func share() {
            viewController?.shareDocument()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIViewController(context: Context) -> DocumentViewController {
        let vc = DocumentViewController()
        vc.document = document
        context.coordinator.viewController = vc
        return vc
    }

    func updateUIViewController(_ uiViewController: DocumentViewController, context: Context) {
        uiViewController.document = document
    }
}

// SwiftUI view that calls ViewController methods
struct DocumentEditScreen: View {
    @State private var document = Document()
    @State private var isSaved = false
    @StateObject private var coordinator = DocumentEditorCoordinator()

    var body: some View {
        VStack {
            DocumentEditorView(document: document, isSaved: $isSaved)
                .onAppear {
                    // Store coordinator reference for later use
                }

            HStack(spacing: 15) {
                Button("Save") {
                    coordinator.save()
                    isSaved = true
                }

                Button("Export PDF") {
                    coordinator.export(format: .pdf)
                }

                Button("Export Word") {
                    coordinator.export(format: .docx)
                }

                Button("Share") {
                    coordinator.share()
                }
            }
            .padding()
        }
    }
}

// Helper to hold coordinator reference
class DocumentEditorCoordinator: ObservableObject {
    var coordinator: DocumentEditorView.Coordinator?

    func save() {
        coordinator?.save()
    }

    func export(format: ExportFormat) {
        coordinator?.export(format: format)
    }

    func share() {
        coordinator?.share()
    }
}
```

## 5. Environment Objects and Dependency Injection

### Sharing Data via EnvironmentObject

```swift
// App-wide data
class AppState: ObservableObject {
    @Published var currentUser: User?
    @Published var authToken: String?
    @Published var theme: Theme = .light
}

// SceneDelegate or App
class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    let appState = AppState()

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options: UISceneConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }

        let window = UIWindow(windowScene: windowScene)

        // Create root SwiftUI view with environment
        let contentView = ContentView()
            .environmentObject(appState)

        let hostingController = UIHostingController(rootView: contentView)
        window.rootViewController = hostingController

        self.window = window
        window.makeKeyAndVisible()
    }
}

// SwiftUI View accessing EnvironmentObject
struct ProfileView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack {
            if let user = appState.currentUser {
                Text("Hello, \(user.name)")
            }

            Button("Switch Theme") {
                appState.theme = appState.theme == .light ? .dark : .light
            }
        }
    }
}

// UIViewController accessing same AppState
class SettingsViewController: UIViewController {
    var appState: AppState!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Access shared state
        print("Current user: \(appState.currentUser?.name ?? "None")")

        // Update state (SwiftUI views will react)
        appState.theme = .dark
    }
}
```

## 6. Common Patterns and Best Practices

### Pattern 1: Simple Data (Immutable)

Use for read-only data passed once.

```swift
// ✅ Good
let swiftUIView = DetailView(
    title: "Repository",
    description: "A great project",
    stars: 1234
)
```

### Pattern 2: Observable Objects

Use for dynamic, mutable data that changes over time.

```swift
// ✅ Good
class DataModel: ObservableObject {
    @Published var items: [Item] = []
}

let model = DataModel()
let swiftUIView = ListView(viewModel: model)

// UIViewController can update
model.items.append(newItem) // SwiftUI updates automatically
```

### Pattern 3: Bindings for Two-Way Sync

Use when both sides need to read and write.

```swift
// ✅ Good
struct EditView: View {
    @Binding var text: String
}

// In UIViewController
@State private var currentText = "Hello"
let editView = EditView(text: $currentText)
```

### Pattern 4: Closures for One-Way Events

Use for callbacks and actions.

```swift
// ✅ Good
let swiftUIView = ButtonView(
    title: "Submit",
    onTap: { [weak self] in
        self?.handleSubmit()
    }
)
```

### Complete Example: Mixed UIKit/SwiftUI App

```swift
// Shared ViewModel
class RepositorySearchViewModel: ObservableObject {
    @Published var searchQuery = ""
    @Published var repositories: [Repository] = []
    @Published var isLoading = false

    func search() {
        isLoading = true

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }

            // API call
            let results = self.performSearch(query: self.searchQuery)

            DispatchQueue.main.async {
                self.repositories = results
                self.isLoading = false
            }
        }
    }
}

// UIViewController (Main screen)
class MainViewController: UIViewController {
    private let viewModel = RepositorySearchViewModel()
    private var cancellables = Set<AnyCancellable>()

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Repository Search"

        // Show SwiftUI search view
        let searchView = SearchView(viewModel: viewModel)
        let hostingController = UIHostingController(rootView: searchView)

        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.view.frame = view.bounds
        hostingController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        hostingController.didMove(toParent: self)

        // Subscribe to selection
        viewModel.$repositories
            .sink { [weak self] repos in
                print("Found \(repos.count) repositories")
            }
            .store(in: &cancellables)
    }
}

// SwiftUI View
struct SearchView: View {
    @ObservedObject var viewModel: RepositorySearchViewModel

    var body: some View {
        VStack {
            // Search bar
            TextField("Search repositories", text: $viewModel.searchQuery)
                .textFieldStyle(.roundedBorder)
                .padding()
                .onSubmit {
                    viewModel.search()
                }

            // Results
            if viewModel.isLoading {
                ProgressView()
            } else {
                List(viewModel.repositories) { repo in
                    VStack(alignment: .leading) {
                        Text(repo.name)
                            .font(.headline)
                        Text(repo.description)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
        }
    }
}
```

## Best Practices Summary

| Pattern | Use Case | Example |
|---------|----------|---------|
| **Direct parameters** | Simple, immutable data | `DetailView(title: "Hi", count: 5)` |
| **@ObservedObject** | Mutable data, shared state | `ListView(viewModel: myViewModel)` |
| **@Binding** | Two-way data sync | `EditView(text: $userName)` |
| **Closures** | Callbacks, actions | `ButtonView(onTap: { handleTap() })` |
| **@EnvironmentObject** | App-wide state | `.environmentObject(appState)` |
| **Combine Publishers** | Reactive updates | `viewModel.$data.sink { }` |

## Common Pitfalls

### ❌ Don't: Create new ViewModel instances

```swift
// ❌ Bad - creates new instance, data won't sync
let swiftUIView = DetailView(viewModel: ViewModel())
```

### ✅ Do: Share ViewModel instances

```swift
// ✅ Good - shares same instance
let viewModel = ViewModel()
let swiftUIView = DetailView(viewModel: viewModel)
```

### ❌ Don't: Forget [weak self] in closures

```swift
// ❌ Bad - memory leak
let swiftUIView = ListView(onTap: {
    self.handleTap() // Captures self strongly
})
```

### ✅ Do: Use [weak self]

```swift
// ✅ Good - prevents memory leak
let swiftUIView = ListView(onTap: { [weak self] in
    self?.handleTap()
})
```

## See Also

- [Background Thread Execution Patterns](background_thread_execution_patterns.md)
- [Memory Leak Detection](advanced/memory_leak_detection.md)
- [Architecture Patterns](../../architecture_patterns.md)

# Screen Rotation and Data Handling in iOS

This guide covers handling screen rotation, preserving data, and updating layouts during orientation changes.

## Understanding Data Loss on Screen Rotation

### Why Does Data Loss Happen?

**UIKit (Older Apps):**
In older iOS apps (pre-iOS 8), rotating the screen would **destroy and recreate the entire ViewController**. This caused:
- All UI state lost (text fields, switches, selections)
- Network requests interrupted
- User input discarded
- Scroll positions reset

**Modern UIKit (iOS 8+):**
ViewControllers are **NOT destroyed** on rotation anymore, BUT:
- Views may be recreated if constraints change
- If you recreate views manually in `viewWillTransition`, data can be lost
- Improper state management still causes data loss

**SwiftUI:**
Views are **value types** and get recreated frequently, BUT:
- Data in `@State`, `@StateObject` is preserved automatically
- Data loss only happens with incorrect property wrapper usage

### Common Causes of Data Loss

| Cause | Problem | Solution |
|-------|---------|----------|
| **Recreating ViewController** | Old code pattern | Don't recreate, use `viewWillTransition` |
| **Not storing data in properties** | Data stored in views only | Store in VC properties or ViewModel |
| **Using @ObservedObject instead of @StateObject** | SwiftUI recreates object | Use `@StateObject` for ownership |
| **Network request not preserved** | Request cancelled on rotation | Store request state, don't cancel |
| **TextField text not saved** | Text stored in UI only | Bind to property/state |

## Quick Fixes for Data Loss

### ❌ Problem: TextField Text Lost on Rotation (UIKit)

```swift
// ❌ BAD - Text lost on rotation
class BadViewController: UIViewController {
    @IBOutlet weak var nameTextField: UITextField!

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        // UI updates but text might be lost
        updateLayout()
    }
}
```

### ✅ Solution: Store Text in Property

```swift
// ✅ GOOD - Text preserved
class GoodViewController: UIViewController {
    @IBOutlet weak var nameTextField: UITextField!

    // Store data in property - survives rotation
    var userName: String = "" {
        didSet {
            nameTextField?.text = userName
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Restore text
        nameTextField.text = userName

        // Save text on changes
        nameTextField.addTarget(self, action: #selector(textChanged), for: .editingChanged)
    }

    @objc func textChanged() {
        userName = nameTextField.text ?? ""
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        // Data in 'userName' property is preserved automatically
        coordinator.animate(alongsideTransition: { _ in
            self.updateLayout()
        })
    }
}
```

### ❌ Problem: Data Lost in SwiftUI

```swift
// ❌ BAD - ViewModel recreated on rotation
struct BadView: View {
    @ObservedObject var viewModel = RepositoryViewModel() // ⚠️ Recreated!

    var body: some View {
        List(viewModel.repositories) { repo in
            Text(repo.name)
        }
    }
}
```

### ✅ Solution: Use @StateObject

```swift
// ✅ GOOD - ViewModel survives rotation
struct GoodView: View {
    @StateObject private var viewModel = RepositoryViewModel() // ✅ Preserved!

    var body: some View {
        List(viewModel.repositories) { repo in
            Text(repo.name)
        }
    }
}
```

### ❌ Problem: Network Request Lost on Rotation

```swift
// ❌ BAD - Request lost on rotation
class BadViewController: UIViewController {
    func fetchData() {
        URLSession.shared.dataTask(with: url) { data, response, error in
            // If rotation happens during request, data might be lost
            DispatchQueue.main.async {
                self.updateUI(with: data) // UI might not exist
            }
        }.resume()
    }
}
```

### ✅ Solution: Store Data in Properties

```swift
// ✅ GOOD - Data preserved even during network request
class GoodViewController: UIViewController {
    var repositories: [Repository] = []
    var isLoading: Bool = false
    var currentTask: URLSessionDataTask?

    func fetchData() {
        isLoading = true

        currentTask = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self else { return }

            // Parse data
            if let data = data {
                let repos = try? JSONDecoder().decode([Repository].self, from: data)

                DispatchQueue.main.async {
                    // Store in property - survives rotation
                    self.repositories = repos ?? []
                    self.isLoading = false
                    self.tableView.reloadData()
                }
            }
        }
        currentTask?.resume()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        // Don't cancel request!
        // Data in 'repositories' property is safe

        coordinator.animate(alongsideTransition: { _ in
            // Just update layout
            self.tableView.reloadData()
        })
    }
}
```

### ❌ Problem: Form Data Lost on Rotation

```swift
// ❌ BAD - All form data lost
class BadFormViewController: UIViewController {
    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var ageField: UITextField!

    // No properties to store data
}
```

### ✅ Solution: Store All Form Data

```swift
// ✅ GOOD - All form data preserved
class GoodFormViewController: UIViewController {
    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var ageField: UITextField!

    // Store all form data in properties
    var formData = FormData()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Restore form data
        nameField.text = formData.name
        emailField.text = formData.email
        ageField.text = formData.age

        // Setup listeners
        setupTextFieldListeners()
    }

    func setupTextFieldListeners() {
        nameField.addTarget(self, action: #selector(nameChanged), for: .editingChanged)
        emailField.addTarget(self, action: #selector(emailChanged), for: .editingChanged)
        ageField.addTarget(self, action: #selector(ageChanged), for: .editingChanged)
    }

    @objc func nameChanged() {
        formData.name = nameField.text ?? ""
    }

    @objc func emailChanged() {
        formData.email = emailField.text ?? ""
    }

    @objc func ageChanged() {
        formData.age = ageField.text ?? ""
    }
}

struct FormData {
    var name: String = ""
    var email: String = ""
    var age: String = ""
}
```

### SwiftUI Form Data Preservation (Automatic!)

```swift
// ✅ SwiftUI - Data automatically preserved
struct FormView: View {
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var age: String = ""

    var body: some View {
        Form {
            TextField("Name", text: $name)
            TextField("Email", text: $email)
            TextField("Age", text: $age)
        }
    }
    // All data automatically preserved on rotation! ✨
}
```

## Complete Example: Search Screen with No Data Loss

### UIKit Version

```swift
class RepositorySearchViewController: UIViewController {
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!

    // ✅ All data in properties - survives rotation
    var repositories: [Repository] = []
    var searchQuery: String = ""
    var isLoading: Bool = false
    var currentPage: Int = 1
    var selectedIndexPath: IndexPath?
    var scrollPosition: CGPoint = .zero

    // Don't cancel request on rotation
    var currentSearchTask: URLSessionDataTask?

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        restoreState()
    }

    func setupUI() {
        searchBar.delegate = self
        tableView.delegate = self
        tableView.dataSource = self

        // Restore previous search
        searchBar.text = searchQuery

        // If we have data, show it
        if !repositories.isEmpty {
            tableView.reloadData()
        }
    }

    func restoreState() {
        // Restore scroll position
        if scrollPosition != .zero {
            tableView.contentOffset = scrollPosition
        }

        // Restore selection
        if let indexPath = selectedIndexPath {
            tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
        }
    }

    func performSearch(query: String) {
        searchQuery = query
        isLoading = true

        // Cancel previous request
        currentSearchTask?.cancel()

        currentSearchTask = URLSession.shared.dataTask(with: makeURL(query: query)) { [weak self] data, response, error in
            guard let self = self else { return }

            if let data = data {
                let repos = try? JSONDecoder().decode([Repository].self, from: data)

                DispatchQueue.main.async {
                    // Store in property - safe from rotation
                    self.repositories = repos ?? []
                    self.isLoading = false
                    self.tableView.reloadData()
                }
            }
        }
        currentSearchTask?.resume()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        // Save state before rotation
        scrollPosition = tableView.contentOffset
        selectedIndexPath = tableView.indexPathForSelectedRow

        coordinator.animate(alongsideTransition: { _ in
            // Data is preserved in properties
            // Just update layout
            self.tableView.reloadData()
        }, completion: { _ in
            // Restore state after rotation
            self.restoreState()
        })
    }
}

extension RepositorySearchViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        if let query = searchBar.text {
            performSearch(query: query)
        }
    }
}

extension RepositorySearchViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return repositories.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let repo = repositories[indexPath.row]
        cell.textLabel?.text = repo.name
        return cell
    }
}

extension RepositorySearchViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedIndexPath = indexPath
        // Handle selection
    }
}
```

### SwiftUI Version (Much Simpler!)

```swift
struct RepositorySearchView: View {
    @StateObject private var viewModel = SearchViewModel()
    @State private var searchText: String = ""

    var body: some View {
        NavigationView {
            VStack {
                SearchBar(text: $searchText)
                    .onSubmit {
                        viewModel.search(query: searchText)
                    }

                if viewModel.isLoading {
                    ProgressView()
                } else {
                    List(viewModel.repositories) { repo in
                        Text(repo.name)
                    }
                }
            }
            .navigationTitle("Search")
        }
    }
    // ✅ All data automatically preserved on rotation!
}

class SearchViewModel: ObservableObject {
    @Published var repositories: [Repository] = []
    @Published var isLoading: Bool = false

    func search(query: String) {
        isLoading = true

        // Network request continues through rotation
        URLSession.shared.dataTask(with: makeURL(query: query)) { [weak self] data, response, error in
            guard let self = self else { return }

            if let data = data {
                let repos = try? JSONDecoder().decode([Repository].self, from: data)

                DispatchQueue.main.async {
                    self.repositories = repos ?? []
                    self.isLoading = false
                }
            }
        }.resume()
    }
}
```

## Do ViewModels Keep Data During Rotation?

### YES - ViewModels KEEP Data! ✅

ViewModels are designed to **survive screen rotation** and preserve all data.

### UIKit ViewModels

```swift
class RepositoryViewModel {
    var repositories: [Repository] = []
    var searchQuery: String = ""
    var currentPage: Int = 1

    func fetchData() {
        // Fetch data
    }
}

class MyViewController: UIViewController {
    // ✅ ViewModel is a property - survives rotation
    let viewModel = RepositoryViewModel()

    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel.fetchData()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        // ✅ viewModel.repositories still has all data
        print("Data count: \(viewModel.repositories.count)")

        coordinator.animate(alongsideTransition: { _ in
            self.tableView.reloadData() // Show same data
        })
    }
}
```

**Why it works:**
- ViewController is NOT destroyed on rotation (iOS 8+)
- ViewModel is a property of ViewController
- Property survives rotation automatically
- All data in ViewModel is preserved

### SwiftUI ViewModels

```swift
class RepositoryViewModel: ObservableObject {
    @Published var repositories: [Repository] = []
    @Published var searchQuery: String = ""
    @Published var currentPage: Int = 1

    func fetchData() {
        // Fetch data
    }
}

struct ContentView: View {
    // ✅ @StateObject - ViewModel survives rotation
    @StateObject private var viewModel = RepositoryViewModel()

    var body: some View {
        List(viewModel.repositories) { repo in
            Text(repo.name)
        }
    }
    // ✅ All viewModel data preserved on rotation!
}
```

**Why it works:**
- `@StateObject` tells SwiftUI to keep ViewModel alive
- Even though View is recreated, ViewModel instance survives
- All `@Published` properties retain their data

### ❌ WRONG: Using @ObservedObject (Data Lost!)

```swift
struct ContentView: View {
    // ❌ @ObservedObject - ViewModel may be recreated!
    @ObservedObject var viewModel = RepositoryViewModel()

    var body: some View {
        List(viewModel.repositories) { repo in
            Text(repo.name)
        }
    }
    // ⚠️ Data LOST on rotation - ViewModel recreated!
}
```

**Why it fails:**
- `@ObservedObject` doesn't own the ViewModel
- When View is recreated, new ViewModel instance created
- All previous data is lost

### Comparison: @StateObject vs @ObservedObject

```swift
// ✅ @StateObject - Owns ViewModel
struct GoodView: View {
    @StateObject private var viewModel = RepositoryViewModel()
    // ViewModel survives rotation ✅
}

// ❌ @ObservedObject - Doesn't own ViewModel
struct BadView: View {
    @ObservedObject var viewModel = RepositoryViewModel()
    // ViewModel recreated on rotation ❌
}

// ✅ @ObservedObject - When passed from parent
struct ChildView: View {
    @ObservedObject var viewModel: RepositoryViewModel // Passed from parent
    // ViewModel owned by parent, safe ✅
}

struct ParentView: View {
    @StateObject private var viewModel = RepositoryViewModel()

    var body: some View {
        ChildView(viewModel: viewModel) // Pass to child
    }
}
```

### Complete ViewModel Example with Rotation

```swift
// UIKit Example
class RepositoryViewModel {
    var repositories: [Repository] = []
    var isLoading: Bool = false
    var searchQuery: String = ""
    var errorMessage: String?

    private var currentTask: URLSessionDataTask?

    func search(query: String) {
        searchQuery = query
        isLoading = true
        errorMessage = nil

        currentTask?.cancel()

        currentTask = URLSession.shared.dataTask(with: makeURL(query: query)) { [weak self] data, response, error in
            guard let self = self else { return }

            if let data = data {
                let repos = try? JSONDecoder().decode([Repository].self, from: data)

                DispatchQueue.main.async {
                    self.repositories = repos ?? []
                    self.isLoading = false
                }
            }
        }
        currentTask?.resume()
    }

    func loadMore() {
        // Load next page
    }
}

class SearchViewController: UIViewController {
    let viewModel = RepositoryViewModel()
    var tableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        // ✅ All ViewModel data is preserved!
        print("Repositories in ViewModel: \(viewModel.repositories.count)")
        print("Search query: \(viewModel.searchQuery)")
        print("Is loading: \(viewModel.isLoading)")

        coordinator.animate(alongsideTransition: { _ in
            // Just reload with same data
            self.tableView.reloadData()
        })
    }
}

// SwiftUI Example
class RepositoryViewModel: ObservableObject {
    @Published var repositories: [Repository] = []
    @Published var isLoading: Bool = false
    @Published var searchQuery: String = ""

    func search(query: String) {
        isLoading = true
        searchQuery = query

        URLSession.shared.dataTask(with: makeURL(query: query)) { [weak self] data, response, error in
            guard let self = self else { return }

            if let data = data {
                let repos = try? JSONDecoder().decode([Repository].self, from: data)

                DispatchQueue.main.async {
                    self.repositories = repos ?? []
                    self.isLoading = false
                }
            }
        }.resume()
    }
}

struct SearchView: View {
    @StateObject private var viewModel = RepositoryViewModel()

    var body: some View {
        VStack {
            TextField("Search", text: $viewModel.searchQuery)
                .onSubmit {
                    viewModel.search(query: viewModel.searchQuery)
                }

            if viewModel.isLoading {
                ProgressView()
            } else {
                List(viewModel.repositories) { repo in
                    Text(repo.name)
                }
            }
        }
        .onAppear {
            print("View appeared")
            // ✅ ViewModel still has data from before rotation
        }
    }
}
```

### Key Takeaways

| Framework | Property Wrapper | Data Survives Rotation? |
|-----------|-----------------|-------------------------|
| **UIKit** | `let viewModel = ViewModel()` | ✅ YES - ViewController property |
| **UIKit** | `var viewModel = ViewModel()` | ✅ YES - ViewController property |
| **SwiftUI** | `@StateObject private var viewModel` | ✅ YES - SwiftUI owns it |
| **SwiftUI** | `@ObservedObject var viewModel` (created) | ❌ NO - Recreated with View |
| **SwiftUI** | `@ObservedObject var viewModel` (passed) | ✅ YES - Parent owns it |

### Summary: ViewModel Data Preservation

**UIKit:**
```swift
// ✅ ALWAYS survives rotation
class ViewController: UIViewController {
    let viewModel = MyViewModel()
    // All data in viewModel is preserved
}
```

**SwiftUI:**
```swift
// ✅ Use @StateObject for ownership
struct MyView: View {
    @StateObject private var viewModel = MyViewModel()
    // All data in viewModel is preserved
}

// ✅ Use @ObservedObject when passed from parent
struct ChildView: View {
    @ObservedObject var viewModel: MyViewModel
    // Safe - parent owns it
}
```

**Bottom Line:**
- **ViewModels ALWAYS keep data during rotation** ✅
- UIKit: ViewModel is a property of ViewController
- SwiftUI: Use `@StateObject` for ownership
- Network requests continue running
- All state variables are preserved
- No need to re-fetch data

## 1. Supporting Screen Rotation

### Enable Supported Orientations (Project Settings)

In Xcode:
1. Select your target
2. Go to "General" tab
3. Under "Deployment Info" → "Device Orientation", check supported orientations

### Programmatically Control Supported Orientations

```swift
// In AppDelegate or SceneDelegate
func application(_ application: UIApplication,
                supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
    return .all // or .portrait, .landscape, .allButUpsideDown
}

// Per ViewController (UIKit)
class MyViewController: UIViewController {
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait // Only portrait
    }

    override var shouldAutorotate: Bool {
        return true // Allow rotation
    }
}
```

## 2. Handling Rotation in UIKit

### Detecting Orientation Changes

```swift
class ViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        // Register for orientation changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(orientationDidChange),
            name: UIDevice.orientationDidChangeNotification,
            object: nil
        )
    }

    @objc func orientationDidChange() {
        let orientation = UIDevice.current.orientation

        switch orientation {
        case .portrait:
            print("Portrait mode")
            updateLayoutForPortrait()
        case .landscapeLeft, .landscapeRight:
            print("Landscape mode")
            updateLayoutForLandscape()
        default:
            break
        }
    }

    func updateLayoutForPortrait() {
        // Adjust UI for portrait
    }

    func updateLayoutForLandscape() {
        // Adjust UI for landscape
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
```

### Using viewWillTransition (Recommended)

```swift
class ViewController: UIViewController {
    var isLandscape = false
    var currentData: [String] = ["Item 1", "Item 2", "Item 3"]

    override func viewWillTransition(to size: CGSize,
                                    with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        // Detect orientation
        isLandscape = size.width > size.height

        // Animate alongside rotation
        coordinator.animate(alongsideTransition: { context in
            // Update UI during rotation animation
            self.updateLayout(for: size)
        }, completion: { context in
            // Completed rotation
            print("Rotation completed")
            self.reloadDataIfNeeded()
        })
    }

    func updateLayout(for size: CGSize) {
        if isLandscape {
            // Landscape layout
            collectionView.collectionViewLayout = landscapeLayout
        } else {
            // Portrait layout
            collectionView.collectionViewLayout = portraitLayout
        }
    }

    func reloadDataIfNeeded() {
        // Refresh data if needed
        tableView.reloadData()
    }
}
```

### Preserving Data During Rotation

```swift
class DataViewController: UIViewController {
    // Properties that survive rotation
    var repositories: [Repository] = []
    var selectedIndex: Int = 0
    var scrollPosition: CGFloat = 0
    var searchQuery: String = ""

    override func viewWillTransition(to size: CGSize,
                                    with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        // Save scroll position before rotation
        scrollPosition = tableView.contentOffset.y

        coordinator.animate(alongsideTransition: { _ in
            // Layout updates
        }, completion: { _ in
            // Restore scroll position after rotation
            self.tableView.contentOffset.y = self.scrollPosition
        })
    }
}
```

## 3. Handling Rotation in SwiftUI

### Detecting Orientation in SwiftUI

```swift
import SwiftUI

struct RotationAwareView: View {
    @State private var orientation = UIDevice.current.orientation

    var body: some View {
        VStack {
            if orientation.isPortrait {
                Text("Portrait Mode")
                portraitLayout
            } else if orientation.isLandscape {
                Text("Landscape Mode")
                landscapeLayout
            }
        }
        .onReceive(NotificationCenter.default.publisher(
            for: UIDevice.orientationDidChangeNotification
        )) { _ in
            orientation = UIDevice.current.orientation
        }
    }

    var portraitLayout: some View {
        VStack(spacing: 20) {
            Image(systemName: "photo")
                .font(.largeTitle)
            Text("Content")
        }
    }

    var landscapeLayout: some View {
        HStack(spacing: 20) {
            Image(systemName: "photo")
                .font(.title)
            Text("Content")
        }
    }
}
```

### Using GeometryReader for Adaptive Layouts

```swift
struct AdaptiveView: View {
    @State private var repositories: [Repository] = []

    var body: some View {
        GeometryReader { geometry in
            if geometry.size.width > geometry.size.height {
                // Landscape
                landscapeLayout(width: geometry.size.width)
            } else {
                // Portrait
                portraitLayout(width: geometry.size.width)
            }
        }
    }

    func portraitLayout(width: CGFloat) -> some View {
        VStack {
            ForEach(repositories) { repo in
                RepositoryRowView(repository: repo)
            }
        }
    }

    func landscapeLayout(width: CGFloat) -> some View {
        HStack {
            List(repositories) { repo in
                Text(repo.name)
            }
            .frame(width: width * 0.3)

            // Detail view
            if let first = repositories.first {
                RepositoryDetailView(repository: first)
            }
        }
    }
}
```

### Environment-Based Orientation Detection

```swift
struct ContentView: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass

    var body: some View {
        if horizontalSizeClass == .compact && verticalSizeClass == .regular {
            // Portrait (iPhone)
            portraitView
        } else if horizontalSizeClass == .regular && verticalSizeClass == .compact {
            // Landscape (iPhone)
            landscapeView
        } else {
            // iPad or other
            regularView
        }
    }

    var portraitView: some View {
        VStack {
            Text("Portrait iPhone")
        }
    }

    var landscapeView: some View {
        HStack {
            Text("Landscape iPhone")
        }
    }

    var regularView: some View {
        Text("iPad or Regular")
    }
}
```

## 4. Preserving Data During Rotation

### UIKit: Using Properties (Recommended)

```swift
class SearchViewController: UIViewController {
    // ✅ Properties survive rotation automatically
    var searchResults: [Repository] = []
    var currentPage: Int = 1
    var searchQuery: String = ""
    var selectedRepository: Repository?

    // ❌ Views are recreated - don't store data here
    var tableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        loadData()
    }

    func loadData() {
        // Load data into properties
        searchResults = fetchRepositories(query: searchQuery, page: currentPage)
        tableView.reloadData()
    }

    override func viewWillTransition(to size: CGSize,
                                    with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        // Data in properties is preserved
        // Just update layout
        coordinator.animate(alongsideTransition: { _ in
            self.tableView.reloadData()
        })
    }
}
```

### UIKit: State Restoration

```swift
class DetailViewController: UIViewController {
    var repositoryID: String?
    var scrollPosition: CGFloat = 0

    // State restoration
    override func encodeRestorableState(with coder: NSCoder) {
        super.encodeRestorableState(with: coder)

        coder.encode(repositoryID, forKey: "repositoryID")
        coder.encode(scrollPosition, forKey: "scrollPosition")
    }

    override func decodeRestorableState(with coder: NSCoder) {
        super.decodeRestorableState(with: coder)

        repositoryID = coder.decodeObject(forKey: "repositoryID") as? String
        scrollPosition = CGFloat(coder.decodeFloat(forKey: "scrollPosition"))

        // Restore state
        restoreContent()
    }

    func restoreContent() {
        if let id = repositoryID {
            loadRepository(id: id)
            tableView.contentOffset.y = scrollPosition
        }
    }
}
```

### SwiftUI: Using @State (Automatic Preservation)

```swift
struct RepositoryListView: View {
    // ✅ @State properties automatically survive rotation
    @State private var repositories: [Repository] = []
    @State private var searchText: String = ""
    @State private var selectedRepository: Repository?
    @State private var currentPage: Int = 1

    var body: some View {
        VStack {
            SearchBar(text: $searchText)

            List(repositories) { repo in
                RepositoryRow(repository: repo)
                    .onTapGesture {
                        selectedRepository = repo
                    }
            }
        }
        .onAppear {
            loadRepositories()
        }
    }

    func loadRepositories() {
        // Load data
        repositories = fetchRepositories()
    }

    // Data automatically preserved during rotation!
}
```

### SwiftUI: Using @StateObject for Complex Data

```swift
// ViewModel survives rotation
class RepositoryViewModel: ObservableObject {
    @Published var repositories: [Repository] = []
    @Published var isLoading: Bool = false
    @Published var searchQuery: String = ""
    @Published var currentPage: Int = 1

    func fetchRepositories() {
        isLoading = true

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }

            let results = self.performSearch(query: self.searchQuery, page: self.currentPage)

            DispatchQueue.main.async {
                self.repositories = results
                self.isLoading = false
            }
        }
    }
}

struct SearchView: View {
    @StateObject private var viewModel = RepositoryViewModel()

    var body: some View {
        GeometryReader { geometry in
            VStack {
                SearchBar(text: $viewModel.searchQuery)

                if viewModel.isLoading {
                    ProgressView()
                } else {
                    if geometry.size.width > geometry.size.height {
                        landscapeLayout
                    } else {
                        portraitLayout
                    }
                }
            }
        }
    }

    var portraitLayout: some View {
        List(viewModel.repositories) { repo in
            Text(repo.name)
        }
    }

    var landscapeLayout: some View {
        HStack {
            List(viewModel.repositories) { repo in
                Text(repo.name)
            }
            .frame(maxWidth: 300)

            Text("Detail View")
        }
    }

    // ✅ viewModel and all its data survives rotation!
}
```

## 5. Layout Updates During Rotation

### UIKit: Auto Layout Constraints

```swift
class AdaptiveViewController: UIViewController {
    let imageView = UIImageView()
    let label = UILabel()

    var portraitConstraints: [NSLayoutConstraint] = []
    var landscapeConstraints: [NSLayoutConstraint] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        setupViews()
        setupConstraints()
        activateConstraintsForCurrentOrientation()
    }

    func setupViews() {
        imageView.translatesAutoresizingMaskIntoConstraints = false
        label.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(imageView)
        view.addSubview(label)
    }

    func setupConstraints() {
        // Portrait constraints
        portraitConstraints = [
            imageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 200),
            imageView.heightAnchor.constraint(equalToConstant: 200),

            label.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 20),
            label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            label.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ]

        // Landscape constraints
        landscapeConstraints = [
            imageView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            imageView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 150),
            imageView.heightAnchor.constraint(equalToConstant: 150),

            label.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 20),
            label.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ]
    }

    override func viewWillTransition(to size: CGSize,
                                    with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        coordinator.animate(alongsideTransition: { _ in
            self.activateConstraintsForOrientation(size: size)
        })
    }

    func activateConstraintsForCurrentOrientation() {
        let size = view.bounds.size
        activateConstraintsForOrientation(size: size)
    }

    func activateConstraintsForOrientation(size: CGSize) {
        if size.width > size.height {
            // Landscape
            NSLayoutConstraint.deactivate(portraitConstraints)
            NSLayoutConstraint.activate(landscapeConstraints)
        } else {
            // Portrait
            NSLayoutConstraint.deactivate(landscapeConstraints)
            NSLayoutConstraint.activate(portraitConstraints)
        }

        view.layoutIfNeeded()
    }
}
```

### SwiftUI: Adaptive Layouts

```swift
struct AdaptiveContentView: View {
    let repositories: [Repository]

    var body: some View {
        GeometryReader { geometry in
            Group {
                if geometry.size.width > 600 {
                    // Wide layout (iPad landscape, etc.)
                    HStack(spacing: 0) {
                        List(repositories) { repo in
                            RepositoryRow(repository: repo)
                        }
                        .frame(width: geometry.size.width * 0.4)

                        RepositoryDetailView(repository: repositories.first)
                    }
                } else if geometry.size.width > geometry.size.height {
                    // Landscape (iPhone)
                    HStack {
                        List(repositories) { repo in
                            CompactRepositoryRow(repository: repo)
                        }
                    }
                } else {
                    // Portrait (iPhone)
                    List(repositories) { repo in
                        FullRepositoryRow(repository: repo)
                    }
                }
            }
        }
    }
}
```

## 6. Preserving Scroll Position

### UIKit: TableView/CollectionView

```swift
class ScrollPreservingViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!

    var savedScrollPosition: CGPoint = .zero
    var repositories: [Repository] = []

    override func viewWillTransition(to size: CGSize,
                                    with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        // Save scroll position and selected row
        savedScrollPosition = tableView.contentOffset
        let selectedIndexPath = tableView.indexPathForSelectedRow

        coordinator.animate(alongsideTransition: { _ in
            // Update layout
            self.tableView.reloadData()
        }, completion: { _ in
            // Restore scroll position
            self.tableView.contentOffset = self.savedScrollPosition

            // Restore selection
            if let indexPath = selectedIndexPath {
                self.tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
            }
        })
    }
}
```

### SwiftUI: ScrollViewReader

```swift
struct ScrollPreservingView: View {
    @State private var repositories: [Repository] = []
    @State private var scrollToID: String?

    var body: some View {
        GeometryReader { geometry in
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack {
                        ForEach(repositories) { repo in
                            RepositoryRow(repository: repo)
                                .id(repo.id)
                        }
                    }
                }
                .onChange(of: geometry.size) { oldSize, newSize in
                    // Maintain scroll position on rotation
                    if let id = scrollToID {
                        proxy.scrollTo(id, anchor: .top)
                    }
                }
                .onAppear {
                    // Track visible item
                    scrollToID = repositories.first?.id
                }
            }
        }
    }
}
```

## 7. Real-World Examples

### Example 1: Repository Search with Rotation

```swift
class RepositorySearchViewController: UIViewController {
    var tableView: UITableView!
    var searchBar: UISearchBar!

    // Data preserved during rotation
    var repositories: [Repository] = []
    var searchQuery: String = ""
    var isLoading: Bool = false
    var currentPage: Int = 1
    var selectedRepository: Repository?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()

        if !repositories.isEmpty {
            tableView.reloadData()
        }
    }

    func setupUI() {
        searchBar = UISearchBar()
        searchBar.delegate = self
        searchBar.text = searchQuery // Restore search text

        tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self

        view.addSubview(searchBar)
        view.addSubview(tableView)

        // Setup constraints
        setupConstraints()
    }

    override func viewWillTransition(to size: CGSize,
                                    with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        // Save state
        let scrollPosition = tableView.contentOffset

        coordinator.animate(alongsideTransition: { _ in
            // Data is already preserved in properties
            // Just update layout
            self.updateLayoutForSize(size)
        }, completion: { _ in
            // Restore scroll
            self.tableView.contentOffset = scrollPosition
        })
    }

    func updateLayoutForSize(_ size: CGSize) {
        if size.width > size.height {
            // Landscape - show more columns or side-by-side
            tableView.rowHeight = 60
        } else {
            // Portrait - standard layout
            tableView.rowHeight = 80
        }
    }

    func performSearch(query: String) {
        searchQuery = query
        isLoading = true

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }

            // API call
            let results = self.fetchRepositories(query: query)

            DispatchQueue.main.async {
                self.repositories = results
                self.isLoading = false
                self.tableView.reloadData()
            }
        }
    }
}

extension RepositorySearchViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        if let query = searchBar.text {
            performSearch(query: query)
        }
    }
}

extension RepositorySearchViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return repositories.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let repo = repositories[indexPath.row]
        cell.textLabel?.text = repo.name
        cell.detailTextLabel?.text = repo.description
        return cell
    }
}
```

### Example 2: SwiftUI Adaptive Repository List

```swift
struct RepositoryListView: View {
    @StateObject private var viewModel = RepositoryViewModel()
    @State private var orientation = UIDevice.current.orientation

    var body: some View {
        GeometryReader { geometry in
            NavigationView {
                VStack {
                    SearchBar(text: $viewModel.searchQuery)
                        .onSubmit {
                            viewModel.search()
                        }

                    if viewModel.isLoading {
                        ProgressView()
                    } else {
                        repositoryList(geometry: geometry)
                    }
                }
                .navigationTitle("Repositories")
            }
            .onReceive(NotificationCenter.default.publisher(
                for: UIDevice.orientationDidChangeNotification
            )) { _ in
                orientation = UIDevice.current.orientation
            }
        }
    }

    @ViewBuilder
    func repositoryList(geometry: GeometryProxy) -> some View {
        if geometry.size.width > geometry.size.height {
            // Landscape - two column
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    ForEach(viewModel.repositories) { repo in
                        RepositoryCard(repository: repo)
                    }
                }
                .padding()
            }
        } else {
            // Portrait - single column
            List(viewModel.repositories) { repo in
                NavigationLink(destination: RepositoryDetailView(repository: repo)) {
                    RepositoryRow(repository: repo)
                }
            }
        }
    }
}

class RepositoryViewModel: ObservableObject {
    @Published var repositories: [Repository] = []
    @Published var searchQuery: String = ""
    @Published var isLoading: Bool = false

    func search() {
        isLoading = true

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }

            let results = self.performSearch(query: self.searchQuery)

            DispatchQueue.main.async {
                self.repositories = results
                self.isLoading = false
            }
        }
    }

    private func performSearch(query: String) -> [Repository] {
        // API call
        return []
    }
}
```

## 8. Best Practices

### ✅ Do's

1. **Store data in properties, not in views**
   ```swift
   // ✅ Good
   var repositories: [Repository] = []

   // ❌ Bad
   @IBOutlet var tableView: UITableView! // View, not data
   ```

2. **Use Auto Layout or GeometryReader for adaptive layouts**
   ```swift
   // ✅ Good - adapts to size changes
   GeometryReader { geometry in
       if geometry.size.width > geometry.size.height {
           landscapeLayout
       } else {
           portraitLayout
       }
   }
   ```

3. **Preserve scroll position during rotation**
   ```swift
   // ✅ Save before rotation, restore after
   let scrollPos = tableView.contentOffset
   // ... rotation ...
   tableView.contentOffset = scrollPos
   ```

4. **Use @StateObject in SwiftUI for ViewModels**
   ```swift
   // ✅ Survives rotation
   @StateObject private var viewModel = ViewModel()
   ```

5. **Test rotation in both directions**

### ❌ Don'ts

1. **Don't recreate data unnecessarily**
   ```swift
   // ❌ Bad - reloads data on rotation
   override func viewWillTransition(...) {
       fetchDataFromAPI() // Wasteful!
   }
   ```

2. **Don't use @ObservedObject for root ViewModels**
   ```swift
   // ❌ Bad - might be recreated
   @ObservedObject var viewModel = ViewModel()

   // ✅ Good - survives rotation
   @StateObject private var viewModel = ViewModel()
   ```

3. **Don't hardcode sizes**
   ```swift
   // ❌ Bad
   imageView.frame = CGRect(x: 0, y: 0, width: 320, height: 480)

   // ✅ Good
   imageView.translatesAutoresizingMaskIntoConstraints = false
   NSLayoutConstraint.activate([...])
   ```

## 9. Testing Rotation

### Programmatically Trigger Rotation (Testing)

```swift
// For testing in UIViewController
extension UIViewController {
    func simulateRotation(to orientation: UIInterfaceOrientation) {
        let windowScene = view.window?.windowScene

        let geometryPreferences = UIWindowScene.GeometryPreferences.iOS(
            interfaceOrientations: UIInterfaceOrientationMask(rawValue: 1 << orientation.rawValue)
        )

        windowScene?.requestGeometryUpdate(geometryPreferences) { error in
            print("Rotation error: \(error)")
        }
    }
}

// Usage
simulateRotation(to: .landscapeRight)
```

### Debug Rotation Issues

```swift
override func viewWillTransition(to size: CGSize,
                                with coordinator: UIViewControllerTransitionCoordinator) {
    super.viewWillTransition(to: size, with: coordinator)

    print("📱 Rotating to size: \(size)")
    print("📦 Current data count: \(repositories.count)")
    print("🔍 Search query: \(searchQuery)")
    print("📍 Scroll position: \(tableView.contentOffset)")

    coordinator.animate(alongsideTransition: { _ in
        print("🔄 During rotation")
    }, completion: { _ in
        print("✅ Rotation completed")
        print("📦 Data count after: \(self.repositories.count)")
    })
}
```

## Summary Table

| Aspect | UIKit | SwiftUI |
|--------|-------|---------|
| **Detect Rotation** | `viewWillTransition` | `GeometryReader` or `NotificationCenter` |
| **Data Preservation** | Store in properties | `@State`, `@StateObject` |
| **Layout Updates** | Auto Layout constraints | `GeometryReader`, size classes |
| **Scroll Position** | Save/restore `contentOffset` | `ScrollViewReader` |
| **Orientation Control** | `supportedInterfaceOrientations` | `Info.plist` settings |

## See Also

- [UIKit SwiftUI Data Passing](uikit_swiftui_data_passing.md)
- [Memory Leak Detection](advanced/memory_leak_detection.md)
- [Architecture Patterns](../../architecture_patterns.md)

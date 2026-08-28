# iOS Data Storage Options — The Complete Architecture & Implementation Guide

A comprehensive guide to choosing, architecting, and implementing storage in iOS apps—featuring complete step-by-step **Implementation TODOs** for all storage mechanisms, plus a deep-dive dual-stack roadmap for implementing **both Core Data AND SwiftData**.

---

## 🧭 Quick Decision Tree

```text
What type of data are you storing?
  │
  ├── 🔐 Passwords, auth tokens, secrets, API keys ────────► Keychain (Security.framework)
  │
  ├── ⚙️ Small user settings, flags, theme (< 1MB) ────────► UserDefaults / @AppStorage
  │
  ├── 📁 Raw files, images, PDFs, audio, temp cache ──────► FileManager (Documents / Caches)
  │
  ├── 🗄️ Large structured data, relationships, queries ───► Core Data (iOS 13+) OR SwiftData (iOS 17+)
  │
  ├── ⚡ Low-level embedded SQL queries / cross-platform ─► SQLite3 / GRDB
  │
  ├── ☁️ Simple key-value sync across Apple devices ──────► NSUbiquitousKeyValueStore
  │
  └── 🌐 Complex multi-device cloud database sync ────────► CloudKit (CKSyncEngine)
```

---

## 📊 Comprehensive Storage Comparison Matrix

| Storage Option | Max Size Limit | Encryption / Security | Search / Query Speed | iCloud Sync Support | Minimum iOS | Best Use Case |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **UserDefaults** | < 1MB recommended | ❌ Plaintext Plist | ❌ Key lookup only | ❌ No | iOS 2.0+ | UI flags, theme, onboarding completed |
| **Keychain** | ~1MB per item | ✅ Hardware AES-256 (Secure Enclave) | ❌ Key lookup only | ✅ iCloud Keychain | iOS 2.0+ | Auth tokens, passwords, biometrics |
| **FileManager (Disk)** | Device storage | ⚠️ Sandbox only (Protected on lock) | ❌ File paths only | ✅ iCloud Drive / Backup | iOS 2.0+ | Cached images, PDFs, raw JSON files |
| **Core Data** | Device storage | ⚠️ Optional SQLite encryption | ⚡ Indexed B-Tree & Predicates | ✅ NSPersistentCloudKitContainer | iOS 3.0+ | Large relational graphs, legacy/enterprise apps |
| **SwiftData** | Device storage | ⚠️ Optional SQLite encryption | ⚡ Modern `#Predicate` Queries | ✅ Built-in CloudKit sync | iOS 17.0+ | Modern SwiftUI apps, macro-driven models |
| **SQLite / GRDB** | Device storage | ⚠️ SQLCipher available | ⚡ Raw SQL optimization | ❌ Manual | iOS 2.0+ | Cross-platform schemas, raw SQL power |
| **iCloud KV Store** | 1MB total (1024 keys) | ✅ Encrypted in transit & at rest | ❌ Key lookup only | ✅ Automatic | iOS 5.0+ | User settings synced across iPhone/iPad/Mac |
| **CloudKit** | 1PB+ (Tiered) | ✅ Apple Cloud Security | ⚡ Server-side Predicates | ✅ Native | iOS 8.0+ | Multi-user cloud sync, shared records |

---

## 1. Storage Option Overviews & Code

### 1.1 UserDefaults (`@AppStorage`)

**What it is:** Property list (`.plist`) backed key-value dictionary stored on disk in the app sandbox.

```swift
// Swift Standard API
UserDefaults.standard.set("dark", forKey: "app_theme")
UserDefaults.standard.set(true, forKey: "is_logged_in")
let theme = UserDefaults.standard.string(forKey: "app_theme") ?? "system"

// Modern SwiftUI @AppStorage
struct SettingsView: View {
    @AppStorage("app_theme") private var appTheme: String = "system"
    @AppStorage("notifications_enabled") private var notificationsEnabled: Bool = true

    var body: some View {
        Toggle("Notifications", isOn: $notificationsEnabled)
    }
}
```

---

### 1.2 Keychain (`Security.framework`)

**What it is:** An encrypted SQLite database managed by the iOS security subsystem (`securityd`) and hardware Secure Enclave.

```swift
import Security

struct KeychainHelper {
    static func save(key: String, data: Data) -> OSStatus {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        SecItemDelete(query as CFDictionary)
        return SecItemAdd(query as CFDictionary, nil)
    }

    static func read(key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        return status == errSecSuccess ? (result as? Data) : nil
    }
}
```

---

### 1.3 File System & Sandbox Directories (`FileManager`)

**What it is:** Raw file read/write access to sandboxed directories:

• **Documents (`.documentDirectory`):** User-generated content. Backed up to iCloud.  
• **Application Support (`.applicationSupportDirectory`):** App data files not directly exposed to user. Backed up to iCloud.  
• **Caches (`.cachesDirectory`):** Discardable cache files (images, downloads). **Not** backed up. OS may purge on low disk space.  
• **Temporary (`temporaryDirectory`):** Ephemeral files deleted when app is not running.  

```swift
func saveImageToDisk(image: UIImage, filename: String) throws -> URL {
    guard let data = image.jpegData(compressionQuality: 0.8) else {
        throw NSError(domain: "ImageError", code: -1)
    }
    let cachesDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
    let fileURL = cachesDir.appendingPathComponent(filename)
    try data.write(to: fileURL, options: .atomic)
    return fileURL
}
```

---

## 2. Deep-Dive: Core Data vs. SwiftData Dual-Stack Roadmap

Many modern iOS applications must support **both Core Data and SwiftData** (e.g., maintaining backward compatibility for iOS 15/16 with Core Data while enabling SwiftData for iOS 17+, or migrating incrementally).

```text
┌─────────────────────────────────────────────────────────────┐
│                 Unified Repository Protocol                 │
│                 (RepositoryStorageProtocol)                 │
└──────────────────────────────┬──────────────────────────────┘
                               │
               ┌───────────────┴───────────────┐
               ▼                               ▼
┌──────────────────────────────┐┌──────────────────────────────┐
│      Core Data Provider      ││      SwiftData Provider      │
│         (iOS 13+)            ││         (iOS 17+)            │
├──────────────────────────────┤├──────────────────────────────┤
│ • NSPersistentContainer      ││ • ModelContainer             │
│ • NSManagedObjectContext     ││ • ModelContext               │
│ • NSFetchRequest & Predicate ││ • @Query & #Predicate        │
│ • .xcdatamodeld Schema       ││ • @Model Macro Definition    │
│ • Background Context Queue   ││ • ModelActor Concurrency     │
└──────────────────────────────┘└──────────────────────────────┘
```

---

### 2.1 Core Data Implementation Architecture

#### Step 1: Model Entity Definition (`.xcdatamodeld`)
Create `AppDatabase.xcdatamodeld` with entity `CDRepository`:
* `id`: String (Indexed, Non-optional)
* `name`: String
* `starCount`: Integer 64
* `ownerName`: String
* `updatedAt`: Date

#### Step 2: Thread-Safe Persistent Container Stack

```swift
import CoreData

final class CoreDataStack {
    static let shared = CoreDataStack()

    let persistentContainer: NSPersistentContainer

    private init() {
        persistentContainer = NSPersistentContainer(name: "AppDatabase")
        
        guard let description = persistentContainer.persistentStoreDescriptions.first else {
            fatalError("Failed to retrieve persistent store description.")
        }
        // Enable automatic lightweight migration
        description.setOption(true as NSNumber, forKey: NSMigratePersistentStoresAutomaticallyOption)
        description.setOption(true as NSNumber, forKey: NSInferMappingModelAutomaticallyOption)

        persistentContainer.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("Unresolved Core Data error \(error), \(error.userInfo)")
            }
        }
        persistentContainer.viewContext.automaticallyMergesChangesFromParent = true
        persistentContainer.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    var viewContext: NSManagedObjectContext {
        persistentContainer.viewContext
    }

    func performBackgroundTask(_ block: @escaping (NSManagedObjectContext) -> Void) {
        persistentContainer.performBackgroundTask(block)
    }
}
```

#### Step 3: CRUD Operations in Core Data

```swift
final class CoreDataRepositoryService {
    private let stack = CoreDataStack.shared

    // Create / Update
    func saveRepository(id: String, name: String, stars: Int, owner: String) {
        let context = stack.viewContext
        let request: NSFetchRequest<CDRepository> = CDRepository.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id)

        do {
            let existing = try context.fetch(request).first
            let repo = existing ?? CDRepository(context: context)
            repo.id = id
            repo.name = name
            repo.starCount = Int64(stars)
            repo.ownerName = owner
            repo.updatedAt = Date()

            try context.save()
        } catch {
            print("❌ Core Data save error: \(error)")
        }
    }

    // Fetch with Predicate & Sort
    func fetchTopRepositories(minStars: Int) -> [CDRepository] {
        let request: NSFetchRequest<CDRepository> = CDRepository.fetchRequest()
        request.predicate = NSPredicate(format: "starCount >= %d", minStars)
        request.sortDescriptors = [NSSortDescriptor(key: "starCount", ascending: false)]
        return (try? stack.viewContext.fetch(request)) ?? []
    }

    // Batch Delete
    func deleteAll() {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = CDRepository.fetchRequest()
        let batchDelete = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        _ = try? stack.viewContext.execute(batchDelete)
    }
}
```

---

### 2.2 SwiftData Implementation Architecture (iOS 17+)

> **📁 Live Working Implementation in Project (Clean 3-Tier Architecture):**  
> • Data Layer Stack: [`SwiftDataStack.swift`](../../../../github_repo_search_iOS_app/Modules/Feature/UI/Samples/Intermediate/Offline/SwiftDataStack.swift) (`SwiftDataStackProtocol`, `ModelContainer`, `@ModelActor`)  
> • Data Layer Models: [`OfflineRepoItem.swift`](../../../../github_repo_search_iOS_app/Modules/Feature/UI/Samples/Intermediate/Offline/OfflineRepoItem.swift) (4 Normalized Tables: Repos, Owners, Tags, AuditLogs)  
> • Repository Layer: [`OfflineRepository.swift`](../../../../github_repo_search_iOS_app/Modules/Feature/UI/Samples/Intermediate/Offline/OfflineRepository.swift) (`OfflineRepositoryProtocol` & `SwiftDataOfflineRepository`)  
> • Presentation ViewModel: [`SwiftDataOfflineViewModel.swift`](../../../../github_repo_search_iOS_app/Modules/Feature/UI/Samples/Intermediate/Offline/SwiftDataOfflineViewModel.swift) (Swift 6 `@Observable` MVVM)  
> • Presentation View: [`SwiftDataOfflineStorageView.swift`](../../../../github_repo_search_iOS_app/Modules/Feature/UI/Samples/Intermediate/Offline/SwiftDataOfflineStorageView.swift) (Interactive Multi-Table Offline & Sync View)  

#### Step 1: Declarative `@Model` Schema Definition

```swift
import SwiftData
import Foundation

@Model
final class SDRepository {
    @Attribute(.unique) var id: String
    var name: String
    var starCount: Int
    var ownerName: String
    var updatedAt: Date
    
    @Relationship(deleteRule: .cascade) 
    var tags: [SDTag]? = []

    init(id: String, name: String, starCount: Int, ownerName: String, updatedAt: Date = Date()) {
        self.id = id
        self.name = name
        self.starCount = starCount
        self.ownerName = ownerName
        self.updatedAt = updatedAt
    }
}

@Model
final class SDTag {
    var name: String
    var repository: SDRepository?

    init(name: String) {
        self.name = name
    }
}
```

#### Step 2: App Entry Point ModelContainer Setup

```swift
import SwiftUI
import SwiftData

@main
struct RepoSearchApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([SDRepository.self, SDTag.self])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
```

#### Step 3: SwiftUI View Integration with `@Query` & Concurrency

```swift
struct SwiftDataRepoListView: View {
    @Environment(\.modelContext) private var modelContext
    
    // Type-safe Swift predicate macro & sorting
    @Query(
        filter: #Predicate<SDRepository> { $0.starCount > 100 },
        sort: \SDRepository.starCount,
        order: .reverse
    ) private var repositories: [SDRepository]

    var body: some View {
        List {
            ForEach(repositories) { repo in
                HStack {
                    VStack(alignment: .leading) {
                        Text(repo.name).font(.headline)
                        Text(repo.ownerName).font(.caption).foregroundColor(.secondary)
                    }
                    Spacer()
                    Label("\(repo.starCount)", systemImage: "star.fill")
                        .foregroundColor(.yellow)
                }
            }
            .onDelete(perform: deleteItems)
        }
        .toolbar {
            Button("Add Sample") {
                let sample = SDRepository(id: UUID().uuidString, name: "swift-concurrency", starCount: 4500, ownerName: "apple")
                modelContext.insert(sample)
            }
        }
    }

    private func deleteItems(offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(repositories[index])
        }
    }
}
```

#### Step 4: Swift 6 Concurrency & `@Observable` ViewModel Pattern (No `@Published` Needed!)

When pairing SwiftData with clean MVVM architecture in **Swift 6 / iOS 17+**, replace legacy `ObservableObject` and `@Published` with Apple's **`@Observable`** macro and `@ModelActor`:

```swift
import Foundation
import Observation
import SwiftData

// ✅ Modern Swift 6 ViewModel: Pure stored properties are automatically observed
@Observable
@MainActor
final class SwiftDataOfflineViewModel {
    var repositories: [OfflineRepoItem] = []
    var searchText: String = ""
    var isSyncing: Bool = false
    var autoSyncEnabled: Bool = true
    
    @ObservationIgnored
    private let repository: OfflineRepositoryProtocol

    init(repository: OfflineRepositoryProtocol = SwiftDataOfflineRepository.shared) {
        self.repository = repository
    }

    func loadData() async {
        do {
            repositories = try await repository.fetchRepositories(matching: searchText, filter: 0)
        } catch {
            print("Fetch failed: \(error)")
        }
    }
}
```

In the SwiftUI View, use `@State` and `@Bindable` for seamless two-way binding without Combine overhead:

```swift
struct SwiftDataOfflineStorageView: View {
    @State private var viewModel = SwiftDataOfflineViewModel()

    var body: some View {
        @Bindable var boundViewModel = viewModel

        List(viewModel.repositories) { repo in
            Text(repo.name)
        }
        .searchable(text: $boundViewModel.searchText)
        .task {
            await viewModel.loadData()
        }
    }
}
```

#### Step 5: Background Thread Persistence with `ModelActor` (Swift Concurrency)

```swift
import SwiftData

@ModelActor
actor BackgroundDataImporter {
    func importBatchRepositories(data: [(id: String, name: String, stars: Int, owner: String)]) throws {
        for item in data {
            let repo = SDRepository(id: item.id, name: item.name, starCount: item.stars, ownerName: item.owner)
            modelContext.insert(repo)
        }
        try modelContext.save()
        print("✅ Background import completed for \(data.count) items.")
    }
}
```

#### Step 6: SwiftData Concurrency, Thread Affinity & `@MainActor` Architecture Rules

> **🔗 Official Apple Documentation & Resources:**  
> • [Apple Developer: `ModelActor` Protocol (Isolated Background Concurrency)](https://developer.apple.com/documentation/swiftdata/modelactor)  
> • [Apple Developer: `ModelContainer.mainContext` Property](https://developer.apple.com/documentation/swiftdata/modelcontainer/maincontext)  
> • [Apple Developer: `ModelContext` (Thread & Concurrency Safety)](https://developer.apple.com/documentation/swiftdata/modelcontext)  
> • [WWDC 2023 Session 10196: Dive Deeper into SwiftData](https://developer.apple.com/videos/play/wwdc2023/10196/)  

##### Why `container.mainContext` is `@MainActor`:
* Apple defines `mainContext` as `@MainActor public var mainContext: ModelContext { get }`.
* A `ModelContext` is **not thread-safe**. Any read, fetch, or mutation on `mainContext` must be performed on `@MainActor` to prevent race conditions and fatal store crashes.
* `@Model` entities fetched from `mainContext` can be safely passed to `@MainActor` ViewModels and SwiftUI Views for instant UI rendering without thread-hopping.

##### Why Annotate `@MainActor` at the Class Level:
Instead of repetitively annotating every single CRUD function with `@MainActor`:
```swift
// ✅ CLEAN STANDARD: Annotate at the Class & Protocol level
@MainActor
protocol OfflineRepositoryProtocol: Sendable { ... }

@MainActor
final class SwiftDataOfflineRepository: OfflineRepositoryProtocol {
    private var mainContext: ModelContext { container.mainContext }

    // All CRUD methods inherit @MainActor automatically!
    func insertRepository(item: OfflineRepoItem) async throws { ... }
    func fetchRepositories(...) async throws -> [OfflineRepoItem] { ... }

    // Background operations explicitly hop off @MainActor to @ModelActor
    nonisolated func importBatchBackground(items: ...) async throws -> Int {
        let importer = BackgroundOfflineImporter(modelContainer: container)
        return try await importer.importBatchItems(items: items)
    }
}
```

---

## 3. Implementation TODO Checklists for ALL Storage Options

Below are the complete, actionable developer checklists to build, verify, and maintain every data storage layer.

---

### 📋 TODO 1: Implement `UserDefaults` Storage Layer

- [ ] **Create Type-Safe UserDefaults Keys Enum:**
  - Avoid raw strings like `"user_theme"` scattered across codebase.
  - Define `enum AppStorageKey: String { case theme, hasCompletedOnboarding, lastSyncDate }`.
- [ ] **Implement Dependency-Injected Wrapper:**
  - Create `protocol KeyValueStorageProtocol` with `set()`, `string(forKey:)`, `bool(forKey:)`.
  - Provide `DefaultUserDefaultsStorage` conforming to protocol for easy unit testing mocks.
- [ ] **Register Default Fallbacks:**
  - Call `UserDefaults.standard.register(defaults: [...])` in `didFinishLaunchingWithOptions` or App `init()`.
- [ ] **Support Codable Objects Safely:**
  - Implement generic extension `setObject<T: Codable>(_ object: T, forKey: String)` with `JSONEncoder`.
  - Implement generic extension `getObject<T: Codable>(forKey: String, type: T.Type) -> T?` with `JSONDecoder`.
- [ ] **Enforce Size Guardrails:**
  - Audit storage to guarantee total payload remains under 1MB. Ensure no large JSON payloads or images are placed in UserDefaults.

---

### 📋 TODO 2: Implement `Keychain` Security Layer

- [ ] **Implement Native Security.framework CRUD Wrapper:**
  - Implement `save(key:value:)`, `read(key:) -> String?`, `delete(key:)`, `clearAll()`.
- [ ] **Set Strict Accessibility Level:**
  - Apply `kSecAttrAccessibleWhenUnlockedThisDeviceOnly` to prevent unencrypted cloud extraction and unlock when device is password protected.
- [ ] **Integrate Biometric Authentication (`LocalAuthentication`):**
  - Add `LAContext` evaluation before retrieving high-security tokens (e.g., FaceID/TouchID prompt).
- [ ] **Handle App Reinstallation Retention:**
  - Note: Keychain items persist across app uninstallations. Add an initial launch flag check in `UserDefaults` to wipe stale Keychain credentials on fresh install if required.
- [ ] **Enable Keychain Access Groups (if sharing across App Extensions / Widgets):**
  - Configure `$(AppIdentifierPrefix)com.company.shared` in Entitlements.

---

### 📋 TODO 3: Implement `FileManager` Disk Storage & Image Cache

- [ ] **Implement Directory Routing Helper:**
  - Create helpers for `.documentDirectory`, `.cachesDirectory`, and `.applicationSupportDirectory`.
- [ ] **Atomic File Writes:**
  - Always use `data.write(to: fileURL, options: .atomic)` to prevent file corruption during app crashes or power loss.
- [ ] **Exclude Temporary Cache from iCloud Backup:**
  - If saving custom support files that shouldn't sync to iCloud, apply `var values = URLResourceValues(); values.isExcludedFromBackup = true`.
- [ ] **Implement Disk Cache Purge Policy:**
  - Create automated cache cleaner function checking file timestamps and evicting items older than $X$ days (e.g., 7 days) or when cache folder exceeds $Y$ MB (e.g., 200MB).

---

### 📋 TODO 4: Implement Direct `SQLite` / `GRDB` (If Applicable)

- [ ] **Configure SQLite Threading Model:**
  - Use `SQLITE_OPEN_FULLMUTEX` or `GRDB.DatabasePool` for multi-threaded reads and serial background writes.
- [ ] **Enable Write-Ahead Logging (WAL):**
  - Execute `PRAGMA journal_mode = WAL;` and `PRAGMA synchronous = NORMAL;` for high-throughput write performance.
- [ ] **Create Database Migration Tracker:**
  - Implement integer schema versioning table `schema_migrations (version INT PRIMARY KEY)` to execute sequential DDL updates.

---

### 📋 TODO 5: Implement `Core Data` Architecture

- [ ] **Create Data Model (`.xcdatamodeld`):**
  - Define entities, attributes with explicit non-optional flags and default values, and index lookup attributes (e.g. `id`, `createdAt`).
- [ ] **Configure Relationships & Delete Rules:**
  - Set Delete Rules explicitly: `Cascade` for parent-child dependencies, `Nullify` for loose associations, `Deny` for protected records.
- [ ] **Configure `NSPersistentContainer`:**
  - Set `automaticallyMergesChangesFromParent = true` on `viewContext`.
  - Set merge policy to `NSMergeByPropertyObjectTrumpMergePolicy`.
- [ ] **Implement Background Work Queues:**
  - Never execute bulk insert/update or background sync on `viewContext`.
  - Use `container.performBackgroundTask { bgContext in ... try bgContext.save() }`.
- [ ] **Implement Batch Operations:**
  - Use `NSBatchInsertRequest` and `NSBatchDeleteRequest` for high-volume operations to bypass creating thousands of `NSManagedObject` instances in RAM.

---

### 📋 TODO 6: Implement `SwiftData` Architecture (iOS 17+)

- [ ] **Define `@Model` Classes:**
  - Annotate domain entities with `@Model`.
  - Use `@Attribute(.unique)` on primary keys.
  - Use `@Relationship(deleteRule: .cascade, inverse: \...)` on associated models.
  - Use `@Transient` on calculated or non-persisted properties.
- [ ] **Initialize `ModelContainer` in SwiftUI App Entry Point:**
  - Attach `.modelContainer(for: [SchemaModels.self])` to the root `WindowGroup`.
- [ ] **Implement UI Querying with `@Query`:**
  - Use modern Swift `#Predicate<Model> { ... }` syntax.
  - Implement dynamic sorting and search filtering via `@Query(filter:sort:)`.
- [ ] **Implement Background Concurrency using `@ModelActor`:**
  - Create `@ModelActor actor DataSyncActor` with private `modelContext` and `modelExecutor` for background API synchronization.
- [ ] **Configure CloudKit Sync (Optional):**
  - Ensure all properties have default values or are optional, and all relationships are optional to satisfy CloudKit schema rules.

---

### 📋 TODO 7: Implement Core Data $\rightarrow$ SwiftData Co-existence & Migration

- [ ] **Shared SQLite Store Architecture:**
  - Point both Core Data and SwiftData to the exact same file URL in `Application Support`.
- [ ] **Verify Schema Compatibility:**
  - SwiftData schema names match Core Data entity names; ensure attribute types and nullabilities match.
- [ ] **Unified Repository Interface (`StorageRepositoryProtocol`):**
  - Implement an abstract storage protocol:
    ```swift
    protocol DataStorageProvider {
        func save(repo: Repository) async throws
        func fetchAll() async throws -> [Repository]
        func delete(id: String) async throws
    }
    ```
  - Create `CoreDataStorageProvider` and `SwiftDataStorageProvider` and inject based on OS version availability:
    ```swift
    func makeStorageProvider() -> DataStorageProvider {
        if #available(iOS 17.0, *) {
            return SwiftDataStorageProvider()
        } else {
            return CoreDataStorageProvider()
        }
    }
    ```

---

## 4. Top Interview Questions & Golden Rules

### 💡 Interview Questions

1. **Q: What is the difference between Core Data and SQLite?**
   * *Answer:* SQLite is a lightweight relational database engine. Core Data is an **object graph management and persistence framework** that can use SQLite as a backing store, but provides in-memory object tracking, faulting, undo/redo, validation, and relationship cascades.

2. **Q: Why should you never use `UserDefaults` for large collections or tokens?**
   * *Answer:* `UserDefaults` reads the entire `.plist` file into memory on app launch. Storing large arrays slows down app startup time and increases memory footprint. Furthermore, it is unencrypted plaintext, making it insecure for secrets.

3. **Q: How does SwiftData handle background threading compared to Core Data?**
   * *Answer:* Core Data uses `NSManagedObjectContext` bound to specific queues (`perform` / `performAndWait`). SwiftData integrates with Swift Concurrency using `@ModelActor`, where an actor encapsulates its own isolated `ModelContext` and executes operations safely across threads without manual locking.

---

### 🌟 Storage Golden Rules

1. **Never store secrets in UserDefaults:** Always use **Keychain** with `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`.
2. **Never access UI context on background threads:** In Core Data, `viewContext` is strictly for `@MainActor`. In SwiftData, use `@ModelActor` for background execution.
3. **Use Atomic Writes for Files:** Always specify `.atomic` when writing data to disk with `FileManager` to prevent corrupted files during unexpected terminations.
4. **Clean up Caches periodically:** iOS may purge `.cachesDirectory` during low storage, but well-behaved apps monitor their own disk usage and proactively evict expired assets.
5. **Always test Schema Migrations:** Always verify that updating model schemas does not crash on existing user devices by verifying lightweight migrations with old SQLite database snapshots.

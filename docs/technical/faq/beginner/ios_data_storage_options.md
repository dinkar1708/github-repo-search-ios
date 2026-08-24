# iOS Data Storage Options - Complete Guide

Comprehensive guide to choosing the right storage method for your data in iOS.

## Quick Decision Tree

```
What type of data?
  ├─ Passwords, tokens, secrets → Keychain
  ├─ Small settings (< 1MB) → UserDefaults
  ├─ Large structured data → Core Data
  ├─ Files, images, documents → File System
  ├─ Simple key-value sync → iCloud Key-Value Store
  └─ Complex sync → CloudKit
```

---

## 1. UserDefaults

### What is it?
Simple key-value storage for small amounts of data.

### Use For:
- User preferences
- App settings
- Simple flags (bool values)
- Last used values
- Small strings/numbers

### ❌ Don't Use For:
- Passwords or sensitive data (use Keychain)
- Large data (> 1MB)
- Complex data structures (use Core Data)
- Files (use File System)

### Size Limit:
- Recommended: < 1MB total
- Technical limit: No hard limit, but affects performance

### Security:
- **Not encrypted** by default
- Stored in plain text
- ❌ Never store passwords here!

### Example:

```swift
// Save
UserDefaults.standard.set("Alice", forKey: "userName")
UserDefaults.standard.set(25, forKey: "userAge")
UserDefaults.standard.set(true, forKey: "isFirstLaunch")
UserDefaults.standard.synchronize() // Optional in modern iOS

// Read
let userName = UserDefaults.standard.string(forKey: "userName")
let userAge = UserDefaults.standard.integer(forKey: "userAge")
let isFirstLaunch = UserDefaults.standard.bool(forKey: "isFirstLaunch")

// Remove
UserDefaults.standard.removeObject(forKey: "userName")

// Check existence
if UserDefaults.standard.object(forKey: "userName") != nil {
    print("userName exists")
}
```

### Supported Types:
- `String`
- `Int`, `Float`, `Double`, `Bool`
- `Data`
- `Date`
- `Array`, `Dictionary` (of property list types)
- `URL`

### Custom Objects (Codable):

```swift
struct User: Codable {
    let name: String
    let age: Int
}

// Save
let user = User(name: "Alice", age: 25)
if let encoded = try? JSONEncoder().encode(user) {
    UserDefaults.standard.set(encoded, forKey: "user")
}

// Read
if let data = UserDefaults.standard.data(forKey: "user"),
   let user = try? JSONDecoder().decode(User.self, from: data) {
    print(user.name)
}
```

### Real-World Examples:

```swift
// App settings
UserDefaults.standard.set(true, forKey: "notificationsEnabled")
UserDefaults.standard.set("dark", forKey: "themeMode")
UserDefaults.standard.set(14, forKey: "fontSize")

// Last state
UserDefaults.standard.set(Date(), forKey: "lastSyncDate")
UserDefaults.standard.set(3, forKey: "currentTabIndex")

// User preferences
UserDefaults.standard.set("en", forKey: "selectedLanguage")
UserDefaults.standard.set(true, forKey: "showTutorial")
```

---

## 2. Keychain

### What is it?
Secure, encrypted storage for sensitive data.

### Use For: ⭐
- Passwords
- Authentication tokens
- API keys
- Certificates
- Credit card info (if allowed)
- Encryption keys
- Any sensitive data

### ❌ Don't Use For:
- Non-sensitive data (overhead)
- Large amounts of data
- Frequently changing data

### Size Limit:
- Individual items: ~1MB
- Total: No practical limit

### Security:
- **Encrypted** by iOS
- Survives app deletion (can be configured)
- Protected by device passcode
- ✅ Most secure option

### Example (Using KeychainAccess library):

```swift
import KeychainAccess

let keychain = Keychain(service: "com.example.app")

// Save
keychain["password"] = "secret123"
keychain["authToken"] = "abc123xyz"

// Read
let password = keychain["password"]
let token = keychain["authToken"]

// Remove
try? keychain.remove("password")

// Check existence
if let _ = keychain["password"] {
    print("Password exists")
}
```

### Example (Native API):

```swift
import Security

// Save to Keychain
func saveToKeychain(key: String, value: String) {
    let data = value.data(using: .utf8)!

    let query: [String: Any] = [
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrAccount as String: key,
        kSecValueData as String: data,
        kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked
    ]

    SecItemDelete(query as CFDictionary) // Delete if exists
    SecItemAdd(query as CFDictionary, nil)
}

// Read from Keychain
func readFromKeychain(key: String) -> String? {
    let query: [String: Any] = [
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrAccount as String: key,
        kSecReturnData as String: true,
        kSecMatchLimit as String: kSecMatchLimitOne
    ]

    var result: AnyObject?
    let status = SecItemCopyMatching(query as CFDictionary, &result)

    guard status == errSecSuccess,
          let data = result as? Data,
          let value = String(data: data, encoding: .utf8) else {
        return nil
    }

    return value
}

// Delete from Keychain
func deleteFromKeychain(key: String) {
    let query: [String: Any] = [
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrAccount as String: key
    ]

    SecItemDelete(query as CFDictionary)
}
```

### Accessibility Options:

```swift
// When to access keychain data
kSecAttrAccessibleWhenUnlocked           // Default, most secure
kSecAttrAccessibleAfterFirstUnlock       // Available after first unlock
kSecAttrAccessibleAlways                 // Always available (deprecated)
kSecAttrAccessibleWhenUnlockedThisDeviceOnly  // Doesn't sync to iCloud
```

### Real-World Examples:

```swift
// User credentials
keychain["userPassword"] = "secretPass123"
keychain["biometricToken"] = "abc123"

// API tokens
keychain["githubToken"] = "ghp_xxxxxxxxxxxx"
keychain["refreshToken"] = "refresh_abc123"

// Encryption keys
keychain["encryptionKey"] = generateEncryptionKey()
```

---

## 3. Core Data

### What is it?
Object graph and persistence framework (local database).

### Use For: ⭐
- Large amounts of structured data
- Relationships between objects
- Complex queries
- Offline storage
- Data that needs indexing

### ❌ Don't Use For:
- Simple key-value storage (use UserDefaults)
- Sensitive data without encryption
- Very large files (use File System)

### Size Limit:
- Practically unlimited
- Limited by device storage

### Security:
- Not encrypted by default
- Can enable encryption with NSPersistentStoreFileProtectionKey

### Example:

```swift
import CoreData

// Define Entity (in .xcdatamodeld)
// Entity: Repository
//   - id: String
//   - name: String
//   - stars: Int32
//   - owner: String

// Save
func saveRepository(_ repo: Repository) {
    let context = persistentContainer.viewContext

    let entity = RepositoryEntity(context: context)
    entity.id = repo.id
    entity.name = repo.name
    entity.stars = Int32(repo.stars)
    entity.owner = repo.owner

    do {
        try context.save()
        print("✅ Saved to Core Data")
    } catch {
        print("❌ Error: \(error)")
    }
}

// Fetch
func fetchRepositories() -> [RepositoryEntity] {
    let context = persistentContainer.viewContext

    let fetchRequest: NSFetchRequest<RepositoryEntity> = RepositoryEntity.fetchRequest()

    // Optional: Add predicate (filter)
    fetchRequest.predicate = NSPredicate(format: "stars > %d", 100)

    // Optional: Sort
    fetchRequest.sortDescriptors = [NSSortDescriptor(key: "stars", ascending: false)]

    do {
        let results = try context.fetch(fetchRequest)
        return results
    } catch {
        print("❌ Fetch error: \(error)")
        return []
    }
}

// Update
func updateRepository(id: String, newStars: Int) {
    let context = persistentContainer.viewContext

    let fetchRequest: NSFetchRequest<RepositoryEntity> = RepositoryEntity.fetchRequest()
    fetchRequest.predicate = NSPredicate(format: "id == %@", id)

    if let repo = try? context.fetch(fetchRequest).first {
        repo.stars = Int32(newStars)
        try? context.save()
    }
}

// Delete
func deleteRepository(_ repo: RepositoryEntity) {
    let context = persistentContainer.viewContext
    context.delete(repo)
    try? context.save()
}
```

### Relationships:

```swift
// Entity: User
//   - name: String
//   - repositories: Relationship (to-many) → Repository

// Entity: Repository
//   - name: String
//   - owner: Relationship (to-one) → User

// Query with relationship
let fetchRequest: NSFetchRequest<User> = User.fetchRequest()
fetchRequest.predicate = NSPredicate(format: "ANY repositories.stars > %d", 1000)
```

### Real-World Examples:

```swift
// Offline repository cache
saveRepository(Repository(id: "1", name: "awesome-ios", stars: 5000))

// User favorites
markAsFavorite(repositoryID: "123")

// Search history
saveSearchQuery("Swift concurrency")

// Downloaded articles for offline reading
saveArticle(article)
```

---

## 4. File System

### What is it?
Store files in app's sandbox directories.

### Use For: ⭐
- Images, videos, audio files
- PDF documents
- Downloaded files
- Large data files
- Cache data

### ❌ Don't Use For:
- Small settings (use UserDefaults)
- Sensitive data without encryption
- Structured data (use Core Data)

### Size Limit:
- Limited by device storage
- Be mindful of user's space

### Security:
- Protected by app sandbox
- Not encrypted by default
- Can encrypt files manually

### Directories:

```swift
// Documents Directory (backed up to iCloud)
let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]

// Caches Directory (not backed up, can be deleted by system)
let cachesDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]

// Temporary Directory (deleted on app exit)
let tempDir = FileManager.default.temporaryDirectory

// Application Support (backed up, for app data)
let appSupportDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
```

### Example:

```swift
// Save file
func saveFile(data: Data, filename: String) {
    let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    let fileURL = documentsDir.appendingPathComponent(filename)

    do {
        try data.write(to: fileURL)
        print("✅ File saved: \(fileURL)")
    } catch {
        print("❌ Error saving: \(error)")
    }
}

// Read file
func readFile(filename: String) -> Data? {
    let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    let fileURL = documentsDir.appendingPathComponent(filename)

    return try? Data(contentsOf: fileURL)
}

// Delete file
func deleteFile(filename: String) {
    let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    let fileURL = documentsDir.appendingPathComponent(filename)

    try? FileManager.default.removeItem(at: fileURL)
}

// Check if file exists
func fileExists(filename: String) -> Bool {
    let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    let fileURL = documentsDir.appendingPathComponent(filename)

    return FileManager.default.fileExists(atPath: fileURL.path)
}

// List all files
func listFiles() -> [String] {
    let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]

    let files = try? FileManager.default.contentsOfDirectory(
        at: documentsDir,
        includingPropertiesForKeys: nil
    )

    return files?.map { $0.lastPathComponent } ?? []
}
```

### Save Image:

```swift
func saveImage(_ image: UIImage, filename: String) {
    guard let data = image.jpegData(compressionQuality: 0.8) else { return }

    let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    let fileURL = documentsDir.appendingPathComponent(filename)

    try? data.write(to: fileURL)
}

func loadImage(filename: String) -> UIImage? {
    let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    let fileURL = documentsDir.appendingPathComponent(filename)

    guard let data = try? Data(contentsOf: fileURL) else { return nil }
    return UIImage(data: data)
}
```

### Real-World Examples:

```swift
// Downloaded repository README
saveFile(data: readmeData, filename: "repo_123_readme.md")

// User profile image
saveImage(profileImage, filename: "profile.jpg")

// Cached API responses
saveFile(data: jsonData, filename: "repos_cache.json")

// Offline PDF documents
saveFile(data: pdfData, filename: "guide.pdf")
```

---

## 5. NSCoding / Codable (Archives)

### What is it?
Encode/decode objects to/from files.

### Use For:
- Saving custom objects
- Complex data structures
- State restoration

### Example (Codable):

```swift
struct User: Codable {
    let name: String
    let age: Int
    let repositories: [Repository]
}

// Save
func saveUser(_ user: User) {
    let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    let fileURL = documentsDir.appendingPathComponent("user.json")

    if let encoded = try? JSONEncoder().encode(user) {
        try? encoded.write(to: fileURL)
    }
}

// Load
func loadUser() -> User? {
    let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    let fileURL = documentsDir.appendingPathComponent("user.json")

    guard let data = try? Data(contentsOf: fileURL),
          let user = try? JSONDecoder().decode(User.self, from: data) else {
        return nil
    }

    return user
}
```

---

## 6. SQLite (Direct)

### What is it?
Lightweight SQL database (Core Data uses SQLite underneath).

### Use For:
- When you need SQL queries
- Migration from other platforms
- Fine control over database

### ❌ Don't Use For:
- Most iOS apps (use Core Data instead)

### Example (Using GRDB):

```swift
import GRDB

// Define model
struct Repository: Codable, FetchableRecord, PersistableRecord {
    var id: String
    var name: String
    var stars: Int
}

// Setup database
let dbPath = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
    .appendingPathComponent("db.sqlite").path

let dbQueue = try DatabaseQueue(path: dbPath)

// Create table
try dbQueue.write { db in
    try db.create(table: "repository") { t in
        t.column("id", .text).primaryKey()
        t.column("name", .text).notNull()
        t.column("stars", .integer).notNull()
    }
}

// Insert
try dbQueue.write { db in
    var repo = Repository(id: "1", name: "awesome-ios", stars: 5000)
    try repo.insert(db)
}

// Query
let repos = try dbQueue.read { db in
    try Repository.fetchAll(db)
}
```

---

## 7. iCloud Key-Value Store

### What is it?
Simple key-value storage synced across user's devices via iCloud.

### Use For:
- User preferences sync
- App settings sync
- Small amounts of data (< 1MB total)

### Size Limit:
- 1MB total
- 1024 key-value pairs max

### Example:

```swift
let store = NSUbiquitousKeyValueStore.default

// Save
store.set("dark", forKey: "theme")
store.set(true, forKey: "notificationsEnabled")
store.synchronize()

// Read
let theme = store.string(forKey: "theme")
let notificationsEnabled = store.bool(forKey: "notificationsEnabled")

// Observe changes
NotificationCenter.default.addObserver(
    self,
    selector: #selector(iCloudStoreDidChange),
    name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
    object: store
)

@objc func iCloudStoreDidChange(_ notification: Notification) {
    // Sync UI with iCloud data
}
```

---

## 8. CloudKit

### What is it?
Apple's cloud database service for syncing data across devices.

### Use For:
- Large amounts of data
- Complex data structures
- User-specific data
- Public data sharing

### Example:

```swift
import CloudKit

let container = CKContainer.default()
let database = container.privateCloudDatabase

// Save record
let record = CKRecord(recordType: "Repository")
record["name"] = "awesome-ios"
record["stars"] = 5000

database.save(record) { savedRecord, error in
    if let error = error {
        print("Error: \(error)")
    } else {
        print("✅ Saved to CloudKit")
    }
}

// Fetch records
let predicate = NSPredicate(format: "stars > %d", 1000)
let query = CKQuery(recordType: "Repository", predicate: predicate)

database.perform(query, inZoneWith: nil) { records, error in
    if let records = records {
        print("Found \(records.count) repositories")
    }
}
```

---

## Storage Comparison Table

| Storage | Size Limit | Security | Sync | Use Case |
|---------|-----------|----------|------|----------|
| **UserDefaults** | < 1MB | ❌ Plain text | ❌ No | Settings, preferences |
| **Keychain** | ~1MB/item | ✅ Encrypted | ✅ Yes (optional) | Passwords, tokens |
| **Core Data** | Device storage | ❌ No (can encrypt) | ❌ No* | Structured data, offline |
| **File System** | Device storage | ❌ Sandbox only | ❌ No* | Files, images, documents |
| **SQLite** | Device storage | ❌ No | ❌ No | SQL queries, migrations |
| **iCloud KV Store** | 1MB total | ✅ Encrypted | ✅ Yes | Settings sync |
| **CloudKit** | 10GB+ | ✅ Encrypted | ✅ Yes | User data, sync |

*Can be synced manually with CloudKit or iCloud Drive

---

## Decision Flow Chart

```
What are you storing?

├─ Passwords, tokens, API keys
│  └─ Use: Keychain ✅

├─ Simple settings (theme, font size)
│  ├─ Need sync? → iCloud Key-Value Store ✅
│  └─ No sync → UserDefaults ✅

├─ Large structured data (hundreds of objects)
│  ├─ Need relationships, complex queries?
│  │  └─ Use: Core Data ✅
│  └─ Simple SQL?
│     └─ Use: SQLite ✅

├─ Files (images, PDFs, videos)
│  ├─ User documents → Documents Directory ✅
│  ├─ Cache data → Caches Directory ✅
│  └─ Temporary → Temp Directory ✅

└─ Sync across devices?
   ├─ Simple key-value → iCloud Key-Value Store ✅
   └─ Complex data → CloudKit ✅
```

---

## Best Practices

### ✅ Do's

1. **Use Keychain for sensitive data**
   ```swift
   keychain["password"] = userPassword  // ✅
   ```

2. **Use UserDefaults for simple settings**
   ```swift
   UserDefaults.standard.set(true, forKey: "darkMode")  // ✅
   ```

3. **Use Core Data for large structured data**
   ```swift
   saveRepositories(repositories)  // ✅ If many repositories
   ```

4. **Clear caches when needed**
   ```swift
   func clearCache() {
       let cachesDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
       try? FileManager.default.removeItem(at: cachesDir)
   }
   ```

### ❌ Don'ts

1. **Don't store passwords in UserDefaults**
   ```swift
   UserDefaults.standard.set("password123", forKey: "password")  // ❌ INSECURE!
   ```

2. **Don't use Core Data for simple key-value**
   ```swift
   // ❌ Overkill for simple setting
   saveToCore Data(Setting(key: "theme", value: "dark"))
   ```

3. **Don't ignore storage limits**
   ```swift
   // ❌ Bad - storing 10MB in UserDefaults
   UserDefaults.standard.set(largeData, forKey: "cache")
   ```

---

## Real-World Example: GitHub Repository App

```swift
class RepositoryStorageManager {

    // 1. UserDefaults - Simple settings
    func saveSettings() {
        UserDefaults.standard.set("dark", forKey: "theme")
        UserDefaults.standard.set(true, forKey: "showStars")
        UserDefaults.standard.set(Date(), forKey: "lastSync")
    }

    // 2. Keychain - Auth token
    func saveAuthToken(_ token: String) {
        keychain["githubToken"] = token
    }

    // 3. Core Data - Offline repositories
    func saveRepositories(_ repos: [Repository]) {
        repos.forEach { repo in
            let entity = RepositoryEntity(context: context)
            entity.id = repo.id
            entity.name = repo.name
            try? context.save()
        }
    }

    // 4. File System - Repository images/avatars
    func saveAvatar(_ image: UIImage, for userID: String) {
        let filename = "\(userID)_avatar.jpg"
        saveImage(image, filename: filename)
    }

    // 5. iCloud KV - Sync user preferences
    func syncPreferences() {
        let store = NSUbiquitousKeyValueStore.default
        store.set("dark", forKey: "theme")
        store.synchronize()
    }
}
```

---

## See Also

- [Memory Leak Detection](advanced/memory_leak_detection.md)
- [App Lifecycle](lifecycle_app.md)
- [Background Thread Execution Patterns](background_thread_execution_patterns.md)

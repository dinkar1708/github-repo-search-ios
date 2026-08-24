# Keychain Secure Storage

## Overview
AES-256 encrypted storage for sensitive data using iOS Keychain.

## Implementation

Location: `Modules/Core/Storage/KeychainManager.swift`

### Features
- AES-256 encryption
- Type-safe with Codable
- Auto-migration from UserDefaults
- Thread-safe operations
- Privacy-aware logging

## Usage

### Save Data
```swift
let keychain = KeychainManager()

// Save any Codable type
try keychain.save(favoriteUsers, for: "favoriteUsers")

// Save raw Data
try keychain.save(data, for: "myKey")
```

### Load Data
```swift
// Load typed data
let users = try keychain.load(for: "favoriteUsers", as: [FavoriteUser].self)

// Load raw Data
let data = try keychain.load(for: "myKey")
```

### Delete Data
```swift
try keychain.delete(for: "favoriteUsers")
```

### Clear All
```swift
try keychain.clearAll()
```

## Error Handling

### KeychainError Enum
```swift
enum KeychainError: Error, LocalizedError {
    case saveFailed(OSStatus)
    case loadFailed(OSStatus)
    case deleteFailed(OSStatus)
    case itemNotFound
    case invalidData
}
```

### Example
```swift
do {
    let users = try keychain.load(for: "users", as: [User].self)
} catch KeychainManager.KeychainError.itemNotFound {
    // First time, no data yet
} catch {
    logger.error("Keychain error: \(error)")
}
```

## Security

### Access Control
- kSecAttrAccessibleAfterFirstUnlock
- Data accessible after device first unlock
- Protected when device locked

### Encryption
- AES-256 encryption by iOS
- Hardware-backed on devices with Secure Enclave
- Data never stored in plaintext

## Migration

### Auto-Migration from UserDefaults
```swift
private func migrateFromUserDefaults() async throws -> [FavoriteUser] {
    guard let data = UserDefaults.standard.data(forKey: key),
          let users = try? JSONDecoder().decode([FavoriteUser].self, from: data) else {
        return []
    }

    try keychain.save(users, for: key)
    UserDefaults.standard.removeObject(forKey: key)

    return users
}
```

## Current Usage

### FavoritesRepository
Uses Keychain for storing:
- Favorite users
- Favorite repositories

Location: `Modules/Data/Repository/FavoritesRepository.swift`

```swift
class KeychainFavoritesRepository: FavoritesRepository {
    private let keychain = KeychainManager()

    func saveFavoriteUser(_ user: FavoriteUser) async throws {
        var users = try await getFavoriteUsers()
        users.append(user)
        try keychain.save(users, for: "favoriteUsers")
    }
}
```

## Best Practices
- Always use type-safe save/load with Codable
- Handle KeychainError.itemNotFound for first-time access
- Use privacy-aware logging
- Never log sensitive data
- Clear keychain on logout if needed

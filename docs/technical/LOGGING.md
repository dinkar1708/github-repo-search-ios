# Logging System

## Overview
Structured logging with OSLog and type-safe categories.

## Implementation

Location: `Modules/Core/Logging/Logger+Extensions.swift`

### LogCategory Enum
Type-safe logging categories prevent typos.

```swift
enum LogCategory: String, CaseIterable {
    case networking
    case viewModel
    case cache
    case favorites
    case analytics
    case ui
    case app
    case storage
    case repository
}
```

### Logger Extension
```swift
extension Logger {
    static func make(category: LogCategory) -> Logger {
        Logger(subsystem: subsystem, category: category.rawValue)
    }

    static let networking = Logger.make(category: .networking)
    static let viewModel = Logger.make(category: .viewModel)
    static let cache = Logger.make(category: .cache)
    // ... more loggers
}
```

## Usage

### In Code
```swift
private let logger = Logger.viewModel

func searchUsers() {
    logger.info("Starting user search")
    logger.debug("Query: \(query)")
    logger.error("Failed to load: \(error)")
}
```

### Privacy Levels
```swift
// Public (visible in logs)
logger.info("Search query: '\(query, privacy: .public)'")

// Private (redacted in logs)
logger.debug("User ID: \(userID, privacy: .private)")

// Sensitive (always redacted)
logger.info("API Key: \(apiKey, privacy: .sensitive)")
```

## Log Levels

### Info
General information about app flow.
```swift
logger.info("User logged in")
```

### Debug
Detailed debugging information.
```swift
logger.debug("Cache hit for key: \(key)")
```

### Error
Error conditions.
```swift
logger.error("Failed to save: \(error)")
```

### Fault
Critical failures.
```swift
logger.fault("Database corruption detected")
```

## Categories

### networking
API calls, network requests, responses.

Usage: `Logger.networking`

### viewModel
ViewModel logic, state changes.

Usage: `Logger.viewModel`

### cache
Cache operations, hits, misses.

Usage: `Logger.cache`

### favorites
Favorites operations.

Usage: `Logger.favorites`

### analytics
Analytics event tracking.

Usage: `Logger.analytics`

### ui
UI interactions, navigation.

Usage: `Logger.ui`

### app
App lifecycle events.

Usage: `Logger.app`

### storage
Keychain, storage operations.

Usage: `Logger.storage`

### repository
Repository layer operations.

Usage: `Logger.repository`

## Viewing Logs

### Console.app
1. Open Console.app
2. Filter by subsystem: your bundle ID
3. Filter by category: networking, viewModel, etc.

### Xcode Debug Console
Logs appear in Xcode console during debugging.

### OSLog Store
Logs persisted by system for later analysis.

## Best Practices
- Use type-safe categories
- Apply privacy levels appropriately
- Never log sensitive data as .public
- Use .private for user data
- Use .sensitive for credentials
- Keep log messages concise
- Include relevant context

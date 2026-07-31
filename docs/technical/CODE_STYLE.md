# Code Style Guide

## Overview
Swift coding standards and linting configuration for consistent code quality.

## SwiftLint (Optional)

**Status:** Configured but not required. SwiftLint is optional for development.

### Configuration File
`.swiftlint.yml` in project root defines all linting rules.

### Installation

**Using Homebrew:**
```bash
brew install swiftlint
```

**Using Mint:**
```bash
mint install realm/SwiftLint
```

### Running SwiftLint

**Lint entire project:**
```bash
swiftlint lint
```

**Auto-fix issues:**
```bash
swiftlint --fix
```

**Lint specific file:**
```bash
swiftlint lint --path github_repo_search_iOS_app/
```

### Xcode Integration

SwiftLint can run automatically on build. Add Run Script Phase:

1. Xcode → Target → Build Phases
2. Click + → New Run Script Phase
3. Add script:
```bash
if which swiftlint >/dev/null; then
  swiftlint
else
  echo "warning: SwiftLint not installed"
fi
```

## Current Rules

### Disabled Rules
These rules are too strict for the codebase:
- trailing_whitespace
- todo
- function_body_length
- type_body_length
- file_length

### Opt-in Rules
Additional quality checks enabled:
- force_unwrapping
- explicit_type_interface
- discouraged_optional_boolean
- discouraged_optional_collection
- empty_count
- explicit_init
- fatal_error_message
- first_where
- implicitly_unwrapped_optional
- multiline_parameters
- redundant_nil_coalescing

### Line Length
- Warning: 120 characters
- Error: 150 characters
- Ignores function declarations, comments, URLs

### Custom Rules

**No Print Statements**
- Use Logger instead of print()
- Severity: Warning

**No Force Cast**
- Avoid `as!` and `as?!`
- Use optional binding or guard
- Severity: Warning

**TODO/FIXME Requires Ticket**
- Format: `TODO[TICKET-123]`
- Ensures all TODOs tracked
- Severity: Warning

## Code Formatting

### Swift Format

**Installation:**
```bash
brew install swift-format
```

**Format file:**
```bash
swift-format format --in-place <file>
```

**Format entire project:**
```bash
find github_repo_search_iOS_app -name "*.swift" -exec swift-format format --in-place {} \;
```

### Configuration
Create `.swift-format` file for custom formatting rules.

## Naming Conventions

### Types
- PascalCase for classes, structs, enums, protocols
- Examples: `HomeViewModel`, `GithubRepository`, `NetworkError`

### Variables and Functions
- camelCase for properties and methods
- Examples: `searchText`, `performSearch()`, `isLoading`

### Constants
- camelCase for constants
- Examples: `maxRetryCount`, `defaultTimeout`

### Enums
- PascalCase for enum names
- camelCase for cases
- Examples: `LogCategory.networking`, `AnalyticsEvent.searchPerformed`

## File Organization

### Import Order
1. System frameworks (UIKit, SwiftUI)
2. Third-party frameworks
3. Internal modules

### Code Structure
1. Type definition
2. Properties
3. Initializers
4. Public methods
5. Private methods
6. Extensions

## Best Practices

### Avoid Force Unwrapping
```swift
// Bad
let value = optional!

// Good
guard let value = optional else { return }
```

### Use Guard for Early Returns
```swift
// Good
guard let data = fetchData() else {
    return
}
processData(data)
```

### Prefer Let Over Var
```swift
// Bad
var name = "John"

// Good (if value doesn't change)
let name = "John"
```

### Explicit Types When Needed
```swift
// Good when type not obvious
let repository: GithubRepository = GithubRepositoryImpl()
```

### Use Type Inference
```swift
// Good when type obvious
let count = items.count
let name = "GitHub"
```

## Documentation

### Public APIs
Document public methods and types:
```swift
/// Searches for GitHub repositories.
/// - Parameters:
///   - query: Search query string
///   - page: Page number for pagination
/// - Returns: SearchItemResponse with results
func searchRepositories(query: String, page: Int) async throws -> SearchItemResponse
```

### Complex Logic
Add comments for non-obvious code:
```swift
// Debounce search to avoid excessive API calls
searchTask?.cancel()
```

## SwiftUI Conventions

### View Naming
- Suffix views with `View`
- Examples: `HomeView`, `SearchItemCell`, `ErrorView`

### ViewModel Naming
- Suffix with `ViewModel`
- Examples: `HomeViewModel`, `UserSearchViewModel`

### Property Wrappers
- `@State` for view-local state
- `@Observable` for ViewModels
- `@Injected` for dependencies
- `@ObservationIgnored` with `@Injected`

## Testing Conventions

### Test Naming
- Prefix with `test`
- Descriptive names
- Examples: `testSearchReturnsResults()`, `testErrorHandling()`

### Test Organization
- Arrange-Act-Assert pattern
- One assertion per test (when possible)
- Clear test names

## CI/CD Integration

### GitHub Actions

Add SwiftLint check to CI:
```yaml
- name: SwiftLint
  run: |
    brew install swiftlint
    swiftlint lint --strict
```

## File References

- Configuration: `.swiftlint.yml`
- Documentation: This file
- Swift Style Guide: [Swift.org API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)

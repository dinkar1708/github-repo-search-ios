# iOS Development References & Best Practices

This document contains curated links to official Apple documentation and industry-standard best practices for iOS development.

## This Project's Tech Stack

### Architecture & Patterns
- **Architecture**: MVVM (Model-View-ViewModel) with Repository pattern
- **UI Framework**: SwiftUI with modern `@Observable` macro (iOS 17+)
- **Dependency Injection**: Property wrapper-based DI (`@Injected`) with DependencyContainer
- **State Management**: `@State` and `@Observable` (not `ObservableObject`)
- **Concurrency**: Swift async/await with `@MainActor`
- **Data Flow**: View → ViewModel → Repository → API Client
- **Persistence**: SwiftData (4 normalized relational tables) + Keychain for secure secrets
- **Background Scheduling**: `BGTaskScheduler` (`BGAppRefreshTask`) for opportunistic cloud sync
- **Testing**: Dual-Framework (**Apple Swift Testing** `@Test` + **Classic XCTest**)
- **Logging**: OSLog with type-safe categories via `LogCategory` enum
- **Caching**: Multi-layer NSCache with TTL support
- **Analytics**: Event-based tracking abstraction layer

### Key Design Decisions
- ✅ Modern Swift patterns (Observable macro, async/await, `@ModelActor`)
- ✅ Dual-Framework Testing (Apple Swift Testing + XCTest)
- ✅ Background Sync Scheduling via Apple's native `BGTaskScheduler`
- ✅ Relational offline persistence with SwiftData & in-memory test isolation
- ✅ Custom DI framework with @Injected property wrapper (zero boilerplate)
- ✅ Protocol-based repository layer for testability
- ✅ Sendable conformance for thread safety
- ✅ Keychain encryption for sensitive data (AES-256)
- ✅ Structured logging with OSLog categories
- ✅ Type-safe enums for logger categories and analytics events
- ✅ Shared singleton for favorites management

---

## Official Apple Documentation

### Design Guidelines
- **[Apple Human Interface Guidelines (HIG)](https://developer.apple.com/design/human-interface-guidelines/ios)** - Official design principles for iOS apps covering clarity, deference, and depth
- **[iOS Design Resources](https://developer.apple.com/design/resources/)** - UI kits, templates, and design assets from Apple

### Swift Language
- **[Swift API Design Guidelines](https://www.swift.org/documentation/api-design-guidelines/)** - Official guidelines for writing Swift code and APIs
- **[Swift Documentation](https://www.swift.org/documentation/)** - Complete Swift language reference
- **[Swift Evolution Proposals](https://github.com/swiftlang/swift-evolution)** - Track Swift language changes and proposals

### Development Resources
- **[Apple Developer Documentation](https://developer.apple.com/documentation/)** - Complete iOS SDK documentation
- **[WWDC Videos](https://developer.apple.com/videos/)** - Annual developer conference sessions
- **[iOS App Dev Tutorials](https://developer.apple.com/tutorials/app-dev-training)** - Official hands-on iOS development tutorials
- **[SwiftUI Tutorials](https://developer.apple.com/tutorials/swiftui)** - Official SwiftUI learning path
- **[App Store Connect](https://developer.apple.com/app-store-connect/)** - Manage your apps on the App Store
- **[TestFlight](https://developer.apple.com/testflight/)** - Beta testing platform for iOS apps
- **[Xcode Documentation](https://developer.apple.com/documentation/xcode)** - Official Xcode IDE documentation
- **[Sample Code](https://developer.apple.com/sample-code/)** - Apple's official sample projects

## Architecture Patterns

### MVVM (Model-View-ViewModel) ✅ **Used in This Project**
- **Use Cases**: Small to medium-sized apps, SwiftUI projects
- **Benefits**: Clear separation of concerns, excellent testability, reactive data binding
- **This Project's Implementation**:
  - **Modern Swift Approach**: Using `@Observable` macro (iOS 17+) instead of legacy `ObservableObject`
  - **State Management**: `@State` for View ownership of ViewModel
  - **Concurrency**: Swift async/await with `@MainActor` for UI updates
  - **Pattern**: View → ViewModel → Repository → API
  - **Example**: `HomeView` → `HomeViewModel` → `DefaultGithubRepository` → `GithubAPI`
  - **Key Files**:
    - ViewModels: `HomeViewModel.swift:17`, `UserProfileViewModel.swift:13`
    - Views: `HomeView.swift:14` (uses `@State private var homeViewModel`)
    - Repository: `GithubRepository.swift:15` (protocol-based design)
- **Key Resources**:
  - [Apple Observable Macro](https://developer.apple.com/documentation/observation/observable()) - Modern state management
  - [Building Scalable MVVM Architecture in iOS](https://medium.com/@maneetsrivastav/building-a-scalable-mvvm-architecture-in-ios-with-dependency-injection-and-clean-oop-3a87d1c919d4)
  - [Modern iOS Architecture Patterns](https://medium.com/@sharmapraveen91/modern-ios-architecture-patterns-and-best-practices-5320e2d9d1aa)

### Clean Architecture
- **Use Cases**: Large-scale enterprise apps, complex business logic
- **Benefits**: High modularity, maintainability, and testability
- **Key Principles**: Separation of concerns, dependency inversion, domain-driven design
- **Resources**:
  - [Clean Architecture iOS Guide](https://www.cmarix.com/blog/clean-architecture-ios/)
  - [The Ultimate Guide to Modern iOS Architecture in 2025](https://medium.com/@csmax/the-ultimate-guide-to-modern-ios-architecture-in-2025-9f0d5fdc892f)

### TCA (The Composable Architecture)
- **Use Cases**: State-heavy applications, complex app flows
- **Benefits**: Predictable state management, excellent testing support

## Swift Coding Standards

### Official Guidelines
- **[Swift API Design Guidelines](https://www.swift.org/documentation/api-design-guidelines/)** - Naming conventions, idioms, and best practices
- **[Swift Style Guide by Google](https://google.github.io/swift/)** - Industry-standard style guide based on Apple's guidelines
- **[LinkedIn Swift Style Guide](https://github.com/linkedin/swift-style-guide)** - Enterprise-grade coding standards

### Key Principles
- Clarity at the point of use is the most important goal
- Write documentation comments for every public declaration
- Prefer clarity over brevity
- Use descriptive names that make code self-documenting
- Follow Swift naming conventions (camelCase, PascalCase)

## Testing Best Practices

### 🍏 Modern Swift Testing (iOS 17+ / Swift 6)
- **[Swift Testing Framework - Apple](https://developer.apple.com/documentation/testing)** — Official Swift Testing documentation covering `@Suite`, `@Test`, `#expect`, `#require`, and tags.
- **[Migrating a Test from XCTest to Swift Testing](https://developer.apple.com/documentation/testing/migratingfromxctest)** — Official Apple migration guide from `XCTestCase` to `@Test`.
- **[Parameterized Testing with Argument Matrices](https://developer.apple.com/documentation/testing/parameterizedtesting)** — Running datasets concurrently via `@Test(arguments: [...])`.
- **[WWDC 2024: Meet Swift Testing (Session 10179)](https://developer.apple.com/videos/play/wwdc2024/10179/)** — WWDC introductory session on architecture and Xcode integration.
- **[WWDC 2024: Go Further with Swift Testing (Session 10195)](https://developer.apple.com/videos/play/wwdc2024/10195/)** — Advanced session on traits, tags, and parallel actor isolation.
- **[Swift Testing GitHub Repository (`swiftlang/swift-testing`)](https://github.com/swiftlang/swift-testing)** — Official open-source package repository.

### 🏛️ Classic XCTest & UI Automation
- **[XCTest Framework - Apple](https://developer.apple.com/documentation/xctest)** — Official XCTest documentation for UI Automation (`XCUIApplication`) and Performance Metrics.
- **[Testing Your Apps in Xcode](https://developer.apple.com/documentation/xcode/testing-your-apps-in-xcode)** — Official testing workflow guide.
- **[XCTest Best Practices](https://maestro.dev/insights/xctest-best-practices-ios-testing)** — Comprehensive testing guide.

### Testing Guidelines
- **Modern Unit & Persistence Tests:** Write with **Swift Testing** using `@Test`, `#expect`, and `@Test(arguments: ...)` matrices.
- **UI & Performance Tests:** Maintain with **XCTest** using `XCUIApplication` and `measure(metrics: ...)`.
- Write single-assertion tests for clarity.
- Use descriptive test names in `@Test("...")`.
- Mock dependencies for stable, repeatable tests.
- Aim for high code coverage using Xcode's coverage visualization.

### Testing Benefits
- Catch bugs early in development
- Reduce debugging time by up to 40%
- Maintain confidence as codebase grows
- Enable safe refactoring

## Security Best Practices

### Keychain & Data Protection
- **[iOS App Security Checklist 2025](https://mobisoftinfotech.com/resources/blog/app-security/ios-app-security-checklist-best-practices)** - Comprehensive security guide
- **[Securing iOS Apps End-to-End](https://ravi6997.medium.com/securing-ios-apps-end-to-end-from-local-storage-to-backend-7d110171c196)** - Keychain, SSL pinning, OAuth2 & JWT
- **[Keychain Best Practices](https://medium.com/@ios-interview/keychain-best-practices-for-storing-sensitive-data-ios-development-a27d2d3ed34b)** - Storing sensitive data securely

### Security Guidelines
- **Always use Keychain** for storing:
  - Passwords and tokens
  - API keys and secrets
  - Cryptographic keys
  - Authentication credentials
- **Never store sensitive data in**:
  - UserDefaults (not encrypted)
  - Plain files (SQLite, JSON, plist)
  - App code or hardcoded strings
- Use appropriate Keychain accessibility constants:
  - `kSecAttrAccessibleWhenUnlocked` - Most secure, data only accessible when device is unlocked
  - `kSecAttrAccessibleAfterFirstUnlock` - Balance of security and usability
- Implement Face ID/Touch ID using LocalAuthentication framework
- Use File Protection APIs (`NSFileProtectionComplete`) for sensitive files
- Implement key rotation policies for long-term security
- Enable App Transport Security (ATS) for network communications
- Use SSL/TLS pinning for critical API endpoints

## Privacy & Compliance

### App Privacy Requirements (2025)
- Declare data collection in App Privacy Manifest
- Request permissions only when necessary
- Provide clear privacy explanations
- Follow App Tracking Transparency (ATT) guidelines
- Implement data minimization principles

## UI/UX Design Principles

### Core Design Principles
1. **Clarity**: Clean, uncluttered UI with clear instructions and recognizable icons
2. **Deference**: Minimize distractions, let content take center stage
3. **Depth**: Use layering, shadows, and visual effects to create hierarchy

### Key Guidelines
- Follow platform conventions for familiar user experience
- Design for all screen sizes (iPhone, iPad)
- Support both orientations (portrait, landscape)
- Implement Dynamic Type for accessibility
- Support VoiceOver and assistive technologies
- Use SF Symbols for consistent iconography
- Follow iOS navigation patterns (tab bars, navigation bars)

## Modern Development Stack (2025)

### Languages & Frameworks
- **Swift**: Type-safe, expressive, with improved concurrency support (async/await)
  - [Swift.org](https://www.swift.org/) - Official Swift language website
  - [Swift Concurrency](https://developer.apple.com/documentation/swift/concurrency) - Official async/await documentation
- **SwiftUI**: Declarative UI programming, better widget integration
  - [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui) - Official SwiftUI framework
  - [SwiftUI Tutorials](https://developer.apple.com/tutorials/swiftui) - Official learning path
- **SwiftData**: Modern replacement for CoreData
  - [SwiftData Documentation](https://developer.apple.com/documentation/swiftdata) - Official SwiftData framework
- **Combine**: Reactive programming framework
  - [Combine Documentation](https://developer.apple.com/documentation/combine) - Official reactive framework
- **UIKit**: Traditional imperative UI framework
  - [UIKit Documentation](https://developer.apple.com/documentation/uikit) - Official UIKit framework

### Recommended Tools
- **Xcode**: Primary IDE with excellent debugging and profiling tools
- **Swift Package Manager**: Dependency management
- **Fastlane**: Automate builds and releases
- **XCTest**: Unit and UI testing framework

## Accessibility

### Requirements
- Support VoiceOver with proper accessibility labels
- Implement Dynamic Type for scalable text
- Provide sufficient color contrast (WCAG guidelines)
- Support reduced motion preferences
- Test with assistive technologies
- Design for inclusivity across all user demographics

## Dependency Injection

### What This Project Uses
**Constructor-Based Dependency Injection** - Manual initialization through Swift initializers
- **Implementation**: Dependencies passed through `init()` parameters
- **Example**: `UserProfileViewModel(repository: GithubRepository = DefaultGithubRepository())`
- **Benefits**: Simple, no external frameworks, testable with protocol-based architecture
- **Pattern**: Protocol-oriented design with default implementations

### Alternative DI Approaches (Not Used in This Project)
- **Swinject** - Popular third-party DI container framework
- **Needle** - Uber's compile-time safe DI framework
- **@EnvironmentObject** - SwiftUI's built-in DI for shared state
- **Factory** - Lightweight service locator pattern

### Modern Requirement
- Dependency Injection has become a fundamental requirement (not just best practice)
- Enables better testability and modularity
- Reduces coupling between components
- Facilitates easier mocking in tests

## Performance Optimization

### Best Practices
- Optimize image loading and caching
- Implement lazy loading for large datasets
- Use instruments for profiling (Time Profiler, Allocations)
- Monitor memory usage and prevent leaks
- Implement efficient list rendering with UITableView/UICollectionView or SwiftUI List
- Use background threads for heavy operations
- Optimize app launch time

## Version Control & Collaboration

### Git Best Practices
- Write clear, descriptive commit messages
- Use feature branches for new development
- Keep commits small and focused
- Review code before merging
- Use pull requests for team collaboration

## Continuous Integration/Continuous Deployment

### CI/CD Best Practices
- Automate testing in CI pipeline
- Run tests on multiple device configurations
- Automate build and deployment processes
- Use TestFlight for beta distribution
- Monitor crash reports and analytics

## Additional Resources

### Community Style Guides
- [Google Swift Style Guide](https://google.github.io/swift/)
- [LinkedIn Swift Style Guide](https://github.com/linkedin/swift-style-guide)
- [Airbnb Swift Style Guide](https://github.com/airbnb/swift)

### Learning Platforms
- [Apple Developer Tutorials](https://developer.apple.com/tutorials/)
- [WWDC Session Videos](https://developer.apple.com/videos/)
- [Swift by Sundell](https://www.swiftbysundell.com/)
- [Hacking with Swift](https://www.hackingwithswift.com/)
- [Kodeco (formerly RayWenderlich)](https://www.kodeco.com/ios) - Comprehensive iOS tutorials and courses
- [Medium iOS Development](https://medium.com/tag/ios-development) - iOS development articles and best practices
- [iOS Dev Weekly](https://iosdevweekly.com/) - Curated newsletter of iOS development articles

### Staying Updated
- Follow [Swift.org Blog](https://www.swift.org/blog/)
- Subscribe to [iOS Dev Weekly](https://iosdevweekly.com/)
- Attend WWDC annually
- Participate in [Swift Forums](https://forums.swift.org/)
- Join [Apple Developer Forums](https://developer.apple.com/forums/)

### Popular iOS Development Blogs
- [NSHipster](https://nshipster.com/) - Deep dives into Swift and Cocoa
- [Swift by Sundell](https://www.swiftbysundell.com/) - Weekly Swift articles and podcasts
- [Paul Hudson - Hacking with Swift](https://www.hackingwithswift.com/) - Free Swift tutorials
- [objc.io](https://www.objc.io/) - Advanced iOS development topics
- [Use Your Loaf](https://useyourloaf.com/) - iOS development tips and guides
- [Antoine van der Lee](https://www.avanderlee.com/) - Swift and iOS development blog
- [Donny Wals](https://www.donnywals.com/) - Practical iOS development tutorials
- [SwiftLee](https://www.avanderlee.com/) - Weekly Swift articles
- [iOS Development on Medium](https://medium.com/tag/ios-app-development) - Community articles

---

## Quick Reference Checklist

### Before Starting a New Feature
- [ ] Choose appropriate architecture pattern (MVVM, Clean Architecture)
- [ ] Plan dependency injection strategy
- [ ] Consider testability from the start
- [ ] Review HIG for design patterns

### During Development
- [ ] Follow Swift API Design Guidelines
- [ ] Write unit tests alongside code
- [ ] Use Keychain for sensitive data
- [ ] Implement proper error handling
- [ ] Add accessibility support
- [ ] Document public APIs

### Before Release
- [ ] Run full test suite
- [ ] Check code coverage
- [ ] Review security checklist
- [ ] Test on multiple devices
- [ ] Verify privacy manifest
- [ ] Test with VoiceOver
- [ ] Profile for performance issues
- [ ] Review App Store guidelines

---

*Last Updated: July 2026*
*This document should be reviewed and updated regularly to reflect the latest iOS development standards and best practices.*

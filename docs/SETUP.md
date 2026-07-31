# Setup Guide

## Prerequisites

- **Xcode**: 15.0 or later
- **iOS Target**: 17.0+
- **macOS**: 13.0+ (for development)
- **Ruby**: 3.2+ (for Fastlane)
- **Git**: For version control

## Quick Start

### 1. Clone the Repository

```bash
git clone <repository-url>
cd github_repo_search_iOS_app
```

### 2. Open Project

```bash
open github_repo_search_iOS_app.xcodeproj
```

### 3. Build and Run

1. Select target: `github_repo_search_iOS_app`
2. Select simulator: iPhone 15 (iOS 17.0+)
3. Press `Cmd + R` to build and run

## Optional: CocoaPods Setup

If you plan to add CocoaPods dependencies:

```bash
# Install CocoaPods (if not installed)
sudo gem install cocoapods

# Install dependencies
pod install

# Open workspace instead of project
open github_repo_search_iOS_app.xcworkspace
```

**Note**: Currently, no pods are active. Uncomment desired dependencies in `Podfile`.

## Development Tools Setup

### SwiftLint

Install SwiftLint for code quality checks:

```bash
brew install swiftlint
```

SwiftLint runs automatically during Xcode build. Configuration: `.swiftlint.yml`

### Fastlane

Install Fastlane for automation:

```bash
# Install Ruby (if needed)
brew install ruby

# Install Fastlane
gem install fastlane

# Verify installation
fastlane --version
```

#### Fastlane Commands

```bash
# Run tests
fastlane test

# Run SwiftLint
fastlane lint

# Build for simulator
fastlane build

# Deploy to TestFlight (requires Apple Developer account)
fastlane beta

# Deploy to App Store (requires Apple Developer account)
fastlane release
```

## GitHub Actions CI/CD

CI/CD runs automatically on:
- Push to `release` or `develop` branches
- Pull requests to `release` or `develop` branches

### Required Secrets (for deployment)

Add these secrets in GitHub repository settings:

```
FASTLANE_APPLE_ID          # Apple Developer email
FASTLANE_PASSWORD          # Apple Developer password
FASTLANE_ITC_TEAM_ID       # App Store Connect Team ID
FASTLANE_TEAM_ID           # Developer Portal Team ID
MATCH_PASSWORD             # Match certificate password
MATCH_GIT_BASIC_AUTHORIZATION  # Match repo credentials
```

## Running Tests

### Via Xcode

1. Press `Cmd + U` to run all tests
2. Or use Test Navigator (Cmd + 6) to run specific tests

### Via Command Line

```bash
# Run all tests
xcodebuild test \
  -scheme github_repo_search_iOS_app \
  -destination 'platform=iOS Simulator,name=iPhone 15'

# Run tests with Fastlane
fastlane test
```

### Test Locations

- **Unit Tests**: `github_repo_search_iOS_app_UnitTests/`
- **Integration Tests**: `github_repo_search_iOS_app_IntegrationTests/`
- **UI Tests**: `github_repo_search_iOS_app_UITests/`

## Project Configuration

### Build Settings

- **iOS Deployment Target**: 17.0
- **Swift Version**: 5.0
- **Architectures**: arm64, x86_64 (simulator)

### Info.plist

Located at: `github_repo_search_iOS_app/AppConfig/Info.plist`

Key configurations:
- Bundle Identifier: `dinakar.app.github-repo-search-iOS-app`
- Version: 1.0
- Build: 1

### Privacy Manifest

Required for App Store submission (2024+):

Location: `github_repo_search_iOS_app/PrivacyInfo.xcprivacy`

## Troubleshooting

### Build Failures

**Issue**: Xcode can't find simulator
```bash
# List available simulators
xcrun simctl list devices

# Use specific simulator ID in build command
xcodebuild -destination 'id=<SIMULATOR_ID>'
```

**Issue**: SwiftLint warnings as errors
```bash
# Temporarily disable strict mode
swiftlint lint --lenient
```

### Fastlane Issues

**Issue**: Fastlane not found
```bash
# Add to PATH
echo 'export PATH="$HOME/.gem/ruby/3.2.0/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

**Issue**: Certificate/provisioning profile errors
```bash
# Clear derived data
rm -rf ~/Library/Developer/Xcode/DerivedData

# Update certificates
fastlane match development --readonly
```

### CocoaPods Issues

**Issue**: Pod install fails
```bash
# Update CocoaPods
gem update cocoapods

# Clean install
rm -rf Pods/ Podfile.lock
pod install --repo-update
```

## IDE Recommendations

### Xcode Extensions
- **SwiftFormat**: Code formatting
- **Periphery**: Dead code detection

### Xcode Settings
- **Editor > Code Formatting**: Enable "Trim Trailing Whitespace"
- **Text Editing**: Enable line numbers, code folding
- **Behaviors**: Configure build/test behaviors

## API Configuration

### GitHub API

No API key required for basic usage (60 requests/hour).

For authenticated requests:
1. Generate personal access token at https://github.com/settings/tokens
2. Add to `GithubAPI.swift` (not implemented yet)

**Rate Limits**:
- Unauthenticated: 60 requests/hour
- Authenticated: 5000 requests/hour

## Next Steps

1. Review [ARCHITECTURE.md](ARCHITECTURE.md) for project structure
2. Check [TESTING.md](TESTING.md) for testing guidelines
3. See [FEATURES.md](FEATURES.md) for feature documentation
4. Read [CHANGELOG.md](CHANGELOG.md) for recent changes

## Support

For issues and questions:
- Check existing issues in GitHub
- Review documentation in `docs/` folder
- Check SwiftLint output for code quality issues

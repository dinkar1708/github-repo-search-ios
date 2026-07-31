# Quick Start Guide

## Prerequisites
- macOS 14.0 or later
- Xcode 15.0 or later
- iOS 17.0+ device or simulator

## Setup Steps

### 1. Clone Repository
```bash
git clone https://github.com/dinkar1708/github_repo_search_iOS_app.git
cd github_repo_search_iOS_app
```

### 2. Open Project
```bash
open github_repo_search_iOS_app.xcodeproj
```

### 3. Select Target
- Click on the scheme selector (top-left)
- Choose "github_repo_search_iOS_app"
- Select a simulator or device

### 4. Build and Run
- Press Cmd + R or click the Play button
- App will launch on selected device/simulator

## First Run

### App opens to Repository Search
- Type a search query to find repositories
- Results appear with debouncing (3 seconds)
- Tap any repository for details

### Navigate via Tabs
- **Users**: Search GitHub users
- **Repositories**: Search repositories
- **Favorites**: View saved items
- **Settings**: Configure app preferences

## Features to Try

### Search
- Repository search with auto-complete
- User search with profile viewing
- Incremental loading with pagination

### Favorites
- Tap star icon to save repositories
- Tap star icon on profiles to save users
- View all favorites in Favorites tab
- Securely stored in Keychain

### Settings
- Toggle dark mode
- Change language (English/Japanese)
- Clear cache
- View app information

## Build Status
Current: BUILD SUCCEEDED

## Troubleshooting

### Build Fails
```bash
# Clean build folder
Cmd + Shift + K

# Or use command line
xcodebuild clean
```

### Simulator Issues
- Restart simulator
- Try different simulator version
- Check Xcode > Preferences > Locations

### Dependencies
No external dependencies required. Project is 100% native iOS.

## Next Steps
- Read [Architecture](../ARCHITECTURE.md) for system design
- See [Features](../FEATURES.md) for complete feature list
- Check [Testing Guide](../TESTING.md) for test information

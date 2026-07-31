# User Flows

## Overview
Complete user interaction flows for all app features.

## Tab Navigation

### Main Tabs
The app has 4 primary tabs:

1. Users - Search GitHub users
2. Repositories - Search GitHub repositories
3. Favorites - View saved items
4. Settings - Configure app preferences

Users can switch between tabs at any time.

## Flow 1: Search Repositories

### Steps
1. User opens app (defaults to Repositories tab)
2. User sees search bar at top
3. User types search query (e.g., "swift")
4. System waits 3 seconds after last keystroke (debouncing)
5. System shows loading indicator
6. System fetches results from GitHub API
7. System displays repository cards with:
   - Repository name
   - Owner avatar and name
   - Description
   - Star count
   - Fork count
   - Primary language
8. User scrolls to see more results
9. System loads next page when scrolling near bottom
10. User taps on repository card
11. System navigates to repository details

### Repository Details Screen
Shows:
- Full repository name
- Owner information
- Complete description
- Statistics (stars, forks, watchers, issues)
- Dates (created, updated)
- Primary language
- License information
- README preview
- Link to open in browser
- Favorite button (star icon)

### Actions
- Tap favorite button to save repository
- Tap "Open in Browser" to view on GitHub
- Tap back button to return to search results

## Flow 2: Search Users

### Steps
1. User taps Users tab
2. User sees search bar at top
3. User types username (e.g., "torvalds")
4. System waits 800ms after last keystroke (debouncing)
5. System shows loading indicator
6. System fetches results from GitHub API
7. System displays user cards with:
   - Avatar image
   - Username
   - Link to profile
8. User scrolls to see more results
9. System loads next page automatically
10. User taps on user card
11. System navigates to user profile

### User Profile Screen
Shows:
- Large avatar
- Full name
- Username
- Bio
- Location
- Email (if public)
- Statistics:
  - Public repositories
  - Followers
  - Following
  - Public gists
- Join date
- List of user's repositories
- Favorite button (star icon)

### Repository List on Profile
Each repository shows:
- Name
- Description
- Star count
- Fork count
- Primary language

User can:
- Tap repository to view details
- Scroll to load more repositories
- Tap favorite button to save user

## Flow 3: Manage Favorites

### View Favorites
1. User taps Favorites tab
2. System shows segmented control:
   - Users
   - Repositories
3. Default view shows Users
4. System loads favorites from Keychain
5. System displays saved items

### User Favorites View
Shows saved users with:
- Avatar
- Username
- Tap to view profile

### Repository Favorites View
Shows saved repositories with:
- Repository name
- Owner
- Description
- Statistics
- Tap to view details

### Add Favorite

**From Repository Details**:
1. User views repository details
2. User taps star icon (empty star)
3. System saves to Keychain
4. Star icon fills (solid star)
5. System tracks analytics event
6. Success confirmation (visual feedback)

**From User Profile**:
1. User views user profile
2. User taps star icon (empty star)
3. System saves to Keychain
4. Star icon fills (solid star)
5. System tracks analytics event
6. Success confirmation (visual feedback)

### Remove Favorite

**From Details/Profile Screen**:
1. User taps filled star icon
2. System removes from Keychain
3. Star icon becomes empty
4. System tracks analytics event

**From Favorites List**:
1. User swipes left on favorite item
2. Delete button appears
3. User taps delete
4. System removes from Keychain
5. Item disappears from list
6. System tracks analytics event

### Switch Between Users and Repositories
1. User taps segmented control
2. System switches view instantly
3. No loading required (data cached)

## Flow 4: Configure Settings

### View Settings
1. User taps Settings tab
2. System shows settings options:
   - Dark Mode toggle
   - Language selection
   - Clear Cache button
   - App Information

### Toggle Dark Mode
1. User taps Dark Mode toggle
2. System applies theme immediately
3. All screens update in real-time
4. System saves preference to UserDefaults
5. System tracks analytics event

### Change Language
1. User taps Language row
2. System shows language picker:
   - English
   - Japanese
3. User selects language
4. System updates all text immediately
5. System saves preference to UserDefaults
6. System tracks analytics event

### Clear Cache
1. User taps "Clear Cache" button
2. System shows confirmation alert
3. User confirms action
4. System clears all cached API responses
5. System shows success message
6. System tracks analytics event

### View App Information
Displays:
- App version
- Build number
- GitHub repository link
- Developer information

## Flow 5: Pull to Refresh

### Repositories Tab
1. User pulls down on list
2. System shows refresh indicator
3. System clears cache for current query
4. System fetches fresh data from API
5. System updates list
6. Refresh indicator disappears

### Users Tab
Same flow as Repositories tab

### Favorites Tab
1. User pulls down on list
2. System shows refresh indicator
3. System reloads data from Keychain
4. System updates list
5. Refresh indicator disappears

## Flow 6: Pagination

### Infinite Scroll
1. User scrolls to near bottom of list
2. System detects scroll position
3. System checks if more pages available
4. System shows loading indicator at bottom
5. System fetches next page from API
6. System appends results to existing list
7. Loading indicator disappears
8. User continues scrolling

### Page Tracking
- Current page tracked in ViewModel
- Page increments with each load
- System prevents duplicate page requests
- System handles end of results gracefully

## Flow 7: Error Handling

### Network Error
1. API call fails (no internet, timeout)
2. System catches error
3. System logs error with context
4. System tracks analytics event
5. System shows error message to user
6. System displays retry button
7. User taps retry
8. System attempts request again

### No Results
1. Search returns zero results
2. System displays "No results found" message
3. System suggests:
   - Check spelling
   - Try different keywords
   - Broaden search terms

### Rate Limit Exceeded
1. API returns 429 status
2. System shows rate limit message
3. System suggests waiting
4. System displays time until reset

## Flow 8: Empty States

### First Launch - Repositories
1. App opens for first time
2. Search bar is empty
3. System shows welcome message:
   - "Search for repositories"
   - Example queries
   - Tips for better results

### First Launch - Users
1. User taps Users tab
2. Search bar is empty
3. System shows welcome message:
   - "Search for GitHub users"
   - Example usernames
   - Tips for finding users

### No Favorites Yet
1. User taps Favorites tab
2. No favorites saved
3. System shows empty state:
   - "No favorites yet"
   - "Tap the star icon to save items"
   - Icon illustration

## Flow 9: Offline Mode

### No Internet Connection
1. User performs action requiring network
2. System detects no connectivity
3. System checks cache for data
4. If cached data available:
   - System shows cached data
   - System displays "Using cached data" banner
5. If no cached data:
   - System shows offline message
   - System displays retry button

### Connection Restored
1. Internet connection returns
2. User pulls to refresh
3. System fetches fresh data
4. System updates cache
5. Offline banner disappears

## Flow 10: Deep Navigation

### Repository Details from Favorites
1. User opens Favorites tab
2. User selects Repositories segment
3. User taps favorite repository
4. System navigates to repository details
5. System shows full repository information
6. Star icon is filled (already favorited)
7. User can unfavorite from details screen

### User Profile from Favorites
1. User opens Favorites tab
2. User selects Users segment
3. User taps favorite user
4. System navigates to user profile
5. System shows full profile
6. System loads user's repositories
7. Star icon is filled (already favorited)
8. User can unfavorite from profile screen

### Repository from User Profile
1. User viewing user profile
2. User scrolls to repository list
3. User taps repository
4. System navigates to repository details
5. User can favorite repository independently

## Navigation Stack

### Back Navigation
- All detail screens have back button
- Back button returns to previous screen
- Navigation stack maintained properly
- State preserved when navigating back

### Tab Switch with Navigation
1. User deep in navigation stack (Users → Profile → Repository)
2. User taps different tab (e.g., Settings)
3. Navigation stack for Users tab preserved
4. User returns to Users tab
5. User still at Repository details screen
6. Back button still works correctly

## Performance Considerations

### Debouncing
- Repository search: 3 seconds
- User search: 800ms
- Prevents excessive API calls
- Provides smooth typing experience

### Caching
- Search results cached for 5 minutes
- User profiles cached for 10 minutes
- Reduces API calls
- Faster response time

### Image Loading
- Avatar images loaded asynchronously
- Placeholder shown while loading
- Images cached by system
- Smooth scrolling maintained

## Accessibility

### VoiceOver Support
- All interactive elements labeled
- Proper navigation order
- State changes announced
- Search results announced

### Dynamic Type
- Text scales with system settings
- Layout adjusts for larger text
- Minimum touch target sizes maintained

### Color Contrast
- Sufficient contrast in light mode
- Sufficient contrast in dark mode
- Important information not color-only

## Analytics Tracking

Each flow tracks relevant events:
- Search performed
- Repository viewed
- User profile viewed
- Favorite added
- Favorite removed
- Setting changed
- Error occurred

This data helps understand:
- Most common searches
- Popular repositories
- User engagement
- Error frequency
- Feature usage

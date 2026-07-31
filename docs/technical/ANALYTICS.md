# Analytics System

## Overview
Event-based tracking abstraction for monitoring user behavior and app performance.

## Implementation

**Location:** `Modules/Core/Analytics/AnalyticsService.swift`

Protocol-based design with console implementation for logging events.

## Architecture

### AnalyticsService Protocol
Defines single method for tracking events.

### AnalyticsEvent Enum
All trackable events in the app.

### AnalyticsFavoriteType
Distinguishes between user and repository favorites.

## Event Categories

### Search Events
- searchPerformed - Tracks search queries and result counts

### Navigation Events
- repositoryViewed - Repository details viewed
- userProfileViewed - User profile viewed

### Favorites Events
- favoriteAdded - Item added to favorites
- favoriteRemoved - Item removed from favorites

### Settings Events
- settingChanged - App setting modified

### Error Events
- errorOccurred - Error with context tracking

## Current Implementation

### ConsoleAnalyticsService
Default implementation logs events to console using OSLog.

**Location:** `Modules/Core/Analytics/AnalyticsService.swift`

## Integration Points

Analytics tracked in:
- HomeViewModel - Repository search and views
- UserSearchViewModel - User search
- UserProfileViewModel - Profile views
- FavoritesManager - Favorite operations

## Usage Pattern

ViewModels inject AnalyticsService via dependency injection:
- Use @Injected property wrapper
- Track events after actions complete
- Include relevant context (query, counts, types)

## Testing

### Mock Implementation
MockAnalyticsService captures events for verification in tests.

**Benefits:**
- Verify events tracked correctly
- Test without side effects
- Validate event parameters

## Future Enhancements

### Third-Party Integration
Replace ConsoleAnalyticsService with real analytics:
- Firebase Analytics
- Amplitude
- Mixpanel

### Additional Events
- Session tracking (start, end, duration)
- User properties
- Screen view tracking
- A/B test assignments

## Privacy Considerations

### Data Collection
- No personally identifiable information collected
- Search queries logged for analysis (anonymous)
- Error messages may contain technical details
- No user credentials tracked

### GDPR Compliance
- All tracking anonymous
- No cross-app tracking
- User can clear all data
- Analytics data not shared

## Best Practices

- Track meaningful user actions
- Avoid tracking sensitive data
- Use consistent naming conventions
- Keep event parameters simple
- Log errors with context
- Test analytics in development

## File References

- Protocol: `Modules/Core/Analytics/AnalyticsService.swift`
- Implementation: `Modules/Core/Analytics/ConsoleAnalyticsService.swift`
- Usage: ViewModels in `Modules/Feature/UI/`

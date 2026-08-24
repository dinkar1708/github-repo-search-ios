# Caching Strategy

## Overview
Multi-layer caching system using NSCache with time-to-live support for improved performance.

## Implementation

**Location:** `Modules/Core/Cache/CacheService.swift`

Protocol-based design with type-safe Codable support and automatic expiration.

## Architecture

### CacheService Protocol
Defines methods for getting, setting, removing, and clearing cached data.

### Features
- Type-safe with Codable
- Time-to-live expiration
- Thread-safe operations
- Memory-based caching
- Automatic cleanup

## Cache Keys

### Naming Convention
Use descriptive prefixes to organize cache keys:

- Search results: `search:<query>:page:<page>`
- User profiles: `user:<username>`
- User repositories: `repos:<username>:page:<page>`

## TTL Guidelines

### Recommended Values
- Search results: 300 seconds (5 minutes)
- User profiles: 600 seconds (10 minutes)
- Repository lists: 300 seconds (5 minutes)
- Static content: 3600 seconds (1 hour)

### Considerations
- API rate limits: Longer TTL reduces API calls
- Data freshness: Shorter TTL shows recent updates
- User experience: Balance between speed and accuracy

## Current Usage

### ViewModels
Cache used in:
- HomeViewModel - Repository search results
- UserSearchViewModel - User search results
- UserProfileViewModel - User profiles and repositories

### Cache Flow
1. Check cache first for existing data
2. Return cached data if valid (not expired)
3. Fetch from network if cache miss
4. Store fresh data in cache with TTL

## Memory Management

### NSCache Benefits
- Automatic eviction under memory pressure
- Thread-safe operations
- No manual cleanup required
- Respects system memory warnings
- LRU eviction policy

## Current Limitations

### Cache Writes Disabled
Cache reads work, but writes disabled for types with Date fields.

**Reason:** SearchItemResponse and UserRepository contain Date properties requiring custom Encodable implementation.

**Impact:** Network requests made every time instead of using cache.

**Future:** Implement custom Date encoding strategy.

## Settings Integration

### Clear Cache Action
Settings screen provides manual cache clearing for user control.

## Testing

### Mock Implementation
MockCacheService available for testing without actual caching.

**Benefits:**
- Predictable test results
- No side effects
- Fast test execution

## Best Practices

- Use descriptive cache keys with prefixes
- Set appropriate TTL based on data volatility
- Clear cache on user logout
- Monitor cache hit rate in development
- Handle cache misses gracefully

## File References

- Protocol: `Modules/Core/Cache/CacheService.swift`
- Usage: ViewModels in `Modules/Feature/UI/`

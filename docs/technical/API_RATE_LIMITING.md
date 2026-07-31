# API Rate Limiting

## Overview
How the app handles GitHub API rate limits and optimizes API usage.

## GitHub API Rate Limits

### Unauthenticated Requests

**Current Implementation:**
- 60 requests per hour
- Rate limit based on IP address
- Resets every hour

**Limit Headers:**
```
X-RateLimit-Limit: 60
X-RateLimit-Remaining: 57
X-RateLimit-Reset: 1372700873
```

### Authenticated Requests (Not Implemented)

**If implemented in future:**
- 5,000 requests per hour
- Requires GitHub personal access token
- Better for heavy usage

**How to Add:**
```swift
var urlRequest = URLRequest(url: url)
urlRequest.setValue("Bearer <token>", forHTTPHeaderField: "Authorization")
```

## Rate Limiting Strategy

### 1. Request Debouncing

**Search Debouncing:**
```swift
// Repository search: 3 seconds
private var searchTask: Task<Void, Never>?

func onSearchTextChange() {
    searchTask?.cancel()
    searchTask = Task {
        try? await Task.sleep(nanoseconds: 3_000_000_000)
        await performSearch()
    }
}
```

**User Search Debouncing:**
```swift
// User search: 800ms
func onUserSearchTextChange() {
    searchTask?.cancel()
    searchTask = Task {
        try? await Task.sleep(nanoseconds: 800_000_000)
        await performUserSearch()
    }
}
```

**Benefits:**
- Prevents API calls while user is typing
- Reduces unnecessary requests
- Improves user experience
- Stays within rate limits

### 2. Caching

**Implementation:**
- In-memory cache (NSCache)
- TTL-based expiration
- Cache keys based on request parameters

**Cache Strategy:**
```swift
// Check cache first
if let cached = cache.get(for: cacheKey, as: SearchItemResponse.self) {
    return cached
}

// Make API call only if cache miss
let response = try await apiClient.request(request)

// Store in cache for future use
cache.set(response, for: cacheKey, ttl: 300) // 5 minutes
```

**Cache Keys:**
```
search:<query>:page:<page>       // Repository search
user:<username>                  // User profile
repos:<username>:page:<page>     // User repositories
users:search:<query>:page:<page> // User search
```

**TTL Configuration:**
```swift
searchResults: 300 seconds   (5 minutes)
userProfiles: 600 seconds    (10 minutes)
userRepos: 300 seconds       (5 minutes)
```

**Location:** `Modules/Core/Cache/CacheService.swift`

### 3. Pagination

**Implementation:**
- Load 30 items per page
- Lazy loading on scroll
- Prevents loading all results at once

**Example:**
```swift
func searchRepositories(query: String, page: Int = 1, perPage: Int = 30) async throws {
    let request = SearchRepoRequest(
        queryString: query,
        perPage: perPage,
        pageNumber: page
    )
    return try await apiClient.request(request)
}
```

**Benefits:**
- Fewer API calls
- Better performance
- Reduced data transfer
- User sees results faster

### 4. Request Cancellation

**Task Cancellation:**
```swift
private var searchTask: Task<Void, Never>?

func cancelPreviousSearch() {
    searchTask?.cancel()
}

func performNewSearch() {
    cancelPreviousSearch()
    searchTask = Task {
        // New search
    }
}
```

**Benefits:**
- Avoids processing outdated requests
- Reduces API usage
- Improves responsiveness

## Rate Limit Monitoring

### Reading Rate Limit Headers

**GitHub Response Headers:**
```swift
func checkRateLimit(response: HTTPURLResponse) {
    if let limit = response.value(forHTTPHeaderField: "X-RateLimit-Limit"),
       let remaining = response.value(forHTTPHeaderField: "X-RateLimit-Remaining"),
       let reset = response.value(forHTTPHeaderField: "X-RateLimit-Reset") {

        logger.info("Rate limit: \(remaining)/\(limit)")

        if let resetTime = TimeInterval(reset) {
            let resetDate = Date(timeIntervalSince1970: resetTime)
            logger.info("Resets at: \(resetDate)")
        }
    }
}
```

### Rate Limit Exceeded

**HTTP 403 Response:**
```json
{
  "message": "API rate limit exceeded",
  "documentation_url": "https://docs.github.com/rest/overview/resources-in-the-rest-api#rate-limiting"
}
```

**Handling:**
```swift
if httpResponse.statusCode == 403 {
    // Check if rate limit exceeded
    if let remaining = httpResponse.value(forHTTPHeaderField: "X-RateLimit-Remaining"),
       remaining == "0" {
        throw NetworkError.rateLimitExceeded(
            resetTime: getReset Time(from: httpResponse)
        )
    }
}
```

**User Message:**
```
"Too many requests. Please try again in a few minutes."
```

## Optimization Techniques

### 1. Conditional Requests (Future)

**ETag Support:**
```swift
// Store ETag from response
let etag = response.value(forHTTPHeaderField: "ETag")

// Use ETag in next request
request.setValue(etag, forHTTPHeaderField: "If-None-Match")

// If data unchanged, GitHub returns 304 Not Modified
// Doesn't count against rate limit!
```

**Not Implemented Yet** - Requires persistence layer for ETags

### 2. Batch Operations

**Current:**
- One request per search
- One request per user profile
- One request per repository list

**Optimization:**
- Use GraphQL API (GitHub v4) for batch queries
- Single request for multiple data points
- Requires authentication

**Example GraphQL:**
```graphql
query {
  user(login: "username") {
    name
    repositories(first: 30) {
      nodes {
        name
        description
      }
    }
  }
}
```

### 3. Smart Caching

**Current Implementation:**
- Fixed TTL (5-10 minutes)
- In-memory only

**Future Improvements:**
- Persistent cache (CoreData)
- Longer TTL for static data
- Background refresh
- Offline support

### 4. Prefetching

**Strategic Prefetching:**
```swift
func prefetchNextPage() {
    // When user scrolls to 80% of current page
    // Prefetch next page
    if shouldPrefetch {
        Task {
            await loadNextPage()
        }
    }
}
```

**Benefits:**
- Smoother user experience
- No waiting for next page
- Controlled API usage

## Rate Limit Best Practices

### DO:

✓ **Use caching aggressively**
```swift
// Cache every API response
cache.set(response, for: key, ttl: 300)
```

✓ **Debounce user input**
```swift
// Wait for user to stop typing
try? await Task.sleep(nanoseconds: 3_000_000_000)
```

✓ **Cancel outdated requests**
```swift
// Cancel when user types again
previousTask?.cancel()
```

✓ **Use pagination**
```swift
// Load 30 items, not all
perPage: 30
```

✓ **Monitor rate limits**
```swift
// Log remaining requests
logger.debug("Remaining: \(remaining)")
```

### DON'T:

✗ **Make requests on every keystroke**
```swift
// Bad - no debouncing
func onChange() {
    performSearch() // ❌
}
```

✗ **Load all results at once**
```swift
// Bad - no pagination
perPage: 1000 // ❌
```

✗ **Ignore cache**
```swift
// Bad - always hit API
let data = try await api.fetch() // ❌
```

✗ **Forget to handle rate limit errors**
```swift
// Bad - no error handling
try await makeRequest() // ❌
```

## Monitoring & Analytics

### Track API Usage

**Analytics Events:**
```swift
enum APIEvent {
    case searchPerformed(query: String, cached: Bool)
    case rateLimitWarning(remaining: Int)
    case rateLimitExceeded
    case cacheHit(key: String)
    case cacheMiss(key: String)
}
```

**Metrics to Track:**
- Total API calls per session
- Cache hit rate
- Rate limit warnings
- Failed requests due to rate limit

**Implementation:**
```swift
func trackAPICall(cached: Bool) {
    analytics.track(event: .searchPerformed(
        query: searchText,
        cached: cached
    ))

    if !cached {
        apiCallCount += 1
    }
}
```

### User Notifications

**Rate Limit Warning:**
```swift
// When remaining < 10
if remaining < 10 {
    showWarning("Running low on API requests. Results may be cached.")
}
```

**Rate Limit Exceeded:**
```swift
// When limit exceeded
showError("Too many requests. Try again at \(resetTime)")
```

## Testing Rate Limits

### Manual Testing

**Trigger Rate Limit:**
```swift
// In test environment
for i in 0..<61 {
    try await searchRepositories(query: "test\(i)")
}
// Should hit rate limit
```

**Test Cache:**
```swift
// First call - API
let result1 = try await search(query: "swift")

// Second call - Cache
let result2 = try await search(query: "swift")

XCTAssertEqual(apiCallCount, 1) // Only one API call
```

### Automated Testing

**Mock Rate Limit:**
```swift
class MockAPIClient: APIClient {
    var requestCount = 0
    var rateLimitThreshold = 5

    func request<T>(_ request: T) async throws -> T.Response {
        requestCount += 1

        if requestCount > rateLimitThreshold {
            throw NetworkError.rateLimitExceeded
        }

        return mockResponse
    }
}
```

## Future Improvements

### Authentication

**Add GitHub Token:**
- Increases limit to 5,000/hour
- Requires token management
- Security considerations

**Implementation:**
```swift
struct GitHubConfig {
    static let token: String? = nil // Configure in xcconfig
}

if let token = GitHubConfig.token {
    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
}
```

### Persistent Cache

**CoreData Integration:**
- Cache survives app restart
- Longer TTL (hours/days)
- Offline mode

**Benefits:**
- Fewer API calls
- Better offline support
- Faster app launches

### GraphQL API

**Migration Benefits:**
- More efficient queries
- Batch operations
- Flexible data fetching
- Better rate limiting

**Considerations:**
- Requires authentication
- More complex implementation
- Learning curve

## Troubleshooting

### "Rate limit exceeded" Error

**Causes:**
- Too many requests in short time
- No caching
- No debouncing

**Solutions:**
1. Wait for rate limit reset
2. Check cache implementation
3. Verify debouncing
4. Reduce request frequency

### Cache Not Working

**Check:**
- Cache TTL not expired
- Cache key correct
- Cache size limits
- Memory warnings

**Debug:**
```swift
logger.debug("Cache check for key: \(key)")
logger.debug("Cache hit: \(hit)")
logger.debug("Cache size: \(cache.currentSize)")
```

### Slow Performance

**Possible Issues:**
- Too many API calls
- No pagination
- Large responses
- No caching

**Solutions:**
- Implement caching
- Use pagination
- Reduce per-page count
- Optimize queries

## References

### GitHub API Documentation

- [Rate Limiting](https://docs.github.com/en/rest/overview/resources-in-the-rest-api#rate-limiting)
- [Best Practices](https://docs.github.com/en/rest/guides/best-practices-for-integrators)
- [Conditional Requests](https://docs.github.com/en/rest/overview/resources-in-the-rest-api#conditional-requests)

### Internal Documentation

- [Caching Strategy](CACHING.md)
- [API Integration](../product/API_INTEGRATION.md)
- [Error Handling](ERROR_HANDLING.md)

## Summary

**Rate Limiting Strategies:**
- ✓ Debouncing (3s for repositories, 800ms for users)
- ✓ Caching (5-10 minute TTL)
- ✓ Pagination (30 items per page)
- ✓ Request cancellation
- ✓ Error handling

**Current Limits:**
- 60 requests/hour (unauthenticated)
- Managed through caching and debouncing
- User experience optimized

**Future Enhancements:**
- Authentication (5,000 req/hour)
- Persistent cache
- GraphQL migration
- Conditional requests

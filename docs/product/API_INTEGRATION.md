# GitHub API Integration

## Overview
Integration with GitHub REST API v3 for searching repositories and users.

## Base Configuration

- **API Endpoint:** `https://api.github.com`
- **API Version:** GitHub REST API v3
- **Authentication:** Currently unauthenticated (60 requests/hour limit)

## API Endpoints

### 1. Search Repositories

**Endpoint:** `GET /search/repositories`

**Parameters:**
- q: Search query (required)
- page: Page number (optional, default: 1)
- per_page: Results per page (optional, default: 30)

**Response:** SearchItemResponse with list of repositories and total count

**File:** `Modules/Data/Remote/Request/SearchRepositoriesRequest.swift`

### 2. Search Users

**Endpoint:** `GET /search/users`

**Parameters:**
- q: Search query (required)
- page: Page number (optional, default: 1)
- per_page: Results per page (optional, default: 30)

**Response:** SearchUserResponse with list of users and total count

**File:** `Modules/Data/Remote/Request/SearchUsersRequest.swift`

### 3. Get User Profile

**Endpoint:** `GET /users/{username}`

**Parameters:**
- username: GitHub username (required)

**Response:** UserProfile with user details, stats, and bio

**File:** `Modules/Data/Remote/Request/GetUserProfileRequest.swift`

### 4. Get User Repositories

**Endpoint:** `GET /users/{username}/repos`

**Parameters:**
- username: GitHub username (required)
- page: Page number (optional, default: 1)
- per_page: Results per page (optional, default: 30)

**Response:** Array of UserRepository objects

**File:** `Modules/Data/Remote/Request/GetUserRepositoriesRequest.swift`

## Request/Response Flow

### ApiClient Implementation

**Location:** `Modules/Data/Remote/API/ApiClient.swift`

1. Construct URL with base URL and endpoint path
2. Add query parameters
3. Set HTTP method and headers
4. Execute request with URLSession
5. Validate HTTP response status
6. Decode JSON response
7. Return typed result

### Request Protocol

**Location:** `Modules/Data/Remote/API/ApiRequest.swift`

All API requests implement ApiRequest protocol defining:
- Response type (associated type)
- Endpoint path
- HTTP method
- Query parameters
- Headers

## Date Handling

### ISO8601 Format
GitHub API returns dates in ISO8601 format: `2024-01-15T10:30:00Z`

### Decoder Strategy
JSON decoder configured with ISO8601 date decoding strategy.

### Date Properties
Models with date fields:
- createdAt
- updatedAt
- pushedAt

## Error Handling

### Network Errors

**File:** `Modules/Data/Remote/Error/NetworkError.swift`

Error types:
- invalidURL - URL construction failed
- requestFailed - Network request failed
- invalidResponse - Non-HTTP response
- decodingFailed - JSON parsing failed
- serverError - HTTP error status code
- noData - Empty response

### Status Code Handling

- 200-299: Success
- 401: Unauthorized - Authentication required
- 403: Forbidden - Rate limit or access denied
- 404: Not Found - Resource not found
- 422: Validation failed
- 429: Rate limit exceeded
- 503: Service unavailable

### Rate Limiting

**Unauthenticated:** 60 requests/hour
**Authenticated:** 5000 requests/hour

Response headers provide rate limit info:
- X-RateLimit-Limit
- X-RateLimit-Remaining
- X-RateLimit-Reset

## Pagination

### Request Parameters
Use page and per_page parameters for pagination.

### Response Headers
GitHub provides pagination info in Link header with next, last, prev, first relations.

### Implementation
ViewModels track current page and load next page when user scrolls to bottom.

## Caching Strategy

### Cache Keys
Format: `<type>:<query>:page:<page>`

Examples:
- `search:swift:page:1`
- `user:torvalds`
- `repos:apple:page:2`

### TTL Values
- Search results: 300 seconds (5 minutes)
- User profiles: 600 seconds (10 minutes)
- Repository lists: 300 seconds (5 minutes)

### Cache Flow
1. Check cache for key
2. Return if valid and not expired
3. Fetch from API if cache miss
4. Store in cache with TTL

## Search Query Syntax

### Basic Search
Simple keyword search: `swift`

### Filters
- Language: `language:swift`
- Stars: `stars:>1000`
- Created date: `created:>2024-01-01`

### Combining Filters
Multiple filters: `language:swift stars:>1000`

### User Search
- Location: `location:tokyo`
- Followers: `followers:>100`

## Best Practices

### Debouncing
Avoid excessive API calls with debouncing:
- Repository search: 3 seconds
- User search: 800ms

### Error Recovery
Implement retry logic for transient errors.

### Logging
Log all API calls with query parameters and errors.

### Analytics
Track API usage for monitoring and optimization.

## Future Enhancements

### Authentication
Add GitHub token for higher rate limits (5000 requests/hour).

### GraphQL API
Consider GraphQL for complex queries with fewer requests.

### Offline Support
Store API responses locally for offline access.

## File References

- API Client: `Modules/Data/Remote/API/ApiClient.swift`
- Requests: `Modules/Data/Remote/Request/`
- Models: `Modules/Data/Remote/Model/`
- Errors: `Modules/Data/Remote/Error/NetworkError.swift`
- Repository: `Modules/Data/Remote/Repository/GithubRepository.swift`

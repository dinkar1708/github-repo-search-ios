# Error Handling

## Overview
Structured error handling with typed errors and user-friendly messages.

## Implementation

**Location:** `Modules/Data/Remote/Error/NetworkError.swift`

Enum-based error system conforming to LocalizedError for user-facing messages.

## Error Types

### NetworkError Enum

**invalidURL**
- Cause: URL construction failed
- Example: Invalid characters in query
- Recovery: Validate input before creating URL

**requestFailed**
- Cause: Network request failed
- Example: No internet connection, timeout
- Recovery: Show retry button, check network status

**invalidResponse**
- Cause: Non-HTTP response received
- Example: Unexpected response type
- Recovery: Log error, report to analytics

**decodingFailed**
- Cause: JSON decoding failed
- Example: API response format changed
- Recovery: Log detailed error, update model

**serverError**
- Cause: HTTP error status code
- Example: 404 Not Found, 429 Too Many Requests
- Recovery: Show message based on status code

**noData**
- Cause: Empty response body
- Example: Successful request but no content
- Recovery: Treat as empty result set

## Status Code Handling

### Success Range
200-299: Request succeeded

### Common Status Codes
- 200 OK - Success
- 201 Created - Resource created
- 204 No Content - Success with no data
- 400 Bad Request - Invalid parameters
- 401 Unauthorized - Authentication required
- 403 Forbidden - No permission
- 404 Not Found - Resource not found
- 429 Too Many Requests - Rate limit exceeded
- 500 Internal Server Error - Server error
- 503 Service Unavailable - Service down

## Error Display

### In ViewModels
ViewModels expose errorMessage property for UI display.

### User Messages
Keep messages:
- Clear and concise
- Non-technical
- Actionable when possible

Examples:
- "No internet connection. Please check your network."
- "Unable to load data. Tap to retry."
- "Something went wrong. Please try again later."

## Logging Strategy

### Error Logging
All errors logged with:
- Error type and description
- Context (where error occurred)
- Analytics event tracking

### Context Tracking
Always include context in error tracking to identify source.

## Recovery Strategies

### Retry Logic
Implement retry for transient errors:
- Network failures
- Timeouts
- Server errors (500-599)

### Fallback Data
Use cached data when network fails.

### Graceful Degradation
Show partial data if some requests fail.

## Testing

### Mock Errors
MockGithubRepository can simulate errors for testing error handling.

### Test Coverage
Verify:
- Error messages displayed
- Loading state cleared
- Retry functionality works
- Analytics events tracked

## API Rate Limiting

### GitHub API Limits
- Unauthenticated: 60 requests/hour
- Authenticated: 5000 requests/hour

### Handling 429 Errors
Show rate limit message and suggest waiting.

### Prevention
- Cache responses
- Debounce search queries
- Batch requests when possible

## Best Practices

### Do
- Use typed errors (NetworkError)
- Provide user-friendly messages
- Log errors with context
- Track errors in analytics
- Implement retry logic for transient errors
- Fallback to cached data when possible
- Show recovery options (Retry button)

### Don't
- Silently swallow errors
- Show technical details to users
- Log sensitive data in errors
- Ignore error types (catch-all)
- Block UI during error handling
- Retry indefinitely

## File References

- Error Types: `Modules/Data/Remote/Error/NetworkError.swift`
- API Client: `Modules/Data/Remote/API/ApiClient.swift`
- ViewModels: `Modules/Feature/UI/*/ViewModel/`

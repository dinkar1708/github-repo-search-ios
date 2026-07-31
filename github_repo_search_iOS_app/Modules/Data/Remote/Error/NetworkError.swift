//
//  NetworkError.swift
//  github_repo_search_iOS_app
//
//  Created for typed network error handling
//

import Foundation

/// Typed network errors for better error handling and user feedback
enum NetworkError: Error, Sendable {
    case unauthorized(message: String)
    case rateLimited(resetDate: Date?)
    case notFound
    case serverError(statusCode: Int, message: String?)
    case invalidResponse
    case decodingFailed(DecodingError)
    case networkUnavailable
    case invalidURL(String)
    case timeout
    case unknown(Error)

    // MARK: - User-Friendly Messages

    var userMessage: String {
        switch self {
        case .unauthorized:
            return "Authentication required. Please check your credentials."
        case .rateLimited(let resetDate):
            if let date = resetDate {
                return "Rate limit exceeded. Try again at \(date.formatted(date: .omitted, time: .shortened))."
            }
            return "Rate limit exceeded. Please try again later."
        case .notFound:
            return "The requested resource was not found."
        case .serverError(let code, let message):
            if let message = message {
                return "Server error (\(code)): \(message)"
            }
            return "Server error (\(code)). Please try again later."
        case .invalidResponse:
            return "Invalid response from server. Please try again."
        case .decodingFailed:
            return "Failed to process server response. Please try again."
        case .networkUnavailable:
            return "No internet connection. Please check your network."
        case .invalidURL:
            return "Invalid request URL. Please contact support."
        case .timeout:
            return "Request timed out. Please try again."
        case .unknown(let error):
            return "An unexpected error occurred: \(error.localizedDescription)"
        }
    }

    // MARK: - Retry Logic

    var isRetryable: Bool {
        switch self {
        case .serverError, .invalidResponse, .timeout, .networkUnavailable:
            return true
        case .unauthorized, .notFound, .decodingFailed, .invalidURL, .rateLimited, .unknown:
            return false
        }
    }

    // MARK: - From ApiResponseError

    static func from(_ apiError: ApiResponseError) -> NetworkError {
        // Parse status code if available
        if let statusCode = parseStatusCode(from: apiError.message) {
            switch statusCode {
            case 401:
                return .unauthorized(message: apiError.message)
            case 403:
                // Check if it's a rate limit error
                if apiError.message.lowercased().contains("rate limit") {
                    return .rateLimited(resetDate: nil)
                }
                return .unauthorized(message: apiError.message)
            case 404:
                return .notFound
            case 500...599:
                return .serverError(statusCode: statusCode, message: apiError.message)
            default:
                break
            }
        }

        // Check for network errors
        if apiError.message.lowercased().contains("network") ||
           apiError.message.lowercased().contains("internet") {
            return .networkUnavailable
        }

        // Default to server error
        return .serverError(statusCode: 0, message: apiError.message)
    }

    private static func parseStatusCode(from message: String) -> Int? {
        // Try to extract status code from error message
        let pattern = "\\b(\\d{3})\\b"
        if let regex = try? NSRegularExpression(pattern: pattern),
           let match = regex.firstMatch(in: message, range: NSRange(message.startIndex..., in: message)),
           let range = Range(match.range(at: 1), in: message) {
            return Int(message[range])
        }
        return nil
    }
}

// MARK: - LocalizedError Conformance

extension NetworkError: LocalizedError {
    var errorDescription: String? {
        return userMessage
    }
}

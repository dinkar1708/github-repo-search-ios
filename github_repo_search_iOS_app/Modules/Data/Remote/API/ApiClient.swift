//
//  ApiClient.swift
//  github_repo_search_iOS_app
//
//  Created by Dinakar Maurya on 2021/08/12.
//  
//

import Foundation
import SwiftUI
import OSLog

/**
 Reusable api client for api call using modern Swift concurrency
 No @MainActor, Sendable conformance, HTTP status validation
 */
struct ApiClient: Sendable {
    struct Response<T>: Sendable where T: Sendable {
        let value: T
        let response: URLResponse
        let statusCode: Int
    }

    private let session: URLSession
    private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.app.github", category: "networking")

    init(timeoutInterval: TimeInterval = 30) {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = timeoutInterval
        config.timeoutIntervalForResource = timeoutInterval * 2
        config.waitsForConnectivity = true
        self.session = URLSession(configuration: config)
    }

    func run<T: Decodable & Sendable>(_ request: URLRequest, retryCount: Int = 2) async throws -> Response<T> {
        Self.logger.info("🌐 \(request.httpMethod ?? "GET") request to \(request.url?.absoluteString ?? "unknown")")

        if let body = request.httpBody?.prettyJson {
            Self.logger.debug("📤 Request body: \(body)")
        }

        var lastError: Error?

        for attempt in 0...retryCount {
            if attempt > 0 {
                Self.logger.warning("🔄 Retry attempt \(attempt) of \(retryCount)")
                // Exponential backoff: wait 1s, 2s, 4s, etc.
                let delaySeconds = pow(2.0, Double(attempt - 1))
                try? await Task.sleep(nanoseconds: UInt64(delaySeconds * 1_000_000_000))
            }

            do {
                let (data, response) = try await session.data(for: request)

                guard let httpResponse = response as? HTTPURLResponse else {
                    throw ApiResponseError(message: "Invalid response type")
                }

                let statusCode = httpResponse.statusCode
                if (200...299).contains(statusCode) {
                    Self.logger.info("✅ Response - Status: \(statusCode)")
                } else {
                    Self.logger.error("❌ Response - Status: \(statusCode)")
                }

                // Validate HTTP status code
                guard (200...299).contains(httpResponse.statusCode) else {
                    let message = "HTTP \(httpResponse.statusCode)"

                    // Don't retry client errors (4xx), only server errors (5xx) and network errors
                    if (400...499).contains(httpResponse.statusCode) {
                        throw ApiResponseError.invalidResponse(statusCode: httpResponse.statusCode, message: message)
                    }

                    lastError = ApiResponseError.invalidResponse(statusCode: httpResponse.statusCode, message: message)
                    continue // Retry for 5xx errors
                }

                do {
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .formatted(Formatter.iso8601)
                    let value = try decoder.decode(T.self, from: data)
                    Self.logger.info("✅ Successfully decoded response")
                    return Response(value: value, response: response, statusCode: httpResponse.statusCode)
                } catch {
                    Self.logger.error("❌ JSON decoding failed: \(error.localizedDescription)")
                    throw try JSONDecoder().decode(ApiResponseError.self, from: data)
                }
            } catch let error as ApiResponseError {
                // Client errors (4xx) should not be retried
                if case .invalidResponse(let code, _) = error, (400...499).contains(code) {
                    throw error
                }
                lastError = error
                Self.logger.error("❌ API Error (attempt \(attempt)): \(error.message)")
            } catch {
                // Network errors should be retried
                lastError = error
                Self.logger.error("❌ Network Error (attempt \(attempt)): \(error.localizedDescription)")
            }
        }

        // All retries failed, throw the last error
        Self.logger.error("❌ All retry attempts failed after \(retryCount) retries")
        if let error = lastError {
            if let apiError = error as? ApiResponseError {
                throw apiError
            }
            throw ApiResponseError(message: error.localizedDescription)
        }
        throw ApiResponseError(message: "Request failed after \(retryCount) retries")
    }
}

//
//  ApiResponseError.swift
//  github_repo_search_iOS_app
//
//  Created by Dinakar Maurya on 2021/08/12.
//  
//

import Foundation
/**
 Reusable api error response type
 Sendable conformance for thread safety
 */
enum ApiResponseError: Error, Sendable {
    case invalidResponse(statusCode: Int, message: String)
    case decodingError(String)
    case networkError(String)
    case apiError(errors: [ApiError]?, message: String, documentationUrl: String)

    var message: String {
        switch self {
        case .invalidResponse(_, let message):
            return message
        case .decodingError(let message):
            return message
        case .networkError(let message):
            return message
        case .apiError(_, let message, _):
            return message
        }
    }

    init(errors: [ApiError] = [], message: String = "Unknown Error!", documentation_url: String = "") {
        self = .apiError(errors: errors, message: message, documentationUrl: documentation_url)
    }
}

// For backward compatibility with Decodable
extension ApiResponseError: Decodable {
    enum CodingKeys: String, CodingKey {
        case errors
        case message
        case documentation_url
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let errors = try container.decodeIfPresent([ApiError].self, forKey: .errors)
        let message = try container.decode(String.self, forKey: .message)
        let docUrl = try container.decodeIfPresent(String.self, forKey: .documentation_url) ?? ""
        self = .apiError(errors: errors, message: message, documentationUrl: docUrl)
    }
}

/**
 Api error details
 Sendable conformance for thread safety
 */
struct ApiError: Decodable, Sendable {
    let message: String
    let resource: String
    let field: String
    let code: String
    
    init(message: String, resource: String, field: String, code: String) {
        self.message = message
        self.resource = resource
        self.field = field
        self.code = code
    }
}

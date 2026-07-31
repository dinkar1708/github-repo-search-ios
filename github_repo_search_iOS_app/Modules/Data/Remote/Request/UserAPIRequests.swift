//
//  UserAPIRequests.swift
//  github_repo_search_iOS_app
//
//  API requests for user-related endpoints
//

import Foundation

// MARK: - User API Calls
extension GithubAPI {

    // MARK: API-1: Search Users
    struct SearchUsersRequest: ApiRequest, Sendable {
        var query: String
        var perPage: Int
        var page: Int

        var path: String { return "search/users" }
        var urlParameters: [String: Any] {
            return [
                "q": query,
                "per_page": perPage,
                "page": page
            ]
        }
        var method: HttpMethod { .get }
    }

    static func searchUsers(requestObject: SearchUsersRequest) async throws -> SearchUser {
        var urlRequest = try requestObject.buildURLRequest()
        urlRequest.httpBody = requestObject.encodeRequestBody()
        urlRequest.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        let response: ApiClient.Response<SearchUser> = try await sharedApiClient.run(urlRequest)
        return response.value
    }

    // MARK: API-2: Get User Profile
    struct GetUserProfileRequest: ApiRequest, Sendable {
        var username: String

        var path: String { return "users/\(username)" }
        var urlParameters: [String: Any] { return [:] }
        var method: HttpMethod { .get }
    }

    static func getUserProfile(requestObject: GetUserProfileRequest) async throws -> UserProfile {
        var urlRequest = try requestObject.buildURLRequest()
        urlRequest.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        let response: ApiClient.Response<UserProfile> = try await sharedApiClient.run(urlRequest)
        return response.value
    }

    // MARK: API-3: Get User Repositories
    struct GetUserRepositoriesRequest: ApiRequest, Sendable {
        var username: String
        var perPage: Int
        var page: Int

        var path: String { return "users/\(username)/repos" }
        var urlParameters: [String: Any] {
            return [
                "per_page": perPage,
                "page": page
            ]
        }
        var method: HttpMethod { .get }
    }

    static func getUserRepositories(requestObject: GetUserRepositoriesRequest) async throws -> [UserRepository] {
        var urlRequest = try requestObject.buildURLRequest()
        urlRequest.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        let response: ApiClient.Response<[UserRepository]> = try await sharedApiClient.run(urlRequest)
        return response.value
    }
}

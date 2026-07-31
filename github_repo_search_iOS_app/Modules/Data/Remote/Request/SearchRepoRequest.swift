//
//  SearchRepoRequest.swift
//  github_repo_search_iOS_app
//
//  Created by Dinakar Maurya on 2021/08/12.
//  
//

import Foundation

/**
 GitHub API calls for search in repositories using modern Swift concurrency
 Sendable conformance, no @MainActor on API calls
 */
// MARK: - For git hub api calls For search in repo
extension GithubAPI {

    /**
     Search in repositories with specified query format
     */
    struct SearchRepoRequest: ApiRequest, Sendable {
        var query: String
        var path: String { return "search/repositories" }
        var urlParameters: [String : Any] { return ["q": query]}
        var method: HttpMethod {
            .get
        }
    }

    /**
     Reusable api client for api call using async/await
     Runs on background thread, no @MainActor
     */
    static func searchRepoNames(requestObject: SearchRepoRequest) async throws -> SearchItemResponse {
        var urlRequest = try requestObject.buildURLRequest()
        urlRequest.httpBody = requestObject.encodeRequestBody()
        urlRequest.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        let response: ApiClient.Response<SearchItemResponse> = try await sharedApiClient.run(urlRequest)
        return response.value
    }
}

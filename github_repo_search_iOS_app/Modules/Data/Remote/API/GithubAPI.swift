//
//  GithubAPI.swift
//  github_repo_search_iOS_app
//
//  Created by Dinakar Maurya on 2021/08/12.
//

import Foundation

/**
 Single shared api client object and base url handling
 */
enum GithubAPI {
    static let sharedApiClient = ApiClient()
    static var appBaseUrl: URL {
            get {
                var url = ""
                #if DEBUG
                url = ApiUrls.debugUrl
                    print("DEBUG-------------->>>>>")
                #elseif INHOUSE
                    // TODO change for inhouse level api∫
                url = ApiUrls.inhouseUrl
                    print("INHOUSE-------------->>>>>")
                #else
                    // TODO: change for production level api
                url = ApiUrls.releaseUrl
                    print("RELEASE-------------->>>>>")
                #endif
                // Safe URL creation with fallback
                guard let validURL = URL(string: url) else {
                    fatalError("Invalid base URL configured: \(url)")
                }
                return validURL
            }
        }
}

//
//  GithubAPI.swift
//  github_repo_search_iOS_app
//
//  Created by Dinakar Maurya on 2021/08/12.
//

import Foundation
import OSLog

/**
 Single shared api client object and base url handling
 */
enum GithubAPI {
    private static let logger = Logger.networking

    static let sharedApiClient = ApiClient()
    static var appBaseUrl: URL {
            get {
                var url = ""
                var environment = ""
                #if DEBUG
                url = ApiUrls.debugUrl
                environment = "DEBUG"
                #elseif INHOUSE
                url = ApiUrls.inhouseUrl
                environment = "INHOUSE"
                #else
                url = ApiUrls.releaseUrl
                environment = "RELEASE"
                #endif

                logger.info("Environment: \(environment) - Base URL: \(url, privacy: .public)")

                // Safe URL creation with fallback
                guard let validURL = URL(string: url) else {
                    logger.fault("Invalid base URL configured: \(url)")
                    fatalError("Invalid base URL configured: \(url)")
                }
                return validURL
            }
        }
}

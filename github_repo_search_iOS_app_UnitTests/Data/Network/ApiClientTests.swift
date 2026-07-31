//
//  ApiClientTests.swift
//  UnitTests
//
//  Created for enterprise-scale testing structure
//

import XCTest
@testable import github_repo_search_iOS_app

/// Unit tests for ApiClient - testing network layer in isolation
class ApiClientTests: XCTestCase {

    override func setUpWithError() throws {
        // Reset any state before each test
    }

    override func tearDownWithError() throws {
        // Clean up after each test
    }

    // MARK: - URL Building Tests

    func testURLBuildingWithValidRequest() throws {
        // Arrange
        let request = GithubAPI.SearchRepoRequest(query: "swift in:name&per_page=40&page=1")

        // Act
        let urlRequest = try request.buildURLRequest()

        // Assert
        XCTAssertNotNil(urlRequest.url, "URL should be built successfully")
        XCTAssertTrue(urlRequest.url?.absoluteString.contains("search/repositories") ?? false,
                     "URL should contain search/repositories path")
        XCTAssertEqual(urlRequest.httpMethod, "GET", "HTTP method should be GET")
    }

    func testURLBuildingWithSpecialCharacters() throws {
        // Arrange
        let request = GithubAPI.SearchRepoRequest(query: "swift+mvvm in:name")

        // Act
        let urlRequest = try request.buildURLRequest()

        // Assert
        XCTAssertNotNil(urlRequest.url, "URL should handle special characters")
        XCTAssertTrue(urlRequest.url?.absoluteString.contains("%") ?? false,
                     "Special characters should be URL encoded")
    }

    // MARK: - Request Method Tests

    func testRequestMethod() throws {
        // Arrange
        let request = GithubAPI.SearchRepoRequest(query: "test")

        // Act
        let method = request.method

        // Assert
        XCTAssertEqual(method, .get, "Search request should use GET method")
    }

    // MARK: - Performance Tests (Unit Level)

    func testURLBuildingPerformance() throws {
        let request = GithubAPI.SearchRepoRequest(query: "swift in:name&per_page=40&page=1")

        measure {
            _ = try? request.buildURLRequest()
        }
    }
}

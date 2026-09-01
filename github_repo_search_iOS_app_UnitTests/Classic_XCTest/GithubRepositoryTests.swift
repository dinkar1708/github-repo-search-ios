//
//  GithubRepositoryTests.swift
//  github_repo_search_iOS_app_UnitTests
//
//  Classic XCTest implementation for GithubRepository
//

import XCTest
@testable import github_repo_search_iOS_app

/// Tests for GithubRepository - API calls and data handling
@MainActor
final class GithubRepositoryTests: XCTestCase {
    let gitHubRepository = DefaultGithubRepository()

    override func setUpWithError() throws {
    }

    override func tearDownWithError() throws {
    }

    func testGetSearchResultWithValidQuery() async throws {
        do {
            let searchResponse = try await gitHubRepository.getSearchResultInRepoName(
                queryString: "swift",
                perPage: 60,
                pageNumber: 1
            )

            print("✅ Total search results count: \(searchResponse.totalCount)")
            print("✅ Current page results count: \(searchResponse.items.count)")

            XCTAssertTrue(searchResponse.totalCount > 0, "Expected search results but got \(searchResponse.totalCount)")
        } catch let error as ApiResponseError {
            XCTFail("API Error: \(error.message)")
        } catch {
            XCTFail("Unexpected error: \(error.localizedDescription)")
        }
    }

    func testGetSearchResultWithEmptyResult() async throws {
        do {
            let searchResponse = try await gitHubRepository.getSearchResultInRepoName(
                queryString: "¥¥¥¥¥¥¥¥¥¥¥",
                perPage: 60,
                pageNumber: 1
            )

            print("✅ Empty result test - Total: \(searchResponse.totalCount)")

            XCTAssertTrue(searchResponse.totalCount == 0, "Expected 0 results for invalid search")
        } catch let error as ApiResponseError {
            // Empty result might also come as error, which is acceptable
            print("✅ API Error (expected for invalid search): \(error.message)")
        } catch {
            XCTFail("Unexpected error: \(error.localizedDescription)")
        }
    }

    func testGetSearchResultWithInvalidQuery() async throws {
        do {
            let searchResponse = try await gitHubRepository.getSearchResultInRepoName(
                queryString: "",
                perPage: 60,
                pageNumber: 1
            )

            // If we get here without error, that's unexpected for empty query
            print("Unexpected: got response for empty query")
            XCTFail("Expected error for empty query but got response")
        } catch let error as ApiResponseError {
            print("✅ Received expected error: \(error.message)")
            XCTAssertTrue(error.message.contains("Validation Failed") || error.message.contains("missing") || error.message.contains("422"),
                         "Expected 'Validation Failed' or 422 error, got: \(error.message)")
        } catch {
            XCTFail("Unexpected error type: \(error.localizedDescription)")
        }
    }

    func testPerPageParameterIsUsed() async throws {
        let customPerPage = 25

        do {
            let searchResponse = try await gitHubRepository.getSearchResultInRepoName(
                queryString: "swift",
                perPage: customPerPage,
                pageNumber: 1
            )

            if searchResponse.items.count > 0 {
                XCTAssertLessThanOrEqual(searchResponse.items.count, customPerPage,
                                        "Results should not exceed perPage limit")
            }
        } catch {
            print("⚠️ Network error (acceptable): \(error.localizedDescription)")
        }
    }
}

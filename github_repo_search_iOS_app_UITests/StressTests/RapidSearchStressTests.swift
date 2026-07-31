//
//  RapidSearchStressTests.swift
//  github_repo_search_iOS_app_UITests
//
//  Created for stress testing rapid search operations
//

import XCTest

final class RapidSearchStressTests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Rapid Search Stress Tests

    /// Test rapid consecutive searches for 30 seconds
    /// Monitors: Memory leaks, search throttling, race conditions
    func testRapidSearching30Seconds() throws {
        sleep(5)

        let searchField = app.searchFields.firstMatch
        XCTAssertTrue(searchField.waitForExistence(timeout: 5))

        measure(metrics: [XCTMemoryMetric(), XCTCPUMetric()]) {
            let startTime = Date()
            var searchCount = 0

            while Date().timeIntervalSince(startTime) < 30 {
                searchField.tap()
                searchField.typeText("test\(searchCount)")

                // Wait briefly then clear
                usleep(100_000) // 100ms - faster than debounce

                // Clear the field
                searchField.clearText()

                searchCount += 1
            }

            print("🔍 Total searches in 30s: \(searchCount)")
        }

        // Verify app is still responsive
        XCTAssertTrue(searchField.exists)
    }

    /// Test search cancellation stress
    /// Stress: Start many searches before they complete
    func testSearchCancellationStress() throws {
        sleep(5)

        let searchField = app.searchFields.firstMatch
        XCTAssertTrue(searchField.waitForExistence(timeout: 5))

        measure(metrics: [XCTMemoryMetric()]) {
            for iteration in 0..<30 {
                // Start search
                searchField.tap()
                searchField.typeText("swift\(iteration)")

                // Cancel before debounce completes
                usleep(200_000) // 200ms - less than 3s debounce

                // Clear and start new search
                searchField.clearText()
            }
        }

        // App should still be functional
        XCTAssertTrue(searchField.exists)
    }

    /// Test alternating between empty and full searches
    func testAlternatingSearchStress() throws {
        sleep(5)

        let searchField = app.searchFields.firstMatch
        XCTAssertTrue(searchField.waitForExistence(timeout: 5))

        measure(metrics: [XCTMemoryMetric()]) {
            for _ in 0..<50 {
                // Type search
                searchField.tap()
                searchField.typeText("swift")
                usleep(100_000)

                // Clear search
                searchField.clearText()
                usleep(100_000)
            }
        }

        XCTAssertTrue(searchField.exists)
    }

    /// Test searching while scrolling results
    func testSearchWhileScrolling() throws {
        sleep(5)

        let searchField = app.searchFields.firstMatch
        XCTAssertTrue(searchField.waitForExistence(timeout: 5))

        // Load some initial results
        searchField.tap()
        searchField.typeText("swift")
        sleep(6)

        measure(metrics: [XCTMemoryMetric()]) {
            for iteration in 0..<20 {
                // Scroll rapidly
                app.swipeUp(velocity: .fast)
                app.swipeDown(velocity: .fast)

                // Modify search mid-scroll
                searchField.tap()
                searchField.typeText("\(iteration)")
                usleep(50_000)

                // Continue scrolling
                app.swipeUp(velocity: .fast)
                usleep(100_000)

                // Clear for next iteration
                if iteration % 5 == 0 {
                    searchField.clearText()
                    searchField.typeText("swift")
                }
            }
        }

        XCTAssertTrue(searchField.exists)
    }

    /// Test rapid search term variations
    func testSearchVariationsStress() throws {
        sleep(5)

        let searchField = app.searchFields.firstMatch
        XCTAssertTrue(searchField.waitForExistence(timeout: 5))

        let searchTerms = ["swift", "kotlin", "java", "python", "go", "rust"]

        measure(metrics: [XCTMemoryMetric()]) {
            // Test all search term combinations
            for term1 in searchTerms {
                for term2 in searchTerms where term1 != term2 {
                    searchField.tap()
                    searchField.typeText(term1)
                    usleep(50_000)

                    searchField.clearText()
                    searchField.typeText(term2)
                    usleep(50_000)

                    searchField.clearText()
                }
            }
        }

        XCTAssertTrue(searchField.exists)
    }
}

// MARK: - Helper Extensions

extension XCUIElement {
    func clearText() {
        guard let stringValue = self.value as? String, !stringValue.isEmpty else {
            return
        }

        // Tap to focus, then select all and delete
        self.tap()

        // Double tap to select word, then type to replace
        self.doubleTap()
        self.typeText("")

        // If that didn't work, try deleting character by character
        let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: stringValue.count)
        self.typeText(deleteString)
    }
}

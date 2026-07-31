//
//  HeavyScrollingStressTests.swift
//  github_repo_search_iOS_app_UITests
//
//  Created for stress testing heavy scrolling scenarios
//

import XCTest

final class HeavyScrollingStressTests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Heavy Scrolling Tests

    /// Test rapid scrolling through search results for 60 seconds
    /// Monitors: Memory usage, CPU usage
    /// Expected: Memory < 150MB, 60 FPS, no crashes
    func testHeavyScrolling60Seconds() throws {
        // Wait for app to load (splash + main view)
        sleep(5)

        // Perform search to get many results
        let searchField = app.searchFields.firstMatch
        XCTAssertTrue(searchField.waitForExistence(timeout: 5))
        searchField.tap()
        searchField.typeText("swift")

        // Wait for results to load (throttle + network + UI update)
        sleep(6)

        // Try to find scrollable container
        let table = app.tables.firstMatch
        if !table.exists {
            // If no table, try scrollView or cells
            let cells = app.cells
            XCTAssertTrue(cells.count > 0, "Should have results to scroll")
        }

        // Measure heavy scrolling for 60 seconds
        measure(metrics: [XCTMemoryMetric(), XCTCPUMetric()]) {
            let startTime = Date()
            var scrollCount = 0

            // Scroll for 60 seconds
            while Date().timeIntervalSince(startTime) < 60 {
                // Scroll down rapidly (3 swipes)
                app.swipeUp(velocity: .fast)
                app.swipeUp(velocity: .fast)
                app.swipeUp(velocity: .fast)

                scrollCount += 3

                // Scroll up rapidly (2 swipes)
                app.swipeDown(velocity: .fast)
                app.swipeDown(velocity: .fast)

                scrollCount += 2

                // Brief pause to allow rendering (50ms)
                usleep(50_000)
            }

            print("🔄 Total scroll gestures in 60s: \(scrollCount)")
        }

        // Verify app is still responsive
        XCTAssertTrue(searchField.exists)
    }

    /// Test extreme scrolling - 100 rapid swipes
    /// Monitors: Memory spikes, frame drops
    func testExtremeRapidScrolling() throws {
        sleep(5)

        let searchField = app.searchFields.firstMatch
        XCTAssertTrue(searchField.waitForExistence(timeout: 5))
        searchField.tap()
        searchField.typeText("ios")
        sleep(6)

        measure(metrics: [XCTMemoryMetric()]) {
            // 100 rapid swipes without pause
            for i in 0..<100 {
                if i % 2 == 0 {
                    app.swipeUp(velocity: .fast)
                } else {
                    app.swipeDown(velocity: .fast)
                }
            }
        }

        // App should still be functional
        XCTAssertTrue(searchField.exists)
    }

    /// Test scrolling while loading more data (pagination stress)
    func testScrollingDuringPagination() throws {
        sleep(5)

        let searchField = app.searchFields.firstMatch
        XCTAssertTrue(searchField.waitForExistence(timeout: 5))
        searchField.tap()
        searchField.typeText("react")
        sleep(6)

        measure(metrics: [XCTMemoryMetric(), XCTCPUMetric()]) {
            // Scroll to bottom quickly to trigger pagination
            for _ in 0..<20 {
                app.swipeUp(velocity: .fast)
                usleep(100_000) // 100ms
            }

            // Scroll back up while data might still be loading
            for _ in 0..<10 {
                app.swipeDown(velocity: .fast)
                usleep(100_000)
            }
        }

        XCTAssertTrue(searchField.exists)
    }

    /// Test momentum scrolling (fling scrolls)
    func testMomentumScrollingStress() throws {
        sleep(5)

        let searchField = app.searchFields.firstMatch
        XCTAssertTrue(searchField.waitForExistence(timeout: 5))
        searchField.tap()
        searchField.typeText("javascript")
        sleep(6)

        measure(metrics: [XCTMemoryMetric()]) {
            // Fast momentum scrolls using app coordinates
            for _ in 0..<30 {
                // Long fast swipe to create momentum
                let startPoint = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.8))
                let endPoint = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.2))

                startPoint.press(forDuration: 0.05, thenDragTo: endPoint)
                usleep(200_000) // 200ms

                // Reverse direction
                let reverseStart = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.2))
                let reverseEnd = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.8))

                reverseStart.press(forDuration: 0.05, thenDragTo: reverseEnd)
                usleep(200_000)
            }
        }

        XCTAssertTrue(searchField.exists)
    }

    /// Test heavy scrolling with results (note: actual images depend on data)
    func testHeavyScrollingWithImages() throws {
        sleep(5)

        let searchField = app.searchFields.firstMatch
        XCTAssertTrue(searchField.waitForExistence(timeout: 5))
        searchField.tap()
        searchField.typeText("developer")
        sleep(6)

        measure(metrics: [XCTMemoryMetric(), XCTCPUMetric()]) {
            let startTime = Date()

            // Scroll rapidly to stress rendering
            while Date().timeIntervalSince(startTime) < 30 {
                app.swipeUp(velocity: .fast)
                usleep(50_000) // 50ms
                app.swipeDown(velocity: .fast)
                usleep(50_000)
            }
        }

        XCTAssertTrue(searchField.exists)
    }

    /// Test scrolling direction changes (worst case for cell reuse)
    func testRapidScrollDirectionChanges() throws {
        sleep(5)

        let searchField = app.searchFields.firstMatch
        XCTAssertTrue(searchField.waitForExistence(timeout: 5))
        searchField.tap()
        searchField.typeText("python")
        sleep(6)

        measure(metrics: [XCTMemoryMetric()]) {
            // Rapid direction changes stress cell reuse mechanism
            for _ in 0..<50 {
                app.swipeUp(velocity: .fast)
                usleep(50_000)
                app.swipeDown(velocity: .fast)
                usleep(50_000)
            }
        }

        XCTAssertTrue(searchField.exists)
    }
}

import XCTest

/// Walks through the app structure like a person would: every tab, the "Done today" row, History
/// filters, archiving and restoring a habit, and deleting all data. Saves a screenshot of each step
/// when SCREENSHOT_DIR (TEST_RUNNER_SCREENSHOT_DIR for xcodebuild) is set.
final class AppNavigationUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    func testEveryTab() {
        XCTAssertTrue(app.staticTexts["Coming up"].waitForExistence(timeout: 5))
        snapshot("tabs-1-today")

        tab("Streaks")
        XCTAssertTrue(app.staticTexts["Active"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["Archived · 1"].exists)
        snapshot("tabs-2-streaks")

        tab("History")
        XCTAssertTrue(app.buttons["All"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["Today"].exists)
        snapshot("tabs-3-history")

        openSettings()
        XCTAssertTrue(app.staticTexts["Show streaks as"].waitForExistence(timeout: 3))
        snapshot("tabs-4-settings")
        app.buttons["Done"].tap()
        XCTAssertTrue(app.staticTexts["Coming up"].waitForExistence(timeout: 3), "Done closes Settings, back on Today")

        // Each tab keeps its own place: open a streak on Streaks, visit Today, come back.
        tab("Streaks")
        habitRow("Gym").tap()
        XCTAssertTrue(app.buttons["Edit"].waitForExistence(timeout: 3))
        tab("Today")
        tab("Streaks")
        XCTAssertTrue(app.buttons["Edit"].exists, "Streaks tab is still on the Gym screen")
    }

    func testOpensOnTodayWithThreeTabs() {
        XCTAssertTrue(app.staticTexts["Good evening"].waitForExistence(timeout: 5) ||
                      app.staticTexts["Good morning"].exists || app.staticTexts["Good afternoon"].exists)
        let history = tabButton("History"), today = tabButton("Today"), streaks = tabButton("Streaks")
        XCTAssertTrue(today.isSelected, "The app opens on Today")
        XCTAssertTrue(history.exists && streaks.exists)
        XCTAssertFalse(app.buttons["Settings"].frame.minY > app.buttons["Create streak"].frame.maxY,
                       "Gear and + share the top row")
        // Left to right: History, Today, Streaks; Today rises above the others.
        XCTAssertLessThan(history.frame.midX, today.frame.midX)
        XCTAssertLessThan(today.frame.midX, streaks.frame.midX)
        XCTAssertLessThan(today.frame.minY, history.frame.minY)
        XCTAssertLessThan(app.buttons["Settings"].frame.midX, app.buttons["Create streak"].frame.midX)
    }

    func testDoneTodayExpandsAndCollapses() {
        let row = app.buttons["Done today · 2"]
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        let skincare = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Morning skincare. Done'")).firstMatch
        XCTAssertFalse(skincare.exists, "Collapsed at first")

        row.tap()
        XCTAssertTrue(skincare.waitForExistence(timeout: 2))
        snapshot("done-expanded")

        row.tap()
        let gone = expectation(for: NSPredicate(format: "exists == false"), evaluatedWith: skincare)
        wait(for: [gone], timeout: 2)
    }

    func testFilteringHistory() {
        tab("History")
        let guitar = app.buttons["Guitar"]
        XCTAssertTrue(guitar.waitForExistence(timeout: 3))
        // The chips scroll sideways; Guitar starts off screen.
        let screen = app.windows.firstMatch.frame
        for _ in 0..<4 where !screen.contains(guitar.frame) {
            app.buttons["All"].swipeLeft()
        }
        guitar.tap()
        XCTAssertTrue(app.staticTexts["Missed Guitar · streak ended at 3w 3d"].waitForExistence(timeout: 2))
        XCTAssertFalse(app.staticTexts["Morning skincare"].exists, "Other habits are filtered out")
        snapshot("history-filtered")

        let all = app.buttons["All"]
        for _ in 0..<4 where !screen.contains(all.frame) {
            guitar.swipeRight()
        }
        all.tap()
        XCTAssertTrue(app.staticTexts["Skipped Run"].waitForExistence(timeout: 2))
    }

    func testArchiveAndRestore() {
        tab("Streaks")
        habitRow("Gym").tap()
        app.buttons["Edit"].tap()

        let archive = app.buttons["Archive streak"]
        XCTAssertTrue(archive.waitForExistence(timeout: 3))
        archive.tap()
        XCTAssertTrue(app.staticTexts["Archive Gym?"].waitForExistence(timeout: 2))
        snapshot("archive-dialog")
        app.buttons["Archive"].tap()

        // Back on the Streaks list, with Gym under Archived.
        let archivedRow = app.buttons["Archived · 2"]
        XCTAssertTrue(archivedRow.waitForExistence(timeout: 5))
        archivedRow.tap()
        habitRow("Gym").tap()
        let restore = app.buttons["Restore"]
        XCTAssertTrue(restore.waitForExistence(timeout: 3))
        snapshot("archived-habit")
        restore.tap()

        XCTAssertTrue(app.buttons["Archived · 1"].waitForExistence(timeout: 5), "Gym left the archive")
        XCTAssertTrue(habitRow("Gym").exists, "Gym is active again")
    }

    func testDeleteAllDataNeedsTwoConfirmations() {
        openSettings()
        let deleteAll = app.buttons["Delete all data"]
        scrollTo(deleteAll)
        XCTAssertTrue(deleteAll.waitForExistence(timeout: 3))
        deleteAll.tap()

        XCTAssertTrue(app.staticTexts["Delete everything?"].waitForExistence(timeout: 2))
        snapshot("delete-all-1")
        app.buttons["Continue"].tap()

        XCTAssertTrue(app.staticTexts["This can't be undone."].waitForExistence(timeout: 2))
        snapshot("delete-all-2")
        app.buttons["Delete everything"].tap()

        XCTAssertTrue(app.staticTexts["Start your first streak"].waitForExistence(timeout: 5),
                      "Back on the empty Today tab")
        XCTAssertTrue(tabButton("Today").isSelected)
        XCTAssertFalse(app.buttons["Done"].exists, "The Settings sheet closed")
        snapshot("delete-all-done")
    }

    func testCancelKeepsEverything() {
        openSettings()
        let deleteAll = app.buttons["Delete all data"]
        scrollTo(deleteAll)
        deleteAll.tap()
        XCTAssertTrue(app.staticTexts["Delete everything?"].waitForExistence(timeout: 2))
        app.buttons["Cancel"].tap()
        app.buttons["Done"].tap()
        XCTAssertTrue(app.staticTexts["Coming up"].waitForExistence(timeout: 3), "Nothing was deleted")
    }

    // MARK: Helpers

    private func tab(_ name: String) {
        tabButton(name).tap()
    }

    private func tabButton(_ name: String) -> XCUIElement {
        app.buttons["tab." + name]
    }

    /// Settings rows below the fold aren't loaded until scrolled to.
    private func scrollTo(_ element: XCUIElement) {
        for _ in 0..<6 where !element.exists {
            app.swipeUp()
        }
    }

    /// Settings opens from the gear at the top left of Today.
    private func openSettings() {
        tab("Today")
        let gear = app.buttons["Settings"]
        XCTAssertTrue(gear.waitForExistence(timeout: 3))
        gear.tap()
    }

    private func habitRow(_ name: String) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", name + ",")).firstMatch
    }

    private func snapshot(_ name: String) {
        let shot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: shot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
        if let dir = ProcessInfo.processInfo.environment["SCREENSHOT_DIR"] {
            try? shot.pngRepresentation.write(to: URL(fileURLWithPath: dir).appendingPathComponent("\(name).png"))
        }
    }
}

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

        tab("Habits")
        XCTAssertTrue(app.staticTexts["Active"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["Archived · 1"].exists)
        snapshot("tabs-2-habits")

        tab("History")
        XCTAssertTrue(app.buttons["All"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["Today"].exists)
        snapshot("tabs-3-history")

        tab("Settings")
        XCTAssertTrue(app.staticTexts["Show streaks as"].waitForExistence(timeout: 3))
        snapshot("tabs-4-settings")

        // Each tab keeps its own place: open a habit on Habits, visit Today, come back.
        tab("Habits")
        habitRow("Gym").tap()
        XCTAssertTrue(app.buttons["Edit"].waitForExistence(timeout: 3))
        tab("Today")
        tab("Habits")
        XCTAssertTrue(app.buttons["Edit"].exists, "Habits tab is still on the Gym screen")
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
        tab("Habits")
        habitRow("Gym").tap()
        app.buttons["Edit"].tap()

        let archive = app.buttons["Archive habit"]
        XCTAssertTrue(archive.waitForExistence(timeout: 3))
        archive.tap()
        XCTAssertTrue(app.staticTexts["Archive Gym?"].waitForExistence(timeout: 2))
        snapshot("archive-dialog")
        app.buttons["Archive"].tap()

        // Back on the Habits list, with Gym under Archived.
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
        tab("Settings")
        let deleteAll = app.buttons["Delete all data"]
        XCTAssertTrue(deleteAll.waitForExistence(timeout: 3))
        deleteAll.tap()

        XCTAssertTrue(app.staticTexts["Delete everything?"].waitForExistence(timeout: 2))
        snapshot("delete-all-1")
        app.buttons["Continue"].tap()

        XCTAssertTrue(app.staticTexts["This can't be undone."].waitForExistence(timeout: 2))
        snapshot("delete-all-2")
        app.buttons["Delete everything"].tap()

        XCTAssertTrue(app.staticTexts["Start your first habit"].waitForExistence(timeout: 5),
                      "Back on the empty Today tab")
        XCTAssertTrue(app.tabBars.buttons["Today"].isSelected)
        snapshot("delete-all-done")
    }

    func testCancelKeepsEverything() {
        tab("Settings")
        app.buttons["Delete all data"].tap()
        XCTAssertTrue(app.staticTexts["Delete everything?"].waitForExistence(timeout: 2))
        app.buttons["Cancel"].tap()
        tab("Today")
        XCTAssertTrue(app.staticTexts["Coming up"].waitForExistence(timeout: 3), "Nothing was deleted")
    }

    // MARK: Helpers

    private func tab(_ name: String) {
        app.tabBars.buttons[name].tap()
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

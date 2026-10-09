import XCTest

/// Walks through the app structure like a person would: both tabs, History (pushed from Today, from
/// the link or a tapped day), the status line, the greeting name, the "Done today" row, History filters,
/// archiving and restoring a streak, and deleting all data. Saves a screenshot of each step
/// when SCREENSHOT_DIR (TEST_RUNNER_SCREENSHOT_DIR for xcodebuild) is set.
final class AppNavigationUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() {
        continueAfterFailure = false
        app = XCUIApplication()
        // Start every run without a saved name, whatever an earlier run left behind.
        app.launchArguments = ["-settings.name", "", "-resetDayStreak", "YES"]
        app.launch()
        // The sample day streak ended at lunchtime: the app opens on "Your 23-day streak ended" once.
        let letsGo = app.buttons["Let's go"]
        XCTAssertTrue(letsGo.waitForExistence(timeout: 5))
        letsGo.tap()
    }

    func testEveryTab() {
        XCTAssertTrue(app.staticTexts["Coming up"].waitForExistence(timeout: 5))
        snapshot("tabs-1-today")

        tab("Streaks")
        XCTAssertTrue(app.staticTexts["Active"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["Archived · 1"].exists)
        snapshot("tabs-2-streaks")

        tab("Today")
        openHistory()
        XCTAssertTrue(app.buttons["All"].waitForExistence(timeout: 3))
        snapshot("tabs-3-history")
        app.navigationBars.buttons["Today"].tap()

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

    func testOpensOnTodayWithTwoTabs() {
        XCTAssertTrue(greeting("Good evening · ").waitForExistence(timeout: 5))
        let today = tabButton("Today"), streaks = tabButton("Streaks")
        XCTAssertTrue(today.isSelected, "The app opens on Today")
        XCTAssertTrue(streaks.exists)
        XCTAssertFalse(tabButton("History").exists, "History is no longer a tab")
        XCTAssertLessThan(today.frame.midX, streaks.frame.midX, "Today on the left, Streaks on the right")
        XCTAssertEqual(today.frame.minY, streaks.frame.minY, accuracy: 1, "No raised button")
        XCTAssertLessThan(app.buttons["Settings"].frame.midX, app.buttons["Create streak"].frame.midX)
    }

    func testStatusLine() {
        let status = app.descendants(matching: .any)["today.status"]
        XCTAssertTrue(status.waitForExistence(timeout: 5))
        XCTAssertEqual(status.label, "1 of 5 done today · Gym is open now")
        // The hero card comes right after the status line.
        XCTAssertLessThan(status.frame.maxY, app.buttons["Check in"].frame.minY)
        XCTAssertFalse(app.staticTexts["1/5"].exists, "The old summary ring is gone")
    }

    func testHistoryLinkPushesAndHidesTheTabBar() {
        XCTAssertTrue(tabButton("Today").waitForExistence(timeout: 5))
        openHistory()
        XCTAssertTrue(app.navigationBars["History"].waitForExistence(timeout: 3), "Large title \"History\"")
        XCTAssertFalse(tabButton("Today").exists, "The tab bar hides on History")
        snapshot("history-pushed")

        // The standard back button says "Today" and brings the tab bar back.
        let back = app.navigationBars.buttons["Today"]
        XCTAssertTrue(back.exists)
        back.tap()
        XCTAssertTrue(tabButton("Today").waitForExistence(timeout: 3), "The tab bar comes back")
        XCTAssertFalse(app.navigationBars["History"].exists)

        // Swiping from the left edge goes back too.
        openHistory()
        XCTAssertTrue(app.navigationBars["History"].waitForExistence(timeout: 3))
        // The robot's synthetic edge swipe sometimes starts the gesture but lets it snap back, so try a few times.
        let window = app.windows.firstMatch
        for _ in 0..<3 where app.navigationBars["History"].exists {
            window.coordinate(withNormalizedOffset: CGVector(dx: 0, dy: 0.5))
                .press(forDuration: 0.05, thenDragTo: window.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)),
                       withVelocity: .default, thenHoldForDuration: 0)
            _ = tabButton("Today").waitForExistence(timeout: 2)
        }
        XCTAssertFalse(app.navigationBars["History"].exists, "Swiping from the left edge goes back")
        XCTAssertTrue(tabButton("Today").waitForExistence(timeout: 3), "Swiped back to Today, tab bar back")
    }

    func testTappingAPastDayOpensHistoryAtThatDay() {
        // Sample today is Thursday, October 1; Tuesday is September 29.
        let tuesday = app.buttons["weekStrip.2"]
        XCTAssertTrue(tuesday.waitForExistence(timeout: 5))
        XCTAssertEqual(tuesday.label, "Tuesday, all done. Opens history.")
        tuesday.tap()
        let header = app.staticTexts["Tuesday, Sep 29"]
        XCTAssertTrue(header.waitForExistence(timeout: 3))
        Thread.sleep(forTimeInterval: 0.5)
        let bar = app.navigationBars["History"].frame
        XCTAssertLessThan(header.frame.minY - bar.maxY, 120, "Tuesday's header is scrolled to the top")
        XCTAssertFalse(app.staticTexts["Yesterday"].isHittable, "Newer days are above, scrolled out of view")
        snapshot("history-tuesday")

        // Today and future days aren't buttons.
        app.navigationBars.buttons["Today"].tap()
        XCTAssertTrue(tabButton("Today").waitForExistence(timeout: 3))
        XCTAssertFalse(app.buttons["weekStrip.4"].exists, "Thursday (today) isn't tappable")
        XCTAssertFalse(app.buttons["weekStrip.6"].exists, "Saturday isn't tappable")
    }

    func testGreetingUsesTheName() {
        XCTAssertTrue(greeting("Good evening · ").waitForExistence(timeout: 5))
        openSettings()
        let field = app.textFields["Your name"]
        XCTAssertTrue(field.waitForExistence(timeout: 3))
        field.tap()
        field.typeText("  Ajeeth  \n")
        app.navigationBars.buttons["Done"].tap()
        XCTAssertTrue(greeting("Good evening, Ajeeth · ").waitForExistence(timeout: 3))
        snapshot("greeting-named")

        // Clear it again.
        openSettings()
        field.tap()
        field.press(forDuration: 1.0)
        if app.menuItems["Select All"].waitForExistence(timeout: 2) { app.menuItems["Select All"].tap() }
        field.typeText(XCUIKeyboardKey.delete.rawValue)
        app.navigationBars.buttons["Done"].tap()
        XCTAssertTrue(greeting("Good evening · ").waitForExistence(timeout: 3))
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
        openHistory()
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

        XCTAssertTrue(app.staticTexts["Hi! I'm your flame. Create a streak and help me grow."].waitForExistence(timeout: 5),
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

    /// History is pushed from the "History" link on Today.
    private func openHistory() {
        let link = app.buttons["today.history"]
        XCTAssertTrue(link.waitForExistence(timeout: 3))
        link.tap()
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

    /// Today's greeting line, which goes on with the date: "Good evening · Thu, Oct 1".
    private func greeting(_ start: String) -> XCUIElement {
        app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", start)).firstMatch
    }

    func testFlameScreenOpensFromTheHeader() {
        let flame = app.buttons["today.flame"]
        XCTAssertTrue(flame.waitForExistence(timeout: 5))
        XCTAssertEqual(flame.label, "Your flame. Ember form. Sad. 0 day streak.")
        XCTAssertTrue(app.staticTexts["That's okay. One check-in brings me back."].exists)
        flame.tap()
        XCTAssertTrue(app.navigationBars["Your flame"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["1 day to Spark"].exists)
        XCTAssertFalse(tabButton("Today").exists, "The tab bar hides on the Flame screen")
        snapshot("flame-screen")
        app.navigationBars.buttons["Today"].tap()
        XCTAssertTrue(tabButton("Today").waitForExistence(timeout: 3))
    }

    func testCheckInCheersTheFlameUp() {
        app.buttons["Check in"].tap()
        app.buttons["Use sample photo"].tap()
        app.buttons["Submit"].tap()
        let done = app.staticTexts["Gym done"]
        XCTAssertTrue(done.waitForExistence(timeout: 2))
        done.tap()
        // The day had a miss, so only step 1 shows; afterwards the flame isn't sad any more.
        let flame = app.buttons["today.flame"]
        XCTAssertTrue(flame.waitForExistence(timeout: 3))
        let happy = NSPredicate(format: "label == %@", "Your flame. Ember form. Happy. 0 day streak.")
        wait(for: [expectation(for: happy, evaluatedWith: flame)], timeout: 3)
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH 'Next up: Journal at'")).firstMatch.exists)
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

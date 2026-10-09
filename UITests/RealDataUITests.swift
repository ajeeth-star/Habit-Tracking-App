import XCTest

/// The app on real saved data (context.md §11): create a streak, move the pretend clock into its window, check in
/// with the sample photo, and check that the streak, the day streak, and History update — and are still right
/// after the app restarts.
final class RealDataUITests: XCTestCase {
    private var app: XCUIApplication!

    func testCreateCheckInAndRestart() {
        continueAfterFailure = false
        app = XCUIApplication()
        // Erase saved data and pretend it's Monday, October 5, 2026, 6:30 AM.
        app.launchArguments = ["-resetData", "YES", "-pretendNow", "2026-10-05 06:30", "-settings.name", ""]
        app.launch()

        // A fresh install starts empty.
        let create = app.buttons["Create a streak"]
        XCTAssertTrue(create.waitForExistence(timeout: 5), "Empty state")
        create.tap()

        // A streak every day, 7–9 AM (the form's default window), no skips.
        let name = app.textFields["e.g. Gym"]
        XCTAssertTrue(name.waitForExistence(timeout: 3))
        name.tap()
        name.typeText("Pushups\n")
        for day in ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"] {
            app.buttons[day].tap()
        }
        app.buttons["form.save"].tap()
        let card = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Pushups'")).firstMatch
        XCTAssertTrue(card.waitForExistence(timeout: 3), "The new streak is on Today")
        snapshot("1-created")

        // Settings → Developer: +1 hour, into the window.
        app.buttons["Settings"].tap()
        let plusHour = app.buttons["+1 hour"]
        XCTAssertTrue(scrollTo(plusHour), "Developer tools")
        plusHour.tap()
        snapshot("2-pretend-time")
        app.navigationBars.buttons["Done"].tap()

        // Check in.
        let checkIn = app.buttons["Check in"]
        XCTAssertTrue(checkIn.waitForExistence(timeout: 5), "The window is open")
        checkIn.tap()
        app.buttons["Use sample photo"].tap()
        let submit = app.buttons["Submit"]
        XCTAssertTrue(submit.waitForExistence(timeout: 5))
        submit.tap()

        // Step 1, then step 2: it was the only streak today, so the day is complete (0 → 1).
        XCTAssertTrue(app.staticTexts["Pushups done"].waitForExistence(timeout: 3))
        let continueButton = app.buttons["Continue"]
        XCTAssertTrue(continueButton.waitForExistence(timeout: 5), "Day streak step")
        snapshot("3-day-streak")
        continueButton.tap()

        assertCheckedIn()
        snapshot("4-after")

        // Still right after the app restarts (the pretend clock is kept).
        app.terminate()
        app.launchArguments = ["-settings.name", ""]
        app.launch()
        assertCheckedIn()
        snapshot("5-after-restart")
    }

    /// "Fill with sample data" gives a few weeks of history; every main screen shows it.
    func testSampleDataScreens() {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-resetData", "YES", "-pretendNow", "2026-10-08 18:40", "-fillSampleData", "YES",
                               "-settings.name", ""]
        app.launch()

        // Guitar missed a day about a week and a half ago, so the day streak ended once; it's been back since,
        // so the "streak ended" screen doesn't show.
        XCTAssertTrue(app.buttons["today.flame"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.buttons["Let's go"].exists)
        XCTAssertTrue(app.buttons["Check in"].exists, "Gym is open on Thursday at 6:40 PM")
        snapshot("sample-1-today")

        app.buttons["today.history"].tap()
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label CONTAINS 'Guitar'")).firstMatch
            .waitForExistence(timeout: 3))
        snapshot("sample-2-history")
        app.navigationBars.buttons["Today"].tap()

        app.buttons["tab.Streaks"].tap()
        let gym = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Gym'")).firstMatch
        XCTAssertTrue(gym.waitForExistence(timeout: 3))
        snapshot("sample-3-streaks")
        gym.tap()
        XCTAssertTrue(app.buttons["See all"].waitForExistence(timeout: 3), "Gym has photos")
        Thread.sleep(forTimeInterval: 1) // let the thumbnails load
        snapshot("sample-4-task")
        app.buttons["See all"].tap()
        Thread.sleep(forTimeInterval: 1)
        snapshot("sample-5-task-history")
    }

    /// Today shows the day streak at 1, the streak at 1, and History has the check-in.
    private func assertCheckedIn() {
        let flame = app.buttons["today.flame"]
        XCTAssertTrue(flame.waitForExistence(timeout: 5))
        XCTAssertEqual(flame.label, "Your flame. Spark form. Proud. 1 day streak.")
        XCTAssertTrue(app.buttons["Done today · 1"].waitForExistence(timeout: 3))

        app.buttons["tab.Streaks"].tap()
        let row = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Pushups'")).firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 3))
        XCTAssertTrue(row.label.contains("1 day") || row.label.contains("1d"), "Streak is 1: \(row.label)")
        app.buttons["tab.Today"].tap()

        app.buttons["today.history"].tap()
        let entry = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Pushups'")).firstMatch
        XCTAssertTrue(entry.waitForExistence(timeout: 3), "History has the check-in")
        app.navigationBars.buttons["Today"].tap()
    }

    private func scrollTo(_ element: XCUIElement) -> Bool {
        for _ in 0..<8 where !element.isHittable {
            app.swipeUp()
        }
        return element.isHittable
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

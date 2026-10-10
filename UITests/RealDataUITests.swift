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
        // The first streak brings the reminder offer (unless reminders are already allowed on this simulator).
        let notNow = app.buttons["Not now"]
        if notNow.waitForExistence(timeout: 3) { notNow.tap() }
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

    /// The reminder offer appears right after the first streak is created, and only then (context.md §7).
    func testReminderPermissionAfterFirstStreak() {
        continueAfterFailure = false
        app = XCUIApplication()
        // `-askForReminders YES` shows it even if this simulator already allows reminders.
        app.launchArguments = ["-resetData", "YES", "-askForReminders", "YES", "-settings.name", ""]
        app.launch()
        // The empty state is up (so the app has started) and no offer came with it.
        XCTAssertTrue(app.buttons["Create a streak"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.buttons["Turn on reminders"].waitForExistence(timeout: 2), "Not on first launch")

        createStreak("Stretch")
        let turnOn = app.buttons["Turn on reminders"]
        XCTAssertTrue(turnOn.waitForExistence(timeout: 10), "Offered right after the first streak")
        XCTAssertTrue(app.staticTexts[
            "I'll remind you when your windows open, so your streak never sneaks away."].waitForExistence(timeout: 3))
        snapshot("reminders-offer")
        let notNow = app.buttons["Not now"]
        XCTAssertTrue(notNow.waitForExistence(timeout: 3))
        notNow.tap()
        XCTAssertTrue(turnOn.waitForNonExistence(timeout: 5))

        // A second streak doesn't ask again.
        let plus = app.buttons["Create streak"].firstMatch
        XCTAssertTrue(plus.waitForExistence(timeout: 5))
        wait(until: "hittable == true", on: plus)
        plus.tap()
        createStreak("Read", openForm: false)
        XCTAssertFalse(turnOn.waitForExistence(timeout: 4), "Only once")
    }

    private func createStreak(_ name: String, openForm: Bool = true) {
        if openForm {
            let create = app.buttons["Create a streak"]
            XCTAssertTrue(create.waitForExistence(timeout: 5))
            create.tap()
        }
        let field = app.textFields["e.g. Gym"]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.tap()
        XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: 5), "Keyboard is up")
        field.typeText(name)
        wait(until: "value == %@", name, on: field)
        field.typeText("\n")
        let monday = app.buttons["Monday"]
        XCTAssertTrue(monday.waitForExistence(timeout: 3))
        monday.tap()
        wait(until: "selected == true", on: monday)
        let save = app.buttons["form.save"]
        wait(until: "enabled == true", on: save)
        save.tap()
        XCTAssertTrue(field.waitForNonExistence(timeout: 5), "The form closed")
    }

    private func wait(until format: String, _ arguments: CVarArg..., on element: XCUIElement) {
        let predicate = NSPredicate(format: format, argumentArray: arguments)
        wait(for: [expectation(for: predicate, evaluatedWith: element)], timeout: 5)
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

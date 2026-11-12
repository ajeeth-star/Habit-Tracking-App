import XCTest

/// The "fuller app" phase on real saved data (context.md §5): the welcome on a fresh install, creating a streak
/// from a "Popular streaks" chip and the flame cheering it on, the four tabs, and the Progress tab with sample
/// data and empty. Set `TEST_RUNNER_SCREENSHOT_DIR=<folder>` to save a PNG of each step.
final class FullerAppUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() {
        continueAfterFailure = false
        app = XCUIApplication()
    }

    func testWelcomeThenCreateFromAChip() {
        // A fresh install on Monday, October 5, 2026, 6:30 AM. `-askForReminders` makes the reminder offer show.
        app.launchArguments = ["-resetData", "YES", "-pretendNow", "2026-10-05 06:30", "-settings.name", "",
                               "-askForReminders", "YES"]
        app.launch()

        XCTAssertTrue(app.staticTexts["Hi! I'm your flame. I grow every day you show up."].waitForExistence(timeout: 10))
        snapshot("welcome-1")
        let next = app.buttons["welcome.continue"]
        next.tap()
        XCTAssertTrue(app.staticTexts["Pick a time for each habit, then snap a photo during it to prove you did it."]
            .waitForExistence(timeout: 3))
        snapshot("welcome-2")
        next.tap()
        XCTAssertTrue(app.staticTexts["Life happens, so you get a few skips each week. Ready? Let's light this up!"]
            .waitForExistence(timeout: 3))
        XCTAssertEqual(next.label, "Let's go")
        snapshot("welcome-3")
        next.tap()

        // The empty state with the chips.
        let gym = app.buttons["starter.Gym"]
        XCTAssertTrue(gym.waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["starter.Clean up"].exists)
        XCTAssertTrue(app.buttons["Create a streak"].exists)
        snapshot("empty-chips")
        gym.tap()

        // The form is filled in from the chip.
        let name = app.textFields["e.g. Gym"]
        XCTAssertTrue(name.waitForExistence(timeout: 5))
        XCTAssertEqual(name.value as? String, "Gym")
        XCTAssertTrue(app.buttons["Monday"].isSelected)
        XCTAssertFalse(app.buttons["Wednesday"].isSelected)
        snapshot("form-from-chip")
        app.buttons["form.save"].tap()

        // After the reminder offer, the flame cheers the first streak on.
        let notNow = app.buttons["Not now"]
        XCTAssertTrue(notNow.waitForExistence(timeout: 10))
        notNow.tap()
        XCTAssertTrue(app.staticTexts["Our first streak! Check in during its window to light me up."]
            .waitForExistence(timeout: 5))
        snapshot("first-streak")

        // The welcome doesn't come back.
        app.terminate()
        app.launchArguments = ["-settings.name", ""]
        app.launch()
        XCTAssertTrue(app.buttons["today.flame"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.buttons["welcome.skip"].exists)
    }

    func testSkipTheWelcome() {
        app.launchArguments = ["-resetData", "YES", "-settings.name", ""]
        app.launch()
        let skip = app.buttons["welcome.skip"]
        XCTAssertTrue(skip.waitForExistence(timeout: 10))
        skip.tap()
        XCTAssertTrue(app.buttons["starter.Gym"].waitForExistence(timeout: 5))
    }

    func testFourTabsAndProgressWithSampleData() {
        app.launchArguments = ["-resetData", "YES", "-pretendNow", "2026-10-08 18:40", "-fillSampleData", "YES",
                               "-settings.name", "", "-settings.seenWelcome", "YES"]
        app.launch()

        // Today's round buttons.
        XCTAssertTrue(app.buttons["today.flame"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["Settings"].exists)
        XCTAssertTrue(app.buttons["Create streak"].exists)

        // Every tab opens.
        for (tab, check) in [("Streaks", "New streak"), ("Flame", "Your flame"), ("Progress", "This month")] {
            app.buttons["tab." + tab].tap()
            XCTAssertTrue(app.descendants(matching: .any)[check].firstMatch.waitForExistence(timeout: 3), "\(tab) tab")
            XCTAssertTrue(app.buttons["tab." + tab].isSelected)
        }
        snapshot("progress-october")

        // Real numbers from the sample history.
        let month = app.staticTexts["progress.month"]
        XCTAssertEqual(month.label, "October 2026")
        XCTAssertTrue(app.staticTexts["Your streaks"].exists)
        let best = app.descendants(matching: .any)
            .matching(NSPredicate(format: "label CONTAINS 'are your strongest day'")).firstMatch
        XCTAssertTrue(best.exists, "Best day shows after two weeks")
        for _ in 0..<4 where !best.isHittable { app.swipeUp() }
        snapshot("progress-october-bottom")
        for _ in 0..<4 { app.swipeDown() }

        // Month switching: back to September (the first streak's month), and no further.
        app.buttons["progress.previousMonth"].tap()
        XCTAssertEqual(month.label, "September 2026")
        XCTAssertFalse(app.buttons["progress.previousMonth"].isEnabled, "Can't go before the first streak")
        snapshot("progress-september")
        app.buttons["progress.nextMonth"].tap()
        XCTAssertEqual(month.label, "October 2026")
        XCTAssertFalse(app.buttons["progress.nextMonth"].isEnabled, "Can't go past this month")

        // Tapping a past day opens History at that day.
        let day = app.buttons["progress.day.6"]
        XCTAssertTrue(day.exists)
        day.tap()
        XCTAssertTrue(app.navigationBars["History"].waitForExistence(timeout: 3))
        XCTAssertFalse(app.buttons["tab.Progress"].exists, "The tab bar hides on History")
        snapshot("progress-history")
        app.navigationBars.buttons.element(boundBy: 0).tap()
        XCTAssertTrue(app.buttons["tab.Progress"].waitForExistence(timeout: 3))
    }

    func testProgressOnAnEmptyInstall() {
        app.launchArguments = ["-resetData", "YES", "-settings.name", "", "-settings.seenWelcome", "YES"]
        app.launch()
        let tab = app.buttons["tab.Progress"]
        XCTAssertTrue(tab.waitForExistence(timeout: 10))
        tab.tap()
        XCTAssertTrue(app.staticTexts["Check in for a few days and your progress shows up here."]
            .waitForExistence(timeout: 3))
        XCTAssertFalse(app.staticTexts["This month"].exists)
        snapshot("progress-empty")
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

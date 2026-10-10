import XCTest

/// Reminders end to end in the simulator (context.md §7): allow them, see a test reminder arrive, and see the
/// real reminders the app scheduled for the sample streaks. Uses the real time.
/// Set TEST_RUNNER_SCREENSHOT_DIR when running xcodebuild to also save each step as a PNG.
final class RemindersUITests: XCTestCase {
    func testTestReminderArrivesAndRemindersAreScheduled() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-resetData", "YES", "-fillSampleData", "YES", "-settings.name", ""]
        app.launch()
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")

        let settings = app.buttons["Settings"]
        XCTAssertTrue(settings.waitForExistence(timeout: 10))
        settings.tap()
        let sendTest = app.buttons["Send test reminder in 5 seconds"]
        for _ in 0..<8 where !sendTest.isHittable { app.swipeUp() }
        sendTest.tap()

        // The first time (a fresh install), iOS asks for permission. The 5 seconds start once it's answered.
        let alert = springboard.alerts.firstMatch
        if alert.waitForExistence(timeout: 10) {
            let allow = alert.buttons["Allow"]
            XCTAssertTrue(allow.waitForExistence(timeout: 5))
            allow.tap()
            XCTAssertTrue(alert.waitForNonExistence(timeout: 5), "Permission answered")
        }

        // The banner shows even with the app open.
        let banner = springboard.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Reminders are working'"))
            .firstMatch
        XCTAssertTrue(banner.waitForExistence(timeout: 20), "The test reminder arrived")
        snapshot("1-test-reminder")

        // The sample streaks' reminders are scheduled (with the real time, so how many depends on the hour).
        let pending = app.buttons["Show pending reminders"]
        for _ in 0..<4 where !pending.isHittable { app.swipeUp() }
        pending.tap()
        XCTAssertTrue(app.navigationBars["Show pending reminders"].waitForExistence(timeout: 3))
        let anyReminder = app.staticTexts.matching(
            NSPredicate(format: "label ENDSWITH ' is open' OR label CONTAINS ' left' OR label CONTAINS ' closes at '"))
            .firstMatch
        XCTAssertTrue(anyReminder.waitForExistence(timeout: 5), "Reminders are scheduled")
        snapshot("2-pending")
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

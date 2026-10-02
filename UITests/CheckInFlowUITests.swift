import XCTest

/// Taps through a check-in the way a person would: hero card → camera → preview → celebration → Home.
/// Set SCREENSHOT_DIR (or TEST_RUNNER_SCREENSHOT_DIR when running xcodebuild) to also save each step
/// as a PNG.
final class CheckInFlowUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    func testCheckInClosesTheHeroCard() {
        let checkIn = app.buttons["Check in"]
        XCTAssertTrue(checkIn.waitForExistence(timeout: 5), "The hero card's Check in button is on Home")
        snapshot("1-home-before")

        checkIn.tap()
        let samplePhoto = app.buttons["Use sample photo"]
        XCTAssertTrue(samplePhoto.waitForExistence(timeout: 5))
        snapshot("2-camera")

        samplePhoto.tap()
        let submit = app.buttons["Submit"]
        XCTAssertTrue(submit.waitForExistence(timeout: 5))
        snapshot("3-preview")

        submit.tap()
        let dayStreak = app.staticTexts["day streak"]
        XCTAssertTrue(dayStreak.waitForExistence(timeout: 2), "The celebration shows")
        Thread.sleep(forTimeInterval: 0.8) // let the pop and count-up finish
        snapshot("4-celebration")

        // It closes on its own after 2.5 seconds.
        let gone = expectation(for: NSPredicate(format: "exists == false"), evaluatedWith: dayStreak)
        wait(for: [gone], timeout: 5)

        // Back on Today: no hero card left; Gym folded into "Done today" (skincare and the skipped run were already there).
        let doneRow = app.buttons["Done today · 3"]
        XCTAssertTrue(doneRow.waitForExistence(timeout: 3), "Gym moved into the Done today row")
        XCTAssertFalse(app.buttons["Check in"].exists, "No Check in button left on Today")
        Thread.sleep(forTimeInterval: 0.8) // let the card animation settle
        snapshot("5-home-after")

        doneRow.tap()
        let gymDone = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Gym. Done. Checked in'")).firstMatch
        XCTAssertTrue(gymDone.waitForExistence(timeout: 3), "Gym shows as a done card when expanded")
        snapshot("5b-done-expanded")

        // The task screen can't check in again today.
        gymDone.tap()
        let doneToday = app.buttons["Done today"]
        XCTAssertTrue(doneToday.waitForExistence(timeout: 5))
        XCTAssertFalse(doneToday.isEnabled, "Check in stays disabled after checking in")
        snapshot("6-task-screen-after")
    }

    func testTappingClosesTheCelebrationEarly() {
        app.buttons["Check in"].tap()
        app.buttons["Use sample photo"].tap()
        app.buttons["Submit"].tap()
        let dayStreak = app.staticTexts["day streak"]
        XCTAssertTrue(dayStreak.waitForExistence(timeout: 2))

        let tappedAt = Date()
        dayStreak.tap()
        let gone = expectation(for: NSPredicate(format: "exists == false"), evaluatedWith: dayStreak)
        wait(for: [gone], timeout: 2)
        XCTAssertLessThan(Date().timeIntervalSince(tappedAt), 2.0, "Closed by the tap, not the timer")
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

import XCTest

/// The Streaks tab's tile grid and Today's timeline on real saved data ("Fill with sample data"), at three times
/// of a Thursday (Gym 6–8 PM, Morning skincare 7–9 AM, Journal 9–10 PM are scheduled; Guitar isn't). Set
/// `TEST_RUNNER_SCREENSHOT_DIR=<folder>` to save a PNG of each step.
final class StreaksAndTimelineUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() {
        continueAfterFailure = false
        app = XCUIApplication()
    }

    private func launch(at time: String) {
        app.launchArguments = ["-resetData", "YES", "-pretendNow", "2026-10-08 \(time)", "-fillSampleData", "YES",
                               "-settings.name", "", "-settings.seenWelcome", "YES"]
        app.launch()
        XCTAssertTrue(app.buttons["today.flame"].waitForExistence(timeout: 10))
    }

    private func card(_ prefix: String) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", prefix)).firstMatch
    }

    private var nowMarker: XCUIElement { app.otherElements["timeline.now"].firstMatch }

    func testMorningEverythingStillToCome() {
        launch(at: "06:30")
        let skincare = card("Morning skincare. Opens")
        XCTAssertTrue(skincare.waitForExistence(timeout: 3))
        XCTAssertTrue(nowMarker.exists)
        XCTAssertLessThan(nowMarker.frame.minY, skincare.frame.minY, "Now is above everything first thing")
        snapshot("timeline-morning")
    }

    func testDuringAWindowGymIsTheHero() {
        launch(at: "18:40")
        XCTAssertTrue(app.buttons["Check in"].waitForExistence(timeout: 3), "Gym is the hero card")
        let journal = card("Journal. Opens")
        for _ in 0..<4 where !journal.isHittable { app.swipeUp() }
        XCTAssertLessThan(nowMarker.frame.minY, journal.frame.minY)
        XCTAssertFalse(app.buttons["Done today · 1"].exists)
        snapshot("timeline-window")
    }

    func testAfterEverythingIsDone() {
        launch(at: "22:30")
        let journal = card("Journal. Done")
        for _ in 0..<4 where !nowMarker.isHittable { app.swipeUp() }
        XCTAssertTrue(journal.exists)
        XCTAssertGreaterThan(nowMarker.frame.minY, journal.frame.minY, "Now is below everything late at night")
        snapshot("timeline-done")
    }

    func testTileGridAndNewStreakTile() {
        launch(at: "18:40")
        app.buttons["tab.Streaks"].tap()
        let summary = app.staticTexts["streaks.summary"]
        XCTAssertTrue(summary.waitForExistence(timeout: 3))
        XCTAssertTrue(summary.label.hasPrefix("4 active · "), summary.label)

        // Highest streak first, then the New streak tile last.
        let gym = app.buttons["tile.Gym"]
        let newTile = app.buttons["tile.new"]
        XCTAssertTrue(gym.exists)
        XCTAssertTrue(gym.label.contains("Open now"), gym.label)
        for _ in 0..<4 where !newTile.isHittable { app.swipeUp() }
        snapshot("tiles-bottom")
        for name in ["Gym", "Morning skincare", "Guitar", "Journal"] {
            XCTAssertLessThan(app.buttons["tile." + name].frame.minY, newTile.frame.maxY - 1, name)
        }

        // The New streak tile opens the create form; a brand-new streak is a dormant tile at 0.
        newTile.tap()
        let name = app.textFields["e.g. Gym"]
        XCTAssertTrue(name.waitForExistence(timeout: 5))
        name.tap()
        name.typeText("Stretch\n")
        app.buttons["Sunday"].tap()
        app.buttons["form.save"].tap()
        let stretch = app.buttons["tile.Stretch"]
        XCTAssertTrue(stretch.waitForExistence(timeout: 5))
        XCTAssertTrue(stretch.label.hasPrefix("Stretch, 0"), stretch.label)
        for _ in 0..<4 where !stretch.isHittable { app.swipeUp() }
        snapshot("tiles-dormant")
        stretch.tap()
        XCTAssertTrue(app.buttons["Edit"].waitForExistence(timeout: 3), "A tile opens its streak")
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

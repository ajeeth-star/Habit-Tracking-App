import XCTest

/// The full 3-step celebration (design.md §4.8), from the Design Gallery's "completes the day, new form"
/// check-in: Gym is the last thing left today and the day streak goes 13 → 14, so the flame becomes a Blaze.
/// Set TEST_RUNNER_SCREENSHOT_DIR when running xcodebuild to also save each step as a PNG.
final class FlameCelebrationUITests: XCTestCase {
    func testThreeStepCelebration() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-galleryEntry", "flow.newForm"]
        app.launch()

        app.buttons["Use sample photo"].tap()
        let submit = app.buttons["Submit"]
        XCTAssertTrue(submit.waitForExistence(timeout: 5))
        submit.tap()

        // Step 1: the check-in. More steps follow, so it moves on by itself after 2 seconds.
        XCTAssertTrue(app.staticTexts["Gym done"].waitForExistence(timeout: 2))
        Thread.sleep(forTimeInterval: 0.8)
        snapshot("1-check-in")

        // Step 2: the day streak.
        let toBonfire = element(app, containing: "16 days to Bonfire")
        XCTAssertTrue(toBonfire.waitForExistence(timeout: 4), "Moved on to the day streak step")
        Thread.sleep(forTimeInterval: 1)
        snapshot("2-day-streak")
        app.buttons["Continue"].tap()

        // Step 3: the new form.
        XCTAssertTrue(element(app, containing: "Your flame became a Blaze!").waitForExistence(timeout: 4))
        Thread.sleep(forTimeInterval: 1.5)
        snapshot("3-new-form")
        app.buttons["Continue"].tap()
    }

    /// Celebration steps read as one VoiceOver element, so match any element whose label contains the text.
    private func element(_ app: XCUIApplication, containing text: String) -> XCUIElement {
        app.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS %@", text)).firstMatch
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

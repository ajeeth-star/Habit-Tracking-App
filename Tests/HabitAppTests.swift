import Testing
@testable import HabitApp

/// Proves the test target builds against the app and runs.
struct HabitAppTests {
    @Test func testingWorks() {
        #expect(1 + 1 == 2)
    }
}

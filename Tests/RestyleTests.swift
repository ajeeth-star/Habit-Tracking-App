import Testing
import UIKit
@testable import HabitApp

/// The playful restyle's building blocks (design.md §1): the bundled font, the sounds, and dark mode.
struct RestyleTests {
    @Test("Every Nunito weight the app uses is available", arguments: [
        Nunito.semiBoldName, Nunito.boldName, Nunito.extraBoldName, Nunito.blackName,
    ])
    func nunitoWeight(name: String) {
        let font = UIFont(name: name, size: 17)
        #expect(font != nil)
        #expect(font?.familyName == "Nunito")
    }

    @Test func soundsAreBundled() {
        #expect(SoundPlayer.allFilesPresent)
        #expect(SoundPlayer.Sound.allCases.count == 4)
    }

    @Test func appIsAlwaysDark() {
        #expect(Bundle.main.object(forInfoDictionaryKey: "UIUserInterfaceStyle") as? String == "Dark")
    }

    @Test func eightBrightStreakColors() {
        #expect(StreakColor.allCases.map(\.rawValue) == ["coral", "orange", "yellow", "green", "teal", "blue", "purple", "pink"])
    }
}

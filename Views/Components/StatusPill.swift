import SwiftUI

/// A task's status (design.md §2): no box, just bold ALL CAPS text in the status color —
/// "OPEN NOW", "DONE 7:42 AM", "OPENS 9:00 PM", "SKIPPED", "MISSED".
struct StatusPill: View {
    enum Kind: Hashable {
        case open
        /// Carries the formatted check-in time, e.g. "7:42 AM" (nil when it isn't known).
        case done(String?)
        /// Carries the formatted opening time, e.g. "9:00 PM".
        case upcoming(String)
        case skipped
        case missed
    }

    let kind: Kind

    var body: some View {
        Text(text)
            .font(Font.app.pill)
            .monospacedDigit()
            .capsLabel()
            .foregroundStyle(color)
            .fixedSize()
            .accessibilityLabel(text)
    }

    /// The same look as `Text`, so a meta line can follow it on one line: "OPENS 9:00 PM · 1 skip left".
    var styledText: Text {
        Text(text.uppercased())
            .font(Font.app.pill)
            .tracking(Typography.capsTracking)
            .foregroundStyle(color)
    }

    /// Sentence case, as VoiceOver reads it: "Done 7:42 AM".
    var text: String {
        switch kind {
        case .open: Strings.Pill.open
        case .done(let time?): Strings.Pill.doneAt(time)
        case .done(nil): Strings.Pill.done
        case .upcoming(let time): Strings.Pill.opens(time)
        case .skipped: Strings.Pill.skipped
        case .missed: Strings.Pill.missed
        }
    }

    private var color: Color {
        switch kind {
        case .open: Color.app.flame
        case .done: Color.app.success
        case .upcoming: Color.app.textTertiary
        case .skipped: Color.app.textSecondary
        case .missed: Color.app.danger
        }
    }
}

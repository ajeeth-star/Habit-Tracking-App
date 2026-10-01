import SwiftUI

/// The small status capsule on the right of a task card.
struct StatusPill: View {
    enum Kind: Hashable {
        case open
        case done
        /// Carries the formatted opening time, e.g. "9:00 PM".
        case upcoming(String)
        case skipped
        case missed
    }

    let kind: Kind

    var body: some View {
        HStack(spacing: Spacing.xxs) {
            if kind == .done {
                Image(systemName: "checkmark")
            }
            Text(text)
                .monospacedDigit()
        }
        .fixedSize()
        .font(Font.app.pill)
        .foregroundStyle(foreground)
        .padding(.horizontal, Sizes.pillHorizontalPadding)
        .padding(.vertical, Sizes.pillVerticalPadding)
        .background(background, in: Capsule())
    }

    var text: String {
        switch kind {
        case .open: Strings.Pill.open
        case .done: Strings.Pill.done
        case .upcoming(let time): Strings.Pill.opens(time)
        case .skipped: Strings.Pill.skipped
        case .missed: Strings.Pill.missed
        }
    }

    private var foreground: Color {
        switch kind {
        case .open: Color.app.accentText
        case .done: Color.app.success
        case .upcoming, .skipped: Color.app.textSecondary
        case .missed: Color.app.danger
        }
    }

    private var background: Color {
        switch kind {
        case .open: Color.app.accentSoft
        case .done: Color.app.successSoft
        case .upcoming, .skipped: Color.app.surfaceMuted
        case .missed: Color.app.dangerSoft
        }
    }
}

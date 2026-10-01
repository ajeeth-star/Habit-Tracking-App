import SwiftUI

/// A round, tappable day letter for picking which days a task runs.
struct DayChip: View {
    let day: Weekday
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(Formatters.current.weekdayLetter(day))
                .font(Font.app.subhead)
                .foregroundStyle(isSelected ? Color.app.onAccent : Color.app.textSecondary)
                // The chip has a fixed size, so the letter stops growing past this text size.
                .dynamicTypeSize(...DynamicTypeSize.xLarge)
                .frame(width: Sizes.dayChip, height: Sizes.dayChip)
                .background {
                    if isSelected {
                        Circle().fill(Color.app.accent)
                    } else {
                        Circle().strokeBorder(Color.app.separator, lineWidth: Sizes.hairline)
                    }
                }
                .frame(minWidth: Sizes.tapTarget, minHeight: Sizes.tapTarget)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        // "T" and "S" repeat, so VoiceOver reads the full name.
        .accessibilityLabel(Formatters.current.weekdayName(day))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

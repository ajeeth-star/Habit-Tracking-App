import SwiftUI

/// A row that shows or hides a group: "Done today · 2" or "Archived · 1", with a chevron.
struct DisclosureRow: View {
    let label: String
    let count: Int
    @Binding var isExpanded: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button {
            withAnimation(reduceMotion ? nil : Motion.standard) { isExpanded.toggle() }
        } label: {
            HStack {
                Text(Strings.counted(label, count))
                    .font(Font.app.meta)
                    .monospacedDigit()
                    .contentTransition(.numericText())
                    .foregroundStyle(Color.app.textSecondary)
                Spacer()
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(Font.app.meta)
                    .foregroundStyle(Color.app.textSecondary)
            }
            .frame(minHeight: Sizes.tapTarget)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityValue(isExpanded ? Strings.expanded : Strings.collapsed)
    }
}

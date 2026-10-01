import SwiftUI

/// A 56pt ring showing how much of today is done, with the count ("2/3") or a checkmark in the middle.
struct ProgressRing: View {
    let done: Int
    let total: Int

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var progress: Double { total == 0 ? 0 : Double(done) / Double(total) }
    private var isComplete: Bool { total > 0 && done == total }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.app.surfaceMuted, lineWidth: Sizes.progressRingLine)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(Color.app.accent, style: StrokeStyle(lineWidth: Sizes.progressRingLine, lineCap: .round))
                .rotationEffect(.degrees(-90)) // start at the top
            if isComplete {
                Image(systemName: "checkmark")
                    .font(Font.app.ringCount)
                    .foregroundStyle(Color.app.accentText)
                    .transition(.scale.combined(with: .opacity))
            } else {
                Text(Strings.Summary.ringCount(done, total))
                    .font(Font.app.ringCount)
                    .foregroundStyle(Color.app.textPrimary)
                    .contentTransition(.numericText(value: Double(done)))
            }
        }
        // The ring has a fixed size, so what's inside stops growing past this text size.
        .dynamicTypeSize(...DynamicTypeSize.xxLarge)
        .padding(Sizes.progressRingLine / 2) // keep the stroke inside the 56pt frame
        .frame(width: Sizes.progressRing, height: Sizes.progressRing)
        .animation(reduceMotion ? nil : Motion.settle, value: done)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Strings.Summary.doneToday(done, total))
    }
}

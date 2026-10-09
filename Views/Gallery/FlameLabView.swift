#if DEBUG
import SwiftUI

/// Design Gallery → Flame → Flame Lab (design.md §4.16): try every form and mood on the live flame, play
/// each celebration step, the evolution to the next form, and the "streak ended" screen, and see every
/// form × mood at once.
struct FlameLabView: View {
    @State private var form = FlameForm.blaze
    @State private var mood = FlameMood.happy
    @State private var playing: Play?

    private enum Play: String, Identifiable {
        case checkIn, dayStreak, revival, newForm, full, ended
        var id: String { rawValue }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.md) {
                FlameCharacterView(form: form, mood: mood, size: Sizes.flameScreen, days: form.minimumDays)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.xl)

                label("Form")
                chips(FlameForm.allCases, selection: $form) { Strings.Flame.formName($0) }
                label("Mood")
                chips(FlameMood.allCases, selection: $mood) { Strings.Flame.moodName($0) }

                label("Play")
                VStack(spacing: Spacing.xs) {
                    ChunkyButton(style: .secondary, "Step 1 · check-in only") { playing = .checkIn }
                    ChunkyButton(style: .secondary, "Step 2 · day streak 22 → 23") { playing = .dayStreak }
                    ChunkyButton(style: .secondary, "Step 2 · revival 0 → 1") { playing = .revival }
                    if let next = form.next {
                        ChunkyButton(style: .secondary,
                                     "Step 3 · \(Strings.Flame.formName(form)) → \(Strings.Flame.formName(next))") {
                            playing = .newForm
                        }
                    }
                    ChunkyButton(style: .secondary, "All 3 steps · 13 → 14 (Blaze)") { playing = .full }
                    ChunkyButton(style: .secondary, "Streak ended screen") { playing = .ended }
                }

                label("Every form × mood")
                FlameGrid()
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.bottom, Spacing.xxxl)
        }
        .background(Color.app.background)
        .navigationTitle("Flame Lab")
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(item: $playing) { play in
            content(play) { playing = nil }
        }
    }

    @ViewBuilder private func content(_ play: Play, close: @escaping () -> Void) -> some View {
        let gym = SampleData.celebrationMidWeek
        switch play {
        case .checkIn:
            StreakCelebrationView(result: gym, form: form, steps: [.checkIn], onDone: close)
        case .dayStreak:
            StreakCelebrationView(result: gym, dayChange: DayStreakChange(from: 22, to: 23, isRevival: false),
                                  steps: [.dayStreak], onDone: close)
        case .revival:
            StreakCelebrationView(result: gym, dayChange: DayStreakChange(from: 0, to: 1, isRevival: true),
                                  steps: [.dayStreak], onDone: close)
        case .newForm:
            StreakCelebrationView(result: gym, steps: [.newForm(from: form, to: form.next ?? form)], onDone: close)
        case .full:
            StreakCelebrationView(result: gym, dayChange: DayStreakChange(from: 13, to: 14, isRevival: false),
                                  onDone: close)
        case .ended:
            DayStreakEndedView(length: 23, longest: 30, bestForm: .bonfire, onClose: close)
        }
    }

    private func label(_ text: String) -> some View {
        Text(text)
            .font(Font.app.sectionHeader)
            .foregroundStyle(Color.app.textTertiary)
    }

    private func chips<Item: Hashable & Identifiable>(_ items: [Item], selection: Binding<Item>,
                                                      title: @escaping (Item) -> String) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.xs) {
                ForEach(items) { item in
                    FilterChip(title: title(item), isSelected: selection.wrappedValue == item) {
                        selection.wrappedValue = item
                    }
                }
            }
            .padding(.horizontal, Spacing.lg)
        }
        .padding(.horizontal, -Spacing.lg)
    }
}

/// Still copies of every form × mood: a row per form, a column per mood.
struct FlameGrid: View {
    var size = Sizes.flameLabGrid

    var body: some View {
        let moods = FlameMood.allCases
        Grid(horizontalSpacing: Spacing.xxs, verticalSpacing: Spacing.sm) {
            GridRow {
                Color.clear.gridCellUnsizedAxes([.horizontal, .vertical])
                ForEach(moods) { mood in
                    Text(Strings.Flame.moodName(mood))
                        .font(Font.app.caption)
                        .foregroundStyle(Color.app.textTertiary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
            }
            ForEach(FlameForm.allCases) { form in
                GridRow {
                    Text(Strings.Flame.formName(form))
                        .font(Font.app.caption)
                        .foregroundStyle(Color.app.textSecondary)
                        .gridColumnAlignment(.leading)
                    ForEach(moods) { mood in
                        FlameCharacterView(form: form, mood: mood, size: size, animated: false)
                    }
                }
            }
        }
    }
}
#endif

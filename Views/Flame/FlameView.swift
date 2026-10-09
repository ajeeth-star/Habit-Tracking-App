import SwiftUI

/// The Flame screen (design.md §4.14), pushed from Today's header: the flame up close, how far it is to
/// the next form, every form on a path, and the longest day streak and best form.
struct FlameView: View {
    @Environment(TaskStore.self) private var store
    @Environment(DayStreakStore.self) private var dayStreak

    private let format = Formatters.current

    var body: some View {
        let state = dayStreak.state
        let now = store.now()
        let mood = dayStreak.status(tasks: store.tasks, now: now).mood
        ScrollView {
            VStack(spacing: 0) {
                FlameCharacterView(form: state.form, mood: mood, size: Sizes.flameScreen, days: state.current)
                    .padding(.top, Spacing.xl)

                Text(Strings.Flame.formName(state.form))
                    .font(Font.app.screenTitle)
                    .foregroundStyle(Color.app.textPrimary)
                    .padding(.top, Spacing.md)
                Text(format.dayStreak(state.current))
                    .font(Font.app.subhead)
                    .foregroundStyle(Color.app.textSecondary)

                VStack(spacing: Spacing.xs) {
                    ProgressBar(progress: FlameForm.progress(days: state.current))
                    Text(format.toNextForm(days: state.current))
                        .font(Font.app.meta)
                        .foregroundStyle(Color.app.textSecondary)
                }
                .accessibilityElement(children: .combine)
                .padding(.top, Spacing.lg)

                FormPath(current: state.form)
                    .padding(.top, Spacing.xl)

                HStack(spacing: Spacing.sm) {
                    stat(Strings.Flame.longest, Strings.Streak.days(state.longest))
                    stat(Strings.Flame.bestForm, Strings.Flame.formName(state.bestForm))
                }
                .padding(.top, Spacing.xl)
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.bottom, Spacing.xxxl)
        }
        .background(Color.app.background)
        .navigationTitle(Strings.Flame.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
    }

    private func stat(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            Text(label)
                .font(Font.app.caption)
                .foregroundStyle(Color.app.textSecondary)
            Text(value)
                .font(Font.app.statValue)
                .foregroundStyle(Color.app.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.md)
        .chunkyCard()
        .accessibilityElement(children: .combine)
    }
}

/// All 8 forms in a row: reached ones in color, the current one ringed, locked ones as silhouettes.
private struct FormPath: View {
    let current: FlameForm

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(Strings.Flame.forms)
                .font(Font.app.sectionHeader)
                .foregroundStyle(Color.app.textTertiary)
                .accessibilityAddTraits(.isHeader)
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: Spacing.sm) {
                        ForEach(FlameForm.allCases) { form in
                            cell(form).id(form)
                        }
                    }
                    .padding(.vertical, Spacing.xs)
                    .padding(.horizontal, Spacing.lg)
                }
                .padding(.horizontal, -Spacing.lg)
                .onAppear { proxy.scrollTo(current, anchor: .center) }
            }
        }
    }

    private func cell(_ form: FlameForm) -> some View {
        let locked = form > current
        return VStack(spacing: Spacing.xxs) {
            ZStack {
                Circle()
                    .fill(Color.app.surface)
                if form == current {
                    Circle().strokeBorder(Color.app.flame, lineWidth: Sizes.formRing)
                }
                if locked {
                    // A flat silhouette: the flame's shape filled with one color.
                    Color.app.surfaceMuted
                        .mask(FlameCharacterView(form: form, size: Sizes.flamePath, animated: false))
                        .accessibilityHidden(true)
                        .overlay {
                            Image(systemName: "lock.fill")
                                .font(Font.app.settingsIcon)
                                .foregroundStyle(Color.app.textTertiary)
                        }
                } else {
                    FlameCharacterView(form: form, size: Sizes.flamePath, animated: false)
                }
            }
            .frame(width: Sizes.formCell, height: Sizes.formCell)
            Text(Strings.Flame.formName(form))
                .font(Font.app.caption)
                .fontWeight(.bold)
                .foregroundStyle(locked ? Color.app.textTertiary : Color.app.textPrimary)
            Text(Formatters.current.formRequirement(form))
                .font(Font.app.caption)
                .monospacedDigit()
                .foregroundStyle(Color.app.textTertiary)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel([Strings.Flame.formName(form), Formatters.current.formRequirement(form),
                             locked ? Strings.Flame.locked : (form == current ? Strings.Flame.current : nil)]
            .compactMap { $0 }.joined(separator: ", "))
    }
}

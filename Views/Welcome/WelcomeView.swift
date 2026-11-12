import SwiftUI

/// The welcome on a fresh install (design.md §4.20): three short pages where the flame introduces itself, how
/// check-ins work, and skips. "Skip" or the last page's "Let's go" finishes it.
struct WelcomeView: View {
    let onFinish: () -> Void

    @State private var page: Int

    /// `startPage` lets the Design Gallery open a later page.
    init(startPage: Int = 0, onFinish: @escaping () -> Void) {
        _page = State(initialValue: startPage)
        self.onFinish = onFinish
    }
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private struct Page {
        var form: FlameForm
        var mood: FlameMood
        var text: String
    }

    private let pages = [
        Page(form: .ember, mood: .happy, text: Strings.Welcome.hello),
        Page(form: .flame, mood: .cheering, text: Strings.Welcome.howItWorks),
        Page(form: .blaze, mood: .proud, text: Strings.Welcome.skips),
    ]

    private var isLast: Bool { page == pages.count - 1 }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button(action: onFinish) {
                    Text(Strings.Welcome.skip)
                        .font(Font.app.body)
                        .foregroundStyle(Color.app.textSecondary)
                        .frame(minWidth: Sizes.tapTarget, minHeight: Sizes.tapTarget)
                        .contentShape(Rectangle())
                }
                .accessibilityIdentifier("welcome.skip")
            }
            .padding(.horizontal, Spacing.lg)

            TabView(selection: $page) {
                ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                    pageView(page)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(reduceMotion ? nil : Motion.welcomeFade, value: page)

            VStack(spacing: Spacing.md) {
                ChunkyButton(isLast ? Strings.Welcome.letsGo : Strings.Welcome.continue) {
                    if isLast {
                        onFinish()
                    } else {
                        withAnimation(reduceMotion ? nil : Motion.welcomeFade) { page += 1 }
                    }
                }
                .accessibilityIdentifier("welcome.continue")
                PageDots(count: pages.count, current: page)
                    .animation(reduceMotion ? nil : Motion.standard, value: page)
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.bottom, Spacing.lg)
        }
        .background(Color.app.background)
    }

    private func pageView(_ page: Page) -> some View {
        VStack(spacing: Spacing.md) {
            Spacer(minLength: 0)
            FlameCharacterView(form: page.form, mood: page.mood, size: Sizes.flameWelcome)
            SpeechBubble(text: page.text, centered: true)
                .accessibilityIdentifier("welcome.bubble")
            Spacer(minLength: 0)
        }
        .padding(.horizontal, Spacing.lg)
    }
}

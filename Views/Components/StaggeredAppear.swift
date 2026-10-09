import SwiftUI

/// Cards slide up 12pt and fade in the first time a screen appears, 40ms apart (design.md §1.6).
/// Not repeated when you come back to a screen that's already been shown. Off with Reduce Motion.
struct StaggeredAppear: ViewModifier {
    let index: Int
    @State private var shown = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .opacity(shown || reduceMotion ? 1 : 0)
            .offset(y: shown || reduceMotion ? 0 : Motion.slideInDistance)
            .onAppear {
                guard !shown else { return }
                if reduceMotion {
                    shown = true
                } else {
                    let delay = Double(min(index, Motion.slideInMaxStaggered)) * Motion.slideInStagger
                    withAnimation(Motion.slideIn.delay(delay)) { shown = true }
                }
            }
    }
}

extension View {
    /// Slide up and fade in on first appearance; `index` sets the stagger.
    func appearSlideIn(index: Int) -> some View {
        modifier(StaggeredAppear(index: index))
    }

    /// A soft haptic when `value` changes (toggles and pickers), unless Settings → Vibrations is off.
    func softHaptic<V: Equatable>(trigger value: V) -> some View {
        modifier(SoftHaptic(value: value))
    }
}

private struct SoftHaptic<V: Equatable>: ViewModifier {
    let value: V
    @Environment(AppSettings.self) private var settings

    func body(content: Content) -> some View {
        content.sensoryFeedback(trigger: value) { _, _ in
            settings.vibrations ? .impact(flexibility: .soft) : nil
        }
    }
}

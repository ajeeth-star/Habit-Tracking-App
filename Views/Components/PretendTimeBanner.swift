#if DEBUG
import SwiftUI
import UIKit

/// DEBUG only (context.md §11): while the pretend clock is on, a bright yellow strip at the top of every screen,
/// "Pretend time: Thu 8:01 PM · TAP TO RESET". Tapping it goes back to real time.
struct PretendTimeBanner: View {
    @Environment(AppClock.self) private var clock

    var body: some View {
        TimelineView(.everyMinute) { context in
            Button {
                clock.resetToRealTime()
            } label: {
                Text(Strings.Developer.banner(Formatters.current.bannerTime(clock.now(at: context.date))))
                    .font(Font.app.pill)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .foregroundStyle(Color.app.textOnBright)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.app.gold)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("pretendTimeBanner")
        }
    }
}

/// Puts the banner in a window of its own, above sheets and full-screen covers, inside the status bar area so
/// it never covers the app's own buttons. Hidden whenever the clock is real.
@MainActor
enum PretendTimeBannerWindow {
    static let height: CGFloat = 20
    private static var window: UIWindow?

    static func install(clock: AppClock) {
        guard window == nil,
              let scene = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first
        else { return }
        let banner = UIWindow(windowScene: scene)
        banner.windowLevel = .statusBar + 1
        let host = UIHostingController(rootView: PretendTimeBanner().environment(clock))
        host.view.backgroundColor = .clear
        // No safe-area padding of its own: it sits exactly where it's put.
        host.safeAreaRegions = []
        banner.rootViewController = host
        // Just below the status bar and Dynamic Island, above the app's own buttons.
        let statusBar = scene.statusBarManager?.statusBarFrame ?? .zero
        banner.frame = CGRect(x: 0, y: max(0, statusBar.maxY - 4), width: scene.screen.bounds.width,
                              height: height)
        window = banner
        update(clock: clock)
    }

    /// Shows the banner while pretending, hides it otherwise; keeps watching the clock.
    private static func update(clock: AppClock) {
        window?.isHidden = !withObservationTracking {
            clock.isPretending
        } onChange: {
            Task { @MainActor in update(clock: clock) }
        }
    }
}
#endif

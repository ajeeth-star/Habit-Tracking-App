import SwiftUI

/// The "Use your last skip?" dialog (design.md §4.5): an `AppDialog` with "Keep my skip" as the
/// highlighted choice and a warning haptic on "Use skip".
struct SkipConfirmationView: View {
    let prompt: SkipPrompt
    /// Called after "Use skip": saves the skip.
    var onUseSkip: () -> Void = {}

    private let format = Formatters.current

    var body: some View {
        AppDialog(
            title: format.skipTitle(prompt),
            message: format.skipBody(prompt),
            safeTitle: Strings.Skip.keep,
            actionTitle: Strings.Skip.use,
            actionStyle: .destructive,
            actionHaptic: .warning,
            actionSound: .skip,
            onAction: onUseSkip)
    }
}

import SwiftUI

/// Camera → preview → success, presented full screen from a task's "Check in" button.
/// Nothing is saved in this phase; the success screen shows what the result would look like.
struct CheckInFlowView: View {
    let task: TaskSnapshot

    @Environment(\.dismiss) private var dismiss
    @State private var step = Step.camera

    private enum Step { case camera, preview, success }

    var body: some View {
        switch step {
        case .camera:
            CameraView(
                taskName: task.name,
                closesAt: task.window.end,
                onClose: { dismiss() },
                onCapture: { step = .preview })
        case .preview:
            PhotoPreviewView(
                taskName: task.name,
                closesAt: task.window.end,
                onRetake: { step = .camera },
                onSubmit: { step = .success })
        case .success:
            CheckInSuccessView(result: sampleResult, onDone: { dismiss() })
        }
    }

    /// What checking in would show. Placeholder until streak rules exist.
    private var sampleResult: CheckInResult {
        var streak = task.streak
        streak.days += 1
        streak.totalCheckIns += 1
        let refunded = task.today == .scheduled(.open, .skipped)
        return CheckInResult(
            taskName: task.name,
            streak: streak,
            remainingThisWeek: task.scheduledDaysAfterToday.count,
            refundedSkipsLeft: refunded ? task.skipsLeft + 1 : nil)
    }
}

import SwiftUI

/// Placeholder home screen. Replaced by the real Today / Not today hub in a later phase.
struct TodayView: View {
    var body: some View {
        NavigationStack {
            Text("No tasks yet.")
                .foregroundStyle(.secondary)
                .navigationTitle("Today")
        }
    }
}

#Preview {
    TodayView()
}

import SwiftUI

@main
struct HabitApp: App {
    @State private var streakDisplay = StreakDisplaySettings()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(streakDisplay)
        }
    }
}

/// Home, filled with sample data for now. In DEBUG builds, Home's paintbrush opens the Design Gallery.
struct RootView: View {
    #if DEBUG
    /// `-galleryEntry <id>` on launch opens that gallery entry directly (used to screenshot every state).
    private let launchEntryID = UserDefaults.standard.string(forKey: "galleryEntry")
    @State private var showingGallery = UserDefaults.standard.string(forKey: "galleryEntry") != nil
    #endif

    var body: some View {
        NavigationStack {
            #if DEBUG
            HomeView(tasks: SampleData.allTasks, now: SampleData.today, onOpenGallery: { showingGallery = true })
            #else
            HomeView(tasks: SampleData.allTasks, now: SampleData.today)
            #endif
        }
        #if DEBUG
        .fullScreenCover(isPresented: $showingGallery) {
            DesignGalleryView(initialEntryID: launchEntryID)
        }
        #endif
    }
}

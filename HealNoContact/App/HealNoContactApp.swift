import SwiftUI
import SwiftData

@main
struct HealNoContactApp: App {
    @State private var appState = AppState()

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            UserProfile.self,
            JournalEntry.self,
            MoodEntry.self,
            Milestone.self,
            EmergencyLog.self,
            LetterEntry.self
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            groupContainer: .automatic
        )
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appState)
                .tint(Color.theme.accent)
                .preferredColorScheme(.dark)
        }
        .modelContainer(sharedModelContainer)
    }
}

struct RootView: View {
    @Environment(AppState.self) private var appState
    @Query private var profiles: [UserProfile]

    var body: some View {
        Group {
            if profiles.isEmpty || !(profiles.first?.hasCompletedOnboarding ?? false) {
                OnboardingContainerView()
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            } else {
                MainTabBarView()
                    .transition(.opacity.combined(with: .scale(scale: 1.02)))
            }
        }
        .animation(.easeInOut(duration: 0.5), value: profiles.first?.hasCompletedOnboarding)
    }
}

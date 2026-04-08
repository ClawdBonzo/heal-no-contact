import SwiftUI
import SwiftData

@main
struct HealNoContactApp: App {
    @State private var appState = AppState()
    private let revenueCat = RevenueCatService.shared

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            UserProfile.self,
            JournalEntry.self,
            MoodEntry.self,
            Milestone.self,
            EmergencyLog.self,
            LetterEntry.self,
            UserGamification.self,
            Quest.self,
            Badge.self,
            StreakFlame.self
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

    init() {
        revenueCat.configure()
    }

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
    @State private var showSplash = true

    var body: some View {
        ZStack {
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

            // Splash screen overlay
            if showSplash {
                SplashScreenView()
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                withAnimation(.easeOut(duration: 0.6)) {
                    showSplash = false
                }
            }
        }
    }
}

struct SplashScreenView: View {
    @State private var scale: CGFloat = 0.85
    @State private var opacity: Double = 0

    var body: some View {
        ZStack {
            Color.theme.deepBackground.ignoresSafeArea()

            Image("Splash-Dark")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .ignoresSafeArea()

            VStack {
                Spacer()
                Image("BrandIcon")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .scaleEffect(scale)
                    .opacity(opacity)
                    .padding(.bottom, 60)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                scale = 1.0
                opacity = 1.0
            }
        }
    }
}

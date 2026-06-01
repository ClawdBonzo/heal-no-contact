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
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @State private var showSplash = true

    var body: some View {
        ZStack {
            if !showSplash {
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
                .transition(.opacity)
            }

            // Splash screen overlay
            if showSplash {
                SplashScreenView()
                    .transition(.opacity)
                    .zIndex(1)
            }

            #if DEBUG
            if DemoConfig.shared.presentScreen == "letter" {
                NavigationStack { UnsentLetterView() }.zIndex(2)
            } else if DemoConfig.shared.presentScreen == "paywall" {
                PaywallView().zIndex(2)
            }
            #endif
        }
        .onAppear {
            #if DEBUG
            if UserDefaults.standard.bool(forKey: "seedDemo") {
                let screen = UserDefaults.standard.string(forKey: "demoScreen") ?? "home"
                DemoConfig.shared.apply(screen: screen, appState: appState)
                if DemoConfig.shared.isOnboarding {
                    DemoSeeder.clear(modelContext)
                } else {
                    DemoSeeder.seed(modelContext)
                }
                showSplash = false
                return
            }
            #endif
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                withAnimation(.easeOut(duration: 0.6)) {
                    showSplash = false
                }
            }
        }
    }
}

struct SplashScreenView: View {
    @State private var opacity: Double = 0
    @State private var heartbeat = false
    @State private var glowPulse = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            // Deep gradient background
            LinearGradient(
                colors: [
                    Color.theme.deepBackground,
                    Color.theme.healPurple.opacity(0.15),
                    Color.theme.deepBackground,
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // Centered pulsating heart-logo
            ZStack {
                // Outer soft glow
                Circle()
                    .fill(Color.theme.healPurple.opacity(0.20))
                    .frame(width: 280, height: 280)
                    .blur(radius: 45)
                    .scaleEffect(glowPulse ? 1.15 : 0.9)

                // Inner glow
                Circle()
                    .fill(Color.theme.healPurple.opacity(0.28))
                    .frame(width: 200, height: 200)
                    .blur(radius: 28)
                    .scaleEffect(glowPulse ? 1.12 : 0.95)

                Image("BrandIcon")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 160, height: 160)
                    .clipShape(RoundedRectangle(cornerRadius: 38))
                    .shadow(color: Color.theme.healPurple.opacity(0.55), radius: 28, y: 10)
                    .scaleEffect(heartbeat ? 1.06 : 1.0)
            }
            .opacity(opacity)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                opacity = 1.0
            }
            if !reduceMotion {
                startHeartbeat()
                withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                    glowPulse = true
                }
            }
        }
    }

    /// Double-pulse heartbeat pattern (~1 Hz).
    private func startHeartbeat() {
        Task { @MainActor in
            while !Task.isCancelled {
                withAnimation(.easeInOut(duration: 0.18)) { heartbeat = true }
                try? await Task.sleep(for: .milliseconds(180))
                withAnimation(.easeInOut(duration: 0.18)) { heartbeat = false }
                try? await Task.sleep(for: .milliseconds(120))
                withAnimation(.easeInOut(duration: 0.18)) { heartbeat = true }
                try? await Task.sleep(for: .milliseconds(180))
                withAnimation(.easeInOut(duration: 0.25)) { heartbeat = false }
                try? await Task.sleep(for: .milliseconds(900))
            }
        }
    }
}

#if DEBUG
// MARK: - Screenshot / demo harness (DEBUG only, gated behind -seedDemo launch arg)

@MainActor
final class DemoConfig {
    static let shared = DemoConfig()
    /// Stats sub-tab to force: 0 = Progress, 1 = Insights
    var statsTab: Int? = nil
    /// Onboarding page to force (welcome = 0, commitment = 3)
    var onboardingPage: Int? = nil
    /// A screen to present as a cover: "letter" or "paywall"
    var presentScreen: String? = nil
    /// True for screens that should show onboarding (no seeded profile)
    var isOnboarding: Bool { onboardingPage != nil }

    func apply(screen: String, appState: AppState) {
        switch screen {
        case "welcome":    onboardingPage = 0
        case "commitment": onboardingPage = 3
        case "home":       appState.selectedTab = .dashboard
        case "progress":   appState.selectedTab = .stats; statsTab = 0
        case "insights":   appState.selectedTab = .stats; statsTab = 1
        case "settings":   appState.selectedTab = .settings
        case "letter":     appState.selectedTab = .journal; presentScreen = "letter"
        case "paywall":    appState.selectedTab = .settings; presentScreen = "paywall"
        default: break
        }
    }
}

enum DemoSeeder {
    @MainActor
    static func seed(_ context: ModelContext) {
        clear(context)
        let cal = Calendar.current
        func daysAgo(_ n: Int) -> Date { cal.date(byAdding: .day, value: -n, to: .now) ?? .now }

        // Profile: 47-day streak, 60-day goal (78% ring)
        let profile = UserProfile(
            exName: "Alex",
            relationshipDuration: "3 years",
            breakupDate: daysAgo(50),
            noContactStartDate: daysAgo(47),
            noContactGoalDays: 60,
            reasonForNoContact: "To heal and rediscover myself",
            personalMantra: String(localized: "I choose my peace over their chaos."),
            hasCompletedOnboarding: true,
            notificationsEnabled: true
        )
        profile.currentStreakStartDate = daysAgo(47)
        profile.streakBestDays = 47
        profile.lastCheckInDate = .now
        context.insert(profile)

        // Gamification: level 5 "Inner Strength"
        let g = UserGamification(userId: profile.id)
        g.currentLevel = 5
        g.totalXP = 589
        g.xpTowardsNextLevel = 90
        context.insert(g)

        // Streak flame for 47 consecutive days
        let flame = StreakFlame(userId: profile.id)
        flame.updateFlameLevel(for: 47)
        context.insert(flame)

        // Milestones: unlock those at/under 47 days
        for (title, subtitle, day, icon) in Milestone.defaultMilestones {
            let m = Milestone(title: title, subtitle: subtitle, dayTarget: day, iconName: icon, isUnlocked: day <= 47)
            if day <= 47 { m.unlockedAt = daysAgo(max(0, 47 - day)) }
            context.insert(m)
        }

        // Mood check-ins: 10 across last 14 days (feeds healing score + weekly)
        let moodPlan: [(JournalEntry.MoodType, Int, Int)] = [
            (.grateful, 8, 0), (.strong, 7, 1), (.hopeful, 6, 2), (.grateful, 8, 3),
            (.neutral, 5, 4), (.hopeful, 6, 5), (.strong, 7, 6),
            (.grateful, 8, 9), (.hopeful, 6, 11), (.strong, 7, 13)
        ]
        for (mood, inten, ago) in moodPlan {
            let e = MoodEntry(mood: mood, intensity: inten, note: "")
            e.createdAt = daysAgo(ago)
            context.insert(e)
        }

        // Journal: 8 consecutive days (journaling streak)
        let titles = ["The 2am test", "What I'm learning", "Letting go, slowly", "A better morning",
                      "I didn't reach out", "Choosing me", "Small wins", "Forward"]
        for i in 0..<8 {
            let j = JournalEntry(
                title: titles[i],
                body: "Today I noticed I'm thinking about them less. Writing it down shows me how far I've come.",
                mood: i % 2 == 0 ? .grateful : .hopeful,
                tags: ["healing"],
                isFavorite: i == 0
            )
            j.createdAt = daysAgo(i)
            j.updatedAt = daysAgo(i)
            context.insert(j)
        }

        // Emergency logs: 15 total, 13 resisted (Urges Resisted 13/15)
        for i in 0..<15 {
            let resisted = i < 13
            let log = EmergencyLog(
                triggerReason: resisted ? "Late-night urge to text" : "Saw their post",
                copingStrategyUsed: resisted ? "Grounding + walked it off" : "Called a friend",
                didResist: resisted,
                durationSeconds: 240 + i * 30,
                intensityLevel: 5 + (i % 4),
                note: ""
            )
            log.createdAt = daysAgo((i * 3) % 30)
            context.insert(log)
        }

        // One active daily quest
        let quest = Quest(
            userId: profile.id,
            type: .daily,
            title: String(localized: "No-Contact Victory"),
            details: String(localized: "Go 24 hours without contact"),
            icon: "lock.fill",
            targetCount: 1,
            xpReward: 25,
            expiresAt: cal.date(byAdding: .day, value: 1, to: .now) ?? .now
        )
        context.insert(quest)

        try? context.save()
    }

    @MainActor
    static func clear(_ context: ModelContext) {
        try? context.delete(model: UserProfile.self)
        try? context.delete(model: UserGamification.self)
        try? context.delete(model: StreakFlame.self)
        try? context.delete(model: Milestone.self)
        try? context.delete(model: MoodEntry.self)
        try? context.delete(model: JournalEntry.self)
        try? context.delete(model: EmergencyLog.self)
        try? context.delete(model: Quest.self)
        try? context.delete(model: Badge.self)
        try? context.delete(model: LetterEntry.self)
        try? context.save()
    }
}
#endif

import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @Query(sort: \MoodEntry.createdAt, order: .reverse) private var recentMoods: [MoodEntry]
    @Query(sort: \Milestone.dayTarget) private var milestones: [Milestone]
    @Query private var gamifications: [UserGamification]
    @Query private var streakFlames: [StreakFlame]
    @State private var showCheckIn = false
    @State private var animateRing = false
    @State private var gamificationService: GameificationService?
    @State private var showLevelUpModal = false
    @State private var levelUpData: LevelUpAward? = nil

    private var profile: UserProfile? { profiles.first }
    private var gamification: UserGamification? { gamifications.first }
    private var streakFlame: StreakFlame? { streakFlames.first }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    if let profile {
                        // Level & XP progress (Gamification)
                        if let gamification = gamification {
                            VStack(spacing: 16) {
                                LevelBadgeView(gamification: gamification, showAnimation: true)
                                XPBarView(gamification: gamification)
                            }
                        }

                        // Streak ring
                        StreakRingView(
                            currentDays: profile.currentStreakDays,
                            goalDays: profile.noContactGoalDays,
                            animate: animateRing
                        )
                        .padding(.top, 8)

                        // Streak flame (Gamification)
                        if let flame = streakFlame {
                            StreakFlameView(flame: flame)
                        }

                        // Mantra card
                        if !profile.personalMantra.isEmpty {
                            MantraCard(mantra: profile.personalMantra)
                        }

                        // Daily quote
                        DailyQuoteCard()

                        // Quick actions
                        QuickActionsGrid(
                            onEmergency: { appState.showEmergencySOS = true },
                            onCheckIn: { showCheckIn = true },
                            onJournal: { appState.selectedTab = .journal }
                        )

                        // Stats row
                        StatsRow(profile: profile)

                        // Next milestone
                        if let next = nextMilestone(for: profile) {
                            NextMilestoneCard(
                                milestone: next,
                                currentDays: profile.currentStreakDays
                            )
                        }

                        // Recent mood
                        if let lastMood = recentMoods.first {
                            RecentMoodCard(mood: lastMood)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 100)
            }
            .scrollIndicators(.hidden)
            .background(Color.theme.deepBackground)
            .navigationTitle("Heal")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(isPresented: $showCheckIn) {
                DailyCheckInSheet()
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
            .fullScreenCover(isPresented: Binding(
                get: { appState.showEmergencySOS },
                set: { appState.showEmergencySOS = $0 }
            )) {
                EmergencyView()
            }
        }
        .onAppear {
            setupGamification()
            checkMilestones()
            withAnimation(.easeInOut(duration: 1.0).delay(0.3)) {
                animateRing = true
            }
        }
        .onChange(of: gamificationService?.levelUpAward) { _, newValue in
            if let award = newValue {
                levelUpData = award
                showLevelUpModal = true
            }
        }
        .sheet(isPresented: $showLevelUpModal) {
            if let levelUp = levelUpData, let gamification = gamification {
                ZStack {
                    Color.black.opacity(0.5).ignoresSafeArea()

                    LevelUpModalView(
                        oldLevel: levelUp.oldLevel,
                        newLevel: levelUp.newLevel,
                        levelName: gamification.levelName
                    ) {
                        showLevelUpModal = false
                        gamificationService?.levelUpAward = nil
                    }
                }
                .presentationBackground(.clear)
            }
        }
    }

    private func nextMilestone(for profile: UserProfile) -> Milestone? {
        milestones.first { !$0.isUnlocked && $0.dayTarget > profile.currentStreakDays }
    }

    private func setupGamification() {
        guard let profile = profile else { return }

        if gamificationService == nil {
            let service = GameificationService(modelContext: modelContext)
            service.initializeGamification(for: profile.id)
            gamificationService = service
        }
    }

    private func checkMilestones() {
        guard let profile else { return }

        for milestone in milestones where !milestone.isUnlocked {
            if profile.currentStreakDays >= milestone.dayTarget {
                milestone.isUnlocked = true
                milestone.unlockedAt = .now
                HapticService.milestone()
                NotificationService.shared.scheduleMilestoneReminder(
                    dayCount: milestone.dayTarget,
                    title: milestone.title
                )
            }
        }

        // Check badge milestones
        let journalCount = (try? modelContext.fetchCount(FetchDescriptor<JournalEntry>())) ?? 0
        let moodCount = recentMoods.count
        gamificationService?.checkMilestoneBadges(
            streakDays: profile.currentStreakDays,
            journalEntryCount: journalCount,
            moodCheckInCount: moodCount
        )
    }
}

// MARK: - Sub-components

private struct MantraCard: View {
    let mantra: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "quote.opening")
                .font(.caption)
                .foregroundStyle(Color.theme.healGold)

            Text(mantra)
                .font(.subheadline.weight(.medium).italic())
                .foregroundStyle(Color.theme.textPrimary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.theme.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.theme.healGold.opacity(0.15), lineWidth: 1)
                )
        )
    }
}

private struct DailyQuoteCard: View {
    private let quote = QuoteService.shared.dailyQuote()

    var body: some View {
        VStack(spacing: 8) {
            Text(quote.text)
                .font(.subheadline)
                .foregroundStyle(Color.theme.textPrimary)
                .multilineTextAlignment(.center)
                .lineSpacing(3)

            Text("— \(quote.author)")
                .font(.caption)
                .foregroundStyle(Color.theme.textTertiary)
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.theme.cardBackground)
        )
    }
}

private struct QuickActionsGrid: View {
    let onEmergency: () -> Void
    let onCheckIn: () -> Void
    let onJournal: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            QuickActionButton(
                icon: "sos",
                label: "SOS",
                color: Color.theme.healPink,
                action: onEmergency
            )

            QuickActionButton(
                icon: "checkmark.circle.fill",
                label: "Check In",
                color: Color.theme.healTeal,
                action: onCheckIn
            )

            QuickActionButton(
                icon: "pencil.and.outline",
                label: "Journal",
                color: Color.theme.healPurple,
                action: onJournal
            )
        }
    }
}

private struct QuickActionButton: View {
    let icon: String
    let label: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: {
            action()
            HapticService.impact(.light)
        }) {
            VStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)

                Text(label)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Color.theme.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.theme.cardBackground)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct StatsRow: View {
    let profile: UserProfile

    var body: some View {
        HStack(spacing: 12) {
            StatPill(
                label: "Current",
                value: "\(profile.currentStreakDays)d",
                icon: "flame.fill",
                color: Color.theme.healPurple
            )
            StatPill(
                label: "Best",
                value: "\(max(profile.streakBestDays, profile.currentStreakDays))d",
                icon: "trophy.fill",
                color: Color.theme.healGold
            )
            StatPill(
                label: "Since BU",
                value: "\(profile.daysSinceBreakup)d",
                icon: "calendar",
                color: Color.theme.healTeal
            )
        }
    }
}

private struct StatPill: View {
    let label: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(color)

            Text(value)
                .font(.title3.weight(.bold).monospacedDigit())
                .foregroundStyle(Color.theme.textPrimary)

            Text(label)
                .font(.caption2)
                .foregroundStyle(Color.theme.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.theme.cardBackground)
        )
    }
}

private struct NextMilestoneCard: View {
    let milestone: Milestone
    let currentDays: Int

    private var daysRemaining: Int {
        max(milestone.dayTarget - currentDays, 0)
    }

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: milestone.iconName)
                .font(.title2)
                .foregroundStyle(Color.theme.healGold)
                .frame(width: 48, height: 48)
                .background(Color.theme.healGold.opacity(0.15))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text("Next: \(milestone.title)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.theme.textPrimary)

                Text("\(daysRemaining) \(daysRemaining == 1 ? "day" : "days") to go")
                    .font(.caption)
                    .foregroundStyle(Color.theme.textSecondary)
            }

            Spacer()

            CircularProgressView(
                progress: Double(currentDays) / Double(milestone.dayTarget),
                lineWidth: 4,
                size: 40
            )
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.theme.cardBackground)
        )
    }
}

private struct CircularProgressView: View {
    let progress: Double
    let lineWidth: CGFloat
    let size: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.theme.textTertiary.opacity(0.3), lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: min(progress, 1.0))
                .stroke(
                    Color.theme.healPurple,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            Text("\(Int(progress * 100))%")
                .font(.system(size: 10, weight: .bold).monospacedDigit())
                .foregroundStyle(Color.theme.textSecondary)
        }
        .frame(width: size, height: size)
    }
}

private struct RecentMoodCard: View {
    let mood: MoodEntry

    var body: some View {
        HStack(spacing: 14) {
            Text(mood.mood.emoji)
                .font(.title)

            VStack(alignment: .leading, spacing: 2) {
                Text("Latest mood: \(mood.mood.rawValue)")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.theme.textPrimary)

                Text(mood.createdAt.relativeFormatted)
                    .font(.caption)
                    .foregroundStyle(Color.theme.textTertiary)
            }

            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.theme.cardBackground)
        )
    }
}

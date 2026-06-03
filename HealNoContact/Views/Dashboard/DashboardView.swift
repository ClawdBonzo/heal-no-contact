
import SwiftUI
import SwiftData

/// Caps the dashboard's recent-mood fetch so power users with thousands of
/// check-ins don't load the whole table just to read the latest entry.
private func dashboardRecentMoodsDescriptor() -> FetchDescriptor<MoodEntry> {
    var d = FetchDescriptor<MoodEntry>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
    d.fetchLimit = 30
    return d
}

struct DashboardView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]

    @Query(dashboardRecentMoodsDescriptor()) private var recentMoods: [MoodEntry]
    @Query(sort: \Milestone.dayTarget) private var milestones: [Milestone]
    @Query private var gamifications: [UserGamification]
    @Query private var streakFlames: [StreakFlame]
    @Query private var allQuests: [Quest]
    @Query(sort: \Badge.unlockedAt, order: .reverse) private var allBadges: [Badge]
    @State private var showCheckIn = false
    @State private var animateRing = false
    @State private var gamificationService: GameificationService?
    @State private var showLevelUpModal = false
    @State private var levelUpData: LevelUpAward? = nil
    @State private var showPhoenixOverlay = false
    @State private var phoenixMilestoneDay: Int? = nil

    private var profile: UserProfile? { profiles.first }
    private var gamification: UserGamification? { gamifications.first }
    private var streakFlame: StreakFlame? { streakFlames.first }

    private var activeDailyQuest: Quest? {
        guard let userId = profile?.id else { return nil }
        return allQuests
            .filter { $0.userId == userId && $0.type == .daily && !$0.isExpired }
            .sorted { !$0.isCompleted && $1.isCompleted }
            .first
    }

    private var unlockedBadges: [Badge] {
        guard let userId = profile?.id else { return [] }
        return allBadges.filter { $0.userId == userId }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {

                    if let profile {
                        // 0. STREAK RECOVERY — 48h safety net after a reset
                        if profile.canRecoverStreak {
                            StreakRecoveryBanner(hoursLeft: profile.recoveryWindowHoursRemaining) {
                                profile.recoverStreak()
                                try? modelContext.save()
                                HapticService.notification(.success)
                                animateRing = true
                                WidgetSync.update(
                                    streakDays: profile.currentStreakDays,
                                    goalDays: profile.noContactGoalDays,
                                    mantra: profile.personalMantra
                                )
                            }
                        }

                        // 1. HERO — streak ring + mantra + SOS chip
                        VStack(spacing: 16) {
                            StreakRingView(
                                currentDays: profile.currentStreakDays,
                                goalDays: profile.noContactGoalDays,
                                animate: animateRing
                            )

                            if !profile.personalMantra.isEmpty {
                                MantraCard(mantra: profile.personalMantra)
                            }

                            SOSChip {
                                appState.showEmergencySOS = true
                            }
                        }
                        .padding(.top, 4)

                        // 2. TODAY — check-in + journal
                        TodayActions(
                            onCheckIn: { showCheckIn = true },
                            onJournal: { appState.selectedTab = .journal }
                        )

                        // 3. DAILY QUEST
                        if let activeQuest = activeDailyQuest {
                            VStack(alignment: .leading, spacing: 12) {
                                SectionHeader(title: String(localized: "Today's Quest"))
                                DailyQuestView(quest: activeQuest) {
                                    gamificationService?.progressQuest(questId: activeQuest.id)
                                    HapticService.impact(.light)
                                }
                            }
                        }

                        // 4. YOUR JOURNEY — 3-card row
                        if let gamification {
                            VStack(alignment: .leading, spacing: 12) {
                                SectionHeader(title: String(localized: "Your Journey"))
                                JourneyStrip(
                                    gamification: gamification,
                                    flame: streakFlame,
                                    nextMilestone: nextMilestone(for: profile),
                                    currentDays: profile.currentStreakDays
                                )
                            }
                        }

                        // 5. BADGES
                        if !unlockedBadges.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                SectionHeader(
                                    title: String(localized: "Badges"),
                                    trailing: "\(unlockedBadges.count)"
                                )
                                BadgesStrip(badges: unlockedBadges)
                            }
                        }

                        // 6. RECENT MOOD
                        if let lastMood = recentMoods.first {
                            RecentMoodCard(mood: lastMood)
                        }

                        // 7. DAILY QUOTE
                        DailyQuoteCard()

                        // Share footer
                        HealingShareButton(
                            streakDays: profile.currentStreakDays,
                            userName: "",
                            mantra: profile.personalMantra
                        )
                        .padding(.top, 8)
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
        .fullScreenCover(isPresented: $showPhoenixOverlay) {
            PhoenixRisingOverlay(day: phoenixMilestoneDay) {
                showPhoenixOverlay = false
                phoenixMilestoneDay = nil
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
                let keyMilestones = [1, 7, 14, 21, 30, 45, 60, 90, 180, 365]
                if keyMilestones.contains(milestone.dayTarget) {
                    let targetDay = milestone.dayTarget
                    Task { @MainActor in
                        try? await Task.sleep(for: .seconds(0.6))
                        phoenixMilestoneDay = targetDay
                        showPhoenixOverlay = true
                    }
                }
            }
        }

        let journalCount = (try? modelContext.fetchCount(FetchDescriptor<JournalEntry>())) ?? 0

        let moodCount = (try? modelContext.fetchCount(FetchDescriptor<MoodEntry>())) ?? recentMoods.count
        gamificationService?.checkMilestoneBadges(
            streakDays: profile.currentStreakDays,
            journalEntryCount: journalCount,
            moodCheckInCount: moodCount
        )
    }
}

// MARK: - Section Header

private struct SectionHeader: View {
    let title: String
    var trailing: String? = nil

    var body: some View {
        HStack {
            Text(title)
                .font(.headline.weight(.semibold))
                .foregroundStyle(Color.theme.textPrimary)
            Spacer()
            if let trailing {
                Text(trailing)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.theme.textTertiary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.theme.cardBackground, in: Capsule())
            }
        }
    }
}

// MARK: - Mantra Card

private struct MantraCard: View {
    let mantra: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "quote.opening")
                .font(.subheadline)
                .foregroundStyle(Color.theme.healGold)

            Text(mantra)
                .font(.subheadline.weight(.medium).italic())
                .foregroundStyle(Color.theme.textPrimary)
                .multilineTextAlignment(.leading)
                .lineSpacing(3)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.theme.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.theme.healGold.opacity(0.18), lineWidth: 1)
                )
        )
    }
}

// MARK: - SOS Chip

private struct SOSChip: View {
    let action: () -> Void
    @State private var pulse = false

    var body: some View {
        Button {
            action()
            HapticService.impact(.medium)
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "heart.fill")
                    .font(.subheadline.weight(.bold))
                    .scaleEffect(pulse ? 1.15 : 1.0)

                Text("I need help now")
                    .font(.subheadline.weight(.semibold))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 22)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [Color.theme.healPink, Color.theme.healPurple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .shadow(color: Color.theme.healPink.opacity(0.4), radius: 12, y: 4)
            )
        }
        .buttonStyle(.plain)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }
}

// MARK: - Today Actions (2 big buttons)

private struct TodayActions: View {
    let onCheckIn: () -> Void
    let onJournal: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            BigActionButton(
                icon: "checkmark.circle.fill",
                title: String(localized: "Check In"),
                subtitle: String(localized: "Log your mood"),
                tint: Color.theme.healTeal,
                action: onCheckIn
            )
            BigActionButton(
                icon: "pencil.and.outline",
                title: String(localized: "Journal"),
                subtitle: String(localized: "Write it out"),
                tint: Color.theme.healPurple,
                action: onJournal
            )
        }
    }
}

private struct BigActionButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button {
            action()
            HapticService.impact(.light)
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(tint)
                    .frame(width: 40, height: 40)
                    .background(tint.opacity(0.15), in: RoundedRectangle(cornerRadius: 10))

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.theme.textPrimary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(Color.theme.textTertiary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.theme.cardBackground)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Journey Strip (Level / Flame / Next Milestone)

private struct JourneyStrip: View {
    let gamification: UserGamification
    let flame: StreakFlame?
    let nextMilestone: Milestone?
    let currentDays: Int

    var body: some View {
        HStack(spacing: 10) {
            JourneyCard(
                tint: Color.theme.healPurple,
                topText: "Lvl \(gamification.currentLevel)",
                bigText: gamification.levelName,
                bottomText: "\(gamification.xpTowardsNextLevel)/\(gamification.xpForNextLevel) XP",
                progress: gamification.levelProgress
            )

            if let flame {
                JourneyCard(
                    tint: Color.theme.healGold,
                    topText: "Flame",
                    bigText: flame.flameName,
                    bottomText: String(format: "×%.1f · %dd", flame.flameMultiplier, flame.consecutiveDaysWithoutContact),
                    progress: nil,
                    iconName: "flame.fill"
                )
            }

            if let nextMilestone {
                let remaining = max(nextMilestone.dayTarget - currentDays, 0)
                JourneyCard(
                    tint: Color.theme.healTeal,
                    topText: "Next",
                    bigText: nextMilestone.title,
                    bottomText: "\(remaining)d to go",
                    progress: Double(currentDays) / Double(max(nextMilestone.dayTarget, 1)),
                    iconName: nextMilestone.iconName
                )
            }
        }
    }
}

private struct JourneyCard: View {
    let tint: Color
    let topText: String
    let bigText: String
    let bottomText: String
    var progress: Double? = nil
    var iconName: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                if let iconName {
                    Image(systemName: iconName)
                        .font(.caption2)
                        .foregroundStyle(tint)
                }
                Text(topText)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(tint)
                    .textCase(.uppercase)
            }

            Text(bigText)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(Color.theme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            Spacer(minLength: 2)

            if let progress {
                ProgressView(value: min(progress, 1.0))
                    .tint(tint)
                    .frame(height: 4)
            }

            Text(bottomText)
                .font(.caption2)
                .foregroundStyle(Color.theme.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 110)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.theme.cardBackground)
        )
    }
}

// MARK: - Badges Strip

private struct BadgesStrip: View {
    let badges: [Badge]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(badges.prefix(10)) { badge in
                    BadgeChip(badge: badge)
                }
            }
            .padding(.horizontal, 2)
        }
        .scrollClipDisabled()
    }
}

private struct BadgeChip: View {
    let badge: Badge

    private var rarityColor: Color {
        switch badge.rarity {
        case .common: Color.theme.textSecondary
        case .rare: Color.theme.healTeal
        case .epic: Color.theme.healPurple
        case .legendary: Color.theme.healGold
        }
    }

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: badge.icon)
                .font(.title2)
                .foregroundStyle(rarityColor)
                .frame(width: 52, height: 52)
                .background(
                    Circle()
                        .fill(rarityColor.opacity(0.15))
                        .overlay(Circle().stroke(rarityColor.opacity(0.4), lineWidth: 1))
                )

            Text(badge.title)
                .font(.caption2.weight(.medium))
                .foregroundStyle(Color.theme.textSecondary)
                .lineLimit(1)
                .frame(maxWidth: 70)
        }
    }
}

// MARK: - Daily Quote

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

// MARK: - Recent Mood

private struct RecentMoodCard: View {
    let mood: MoodEntry

    var body: some View {
        HStack(spacing: 14) {
            Text(mood.mood.emoji)
                .font(.title)

            VStack(alignment: .leading, spacing: 2) {
                Text("Latest mood: \(mood.mood.localizedName)")
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

// MARK: - Streak Recovery Banner

/// Shown for 48 hours after a streak reset, offering a one-tap undo.
/// A gentle loss-aversion safety net: slipping once shouldn't end the journey.
private struct StreakRecoveryBanner: View {
    let hoursLeft: Int
    let onRecover: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "arrow.uturn.backward.circle.fill")
                    .font(.title3)
                    .foregroundStyle(Color.theme.healGold)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Restore your streak")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.theme.textPrimary)
                    Text("A slip isn't the end. You can undo your reset for \(hoursLeft)h.")
                        .font(.caption)
                        .foregroundStyle(Color.theme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
            }

            Button(action: onRecover) {
                Text("Restore my streak")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                    .background(
                        LinearGradient(
                            colors: [Color.theme.healPurple, Color.theme.healBlue],
                            startPoint: .leading, endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(16)
        .background(Color.theme.healGold.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.theme.healGold.opacity(0.4), lineWidth: 1)
        )
    }
}


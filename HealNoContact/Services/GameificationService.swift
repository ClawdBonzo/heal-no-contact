import SwiftData
import Observation
import Foundation

struct LevelUpAward: Equatable {
    let oldLevel: Int
    let newLevel: Int
}

/// A transient "+N XP" event for the global toast. `id` makes repeated equal amounts distinct.
struct XPGain: Equatable, Identifiable {
    let id = UUID()
    let amount: Int
    let reason: String
}

/// The single gamification engine for the app. One instance is created by `RootView`,
/// injected via `.environment`, and shared by every screen — so XP, level-ups, quests,
/// badges and the flame are always in sync and celebrated wherever they're earned.
@Observable
@MainActor
final class GameificationService {
    var userGamification: UserGamification?
    var quests: [Quest] = []
    var badges: [Badge] = []
    var streakFlame: StreakFlame?

    // Transient events observed by the global overlay.
    var recentXPGain: XPGain? = nil
    var levelUpAward: LevelUpAward? = nil
    var recentBadge: Badge? = nil

    private let modelContext: ModelContext
    private var userId: UUID?

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Derived

    var dailyQuests: [Quest] {
        quests.filter { $0.type == .daily && !$0.isExpired }
              .sorted { ($0.isCompleted ? 1 : 0, $0.createdAt) < ($1.isCompleted ? 1 : 0, $1.createdAt) }
    }

    var weeklyQuests: [Quest] {
        quests.filter { $0.type == .weekly && !$0.isExpired }
              .sorted { ($0.isCompleted ? 1 : 0, $0.createdAt) < ($1.isCompleted ? 1 : 0, $1.createdAt) }
    }

    var dailyCompletedCount: Int { dailyQuests.filter(\.isCompleted).count }

    var isMaxLevel: Bool { (userGamification?.currentLevel ?? 1) >= 10 }

    // MARK: - Lifecycle

    /// Idempotent. Call on launch, on foreground, and whenever the profile changes.
    /// Creates the records on first run, rolls quests over at day/week boundaries,
    /// recomputes the flame from the real streak, and credits today's no-contact day.
    func sync(profile: UserProfile) {
        if userId != profile.id || userGamification == nil {
            initializeGamification(for: profile.id)
        }
        refreshQuests(for: profile.id)
        syncFlame(streakDays: profile.currentStreakDays)
        creditNoContactDay(profile: profile)
        try? modelContext.save()
    }

    /// Forget all cached model objects (after "Delete All Data").
    func reset() {
        userGamification = nil; quests = []; badges = []; streakFlame = nil; userId = nil
        recentXPGain = nil; levelUpAward = nil; recentBadge = nil
    }

    func initializeGamification(for userId: UUID) {
        self.userId = userId

        if let existing = try? modelContext.fetch(
            FetchDescriptor<UserGamification>(predicate: #Predicate { $0.userId == userId })
        ).first {
            userGamification = existing
        } else {
            let fresh = UserGamification(userId: userId)
            modelContext.insert(fresh)
            userGamification = fresh
        }

        if let existingFlame = try? modelContext.fetch(
            FetchDescriptor<StreakFlame>(predicate: #Predicate { $0.userId == userId })
        ).first {
            streakFlame = existingFlame
        } else {
            let flame = StreakFlame(userId: userId)
            modelContext.insert(flame)
            streakFlame = flame
        }

        loadQuests(for: userId)
        loadBadges(for: userId)
        try? modelContext.save()
    }

    // MARK: - XP & Levels

    func addXP(_ amount: Int, reason: String) {
        guard let gamification = userGamification else { return }

        let multiplier = streakFlame?.flameMultiplier ?? 1.0
        let awarded = max(1, Int((Double(amount) * multiplier).rounded()))
        let oldLevel = gamification.currentLevel
        gamification.addXP(awarded)

        recentXPGain = XPGain(amount: awarded, reason: reason)
        HapticService.xpGain()

        if gamification.currentLevel > oldLevel {
            levelUpAward = LevelUpAward(oldLevel: oldLevel, newLevel: gamification.currentLevel)
            HapticService.levelUp()
            checkLevelBadges()
        }

        try? modelContext.save()
    }

    // MARK: - Flame

    /// The flame is a function of the real no-contact streak: it grows with the streak,
    /// resets with it, and multiplies XP up to ×1.5 at 90+ days.
    func syncFlame(streakDays: Int) {
        streakFlame?.updateFlameLevel(for: max(streakDays, 0))
    }

    // MARK: - Quests

    enum QuestKind: String {
        case checkIn = "heart.fill"
        case journal = "book.fill"
        case noContact = "lock.fill"
        case selfCare = "leaf.fill"
        case crusader = "star.fill"
    }

    /// Advances every active (unexpired, incomplete) quest of the given kind by one step —
    /// e.g. saving a journal entry progresses "Journal Feelings" (daily) and "Journal Warrior" (weekly).
    func progressQuests(ofKind kind: QuestKind) {
        let matching = quests.filter { $0.icon == kind.rawValue && !$0.isCompleted && !$0.isExpired }
        guard !matching.isEmpty else { return }
        for quest in matching { progress(quest) }
        try? modelContext.save()
    }

    private func progress(_ quest: Quest) {
        quest.incrementProgress()
        guard quest.isCompleted else { return }

        addXP(quest.xpReward, reason: quest.title)
        HapticService.questComplete()

        // Completing any daily quest feeds the weekly "Quest Crusader".
        if quest.type == .daily {
            for weekly in quests where weekly.icon == QuestKind.crusader.rawValue && weekly.type == .weekly
                && !weekly.isCompleted && !weekly.isExpired {
                progress(weekly)
            }
        }
        checkQuestCompletionBadges()
    }

    /// Credits one "no-contact day" per calendar day the user shows up without a reset that day.
    /// Drives the daily "No-Contact Victory" and weekly "No-Contact Champion" quests.
    private func creditNoContactDay(profile: UserProfile) {
        guard let g = userGamification, profile.currentStreakDays >= 1 else { return }
        let cal = Calendar.current
        if let last = g.lastNoContactCreditDate, cal.isDateInToday(last) { return }
        if let reset = profile.lastResetDate, cal.isDateInToday(reset) { return }
        g.lastNoContactCreditDate = .now
        progressQuests(ofKind: .noContact)
    }

    /// Daily quests expire at the end of the local day; weekly ones at the start of next week.
    /// Safe to call often — only creates when nothing active exists.
    func refreshQuests(for userId: UUID) {
        let now = Date.now
        let cal = Calendar.current

        for quest in quests where quest.expiresAt <= now { modelContext.delete(quest) }
        quests.removeAll { $0.expiresAt <= now }

        if !quests.contains(where: { $0.type == .daily }) {
            let endOfDay = cal.startOfDay(for: cal.date(byAdding: .day, value: 1, to: now) ?? now)
            createDailyQuests(for: userId, expiresAt: endOfDay)
        }
        if !quests.contains(where: { $0.type == .weekly }) {
            let weekStart = cal.date(from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)) ?? now
            let nextWeek = cal.date(byAdding: .day, value: 7, to: weekStart) ?? now
            createWeeklyQuests(for: userId, expiresAt: nextWeek)
        }
        loadQuests(for: userId)
    }

    private func createDailyQuests(for userId: UUID, expiresAt: Date) {
        let daily: [(String, String, String, Int)] = [
            (String(localized: "Daily Check-In"), String(localized: "Log your mood today"), QuestKind.checkIn.rawValue, 10),
            (String(localized: "Journal Feelings"), String(localized: "Write a journal entry"), QuestKind.journal.rawValue, 15),
            (String(localized: "No-Contact Victory"), String(localized: "Go 24 hours without contact"), QuestKind.noContact.rawValue, 25),
            (String(localized: "Self-Care Time"), String(localized: "Ride out an urge with SOS"), QuestKind.selfCare.rawValue, 20)
        ]
        for (title, details, icon, xp) in daily {
            modelContext.insert(Quest(userId: userId, type: .daily, title: title, details: details,
                                      icon: icon, targetCount: 1, xpReward: xp, expiresAt: expiresAt))
        }
    }

    private func createWeeklyQuests(for userId: UUID, expiresAt: Date) {
        let weekly: [(String, String, String, Int, Int)] = [
            (String(localized: "Journal Warrior"), String(localized: "Write 5 journal entries"), QuestKind.journal.rawValue, 5, 50),
            (String(localized: "No-Contact Champion"), String(localized: "7 days without contact"), QuestKind.noContact.rawValue, 7, 100),
            (String(localized: "Mood Master"), String(localized: "Log mood 7 times"), QuestKind.checkIn.rawValue, 7, 50),
            (String(localized: "Quest Crusader"), String(localized: "Complete 3 daily quests"), QuestKind.crusader.rawValue, 3, 75)
        ]
        for (title, details, icon, target, xp) in weekly {
            modelContext.insert(Quest(userId: userId, type: .weekly, title: title, details: details,
                                      icon: icon, targetCount: target, xpReward: xp, expiresAt: expiresAt))
        }
    }

    // MARK: - Check-in streak (separate from the no-contact streak)

    /// Returns false if the user already checked in today (no double XP).
    @discardableResult
    func recordCheckIn() -> Bool {
        guard let g = userGamification else { return false }
        let cal = Calendar.current
        if let last = g.dailyStreakLastDate, cal.isDateInToday(last) { return false }
        if let last = g.dailyStreakLastDate, cal.isDateInYesterday(last) {
            g.dailyStreakDays += 1
        } else {
            g.dailyStreakDays = 1
        }
        g.dailyStreakLastDate = .now
        return true
    }

    var hasCheckedInToday: Bool {
        guard let last = userGamification?.dailyStreakLastDate else { return false }
        return Calendar.current.isDateInToday(last)
    }

    // MARK: - Badge System

    /// All badges the app can award, in display order. Used for the locked-badge grid.
    struct BadgeSpec { let id: String; let title: String; let details: String; let icon: String; let rarity: Badge.Rarity }
    static var catalog: [BadgeSpec] {[
        BadgeSpec(id: "first_quest",    title: String(localized: "Quest Starter"),   details: String(localized: "Complete your first daily quest"), icon: "star.fill",        rarity: .common),
        BadgeSpec(id: "journal_keeper", title: String(localized: "Journal Keeper"),  details: String(localized: "10 journal entries"),             icon: "book.fill",        rarity: .common),
        BadgeSpec(id: "week_strong",    title: String(localized: "One Week Strong"), details: String(localized: "7 days of no-contact"),           icon: "flame.fill",       rarity: .rare),
        BadgeSpec(id: "mood_tracker",   title: String(localized: "Mood Tracker"),    details: String(localized: "20 mood check-ins"),              icon: "heart.fill",       rarity: .rare),
        BadgeSpec(id: "weekly_champion",title: String(localized: "Weekly Champion"), details: String(localized: "Complete a weekly quest"),        icon: "crown.fill",       rarity: .rare),
        BadgeSpec(id: "month_warrior",  title: String(localized: "30-Day Warrior"),  details: String(localized: "One month of healing"),           icon: "shield.fill",      rarity: .epic),
        BadgeSpec(id: "rising_phoenix", title: String(localized: "Rising Phoenix"),  details: String(localized: "Reached level 5"),                icon: "flame.fill",       rarity: .epic),
        BadgeSpec(id: "century_club",   title: String(localized: "Century Club"),    details: String(localized: "100 days free"),                  icon: "medal.fill",       rarity: .epic),
        BadgeSpec(id: "fully_healed",   title: String(localized: "Fully Healed"),    details: String(localized: "Reached ultimate level"),         icon: "heart.fill",       rarity: .legendary),
    ]}

    func hasBadge(_ id: String) -> Bool { badges.contains { $0.badgeId == id } }

    private func unlock(_ id: String) {
        guard let userId, !hasBadge(id), let spec = Self.catalog.first(where: { $0.id == id }) else { return }
        let badge = Badge(userId: userId, badgeId: spec.id, title: spec.title, details: spec.details,
                          icon: spec.icon, rarity: spec.rarity)
        modelContext.insert(badge)
        badges.insert(badge, at: 0)
        userGamification?.totalBadgesEarned = badges.count
        recentBadge = badge
        HapticService.badgeUnlock(spec.rarity.rawValue)
        try? modelContext.save()
    }

    private func checkQuestCompletionBadges() {
        if quests.contains(where: { $0.type == .daily && $0.isCompleted }) { unlock("first_quest") }
        if quests.contains(where: { $0.type == .weekly && $0.isCompleted }) {
            userGamification?.weeklyQuestsCompleted = quests.filter { $0.type == .weekly && $0.isCompleted }.count
            unlock("weekly_champion")
        }
    }

    private func checkLevelBadges() {
        guard let g = userGamification else { return }
        if g.currentLevel >= 5  { unlock("rising_phoenix") }
        if g.currentLevel >= 10 { unlock("fully_healed") }
    }

    func checkMilestoneBadges(streakDays: Int, journalEntryCount: Int, moodCheckInCount: Int) {
        if streakDays >= 7   { unlock("week_strong") }
        if streakDays >= 30  { unlock("month_warrior") }
        if streakDays >= 100 { unlock("century_club") }
        if journalEntryCount >= 10 { unlock("journal_keeper") }
        if moodCheckInCount >= 20  { unlock("mood_tracker") }
        checkLevelBadges()
    }

    // MARK: - Private Helpers

    private func loadQuests(for userId: UUID) {
        var descriptor = FetchDescriptor<Quest>(predicate: #Predicate { $0.userId == userId })
        descriptor.sortBy = [SortDescriptor(\.createdAt)]
        quests = (try? modelContext.fetch(descriptor)) ?? []
    }

    private func loadBadges(for userId: UUID) {
        var descriptor = FetchDescriptor<Badge>(predicate: #Predicate { $0.userId == userId })
        descriptor.sortBy = [SortDescriptor(\.unlockedAt, order: .reverse)]
        badges = (try? modelContext.fetch(descriptor)) ?? []
    }
}

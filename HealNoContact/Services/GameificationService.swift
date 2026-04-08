import SwiftData
import Observation
import Foundation

struct LevelUpAward: Equatable {
    let oldLevel: Int
    let newLevel: Int
}

@Observable
@MainActor
final class GameificationService {
    var userGamification: UserGamification?
    var quests: [Quest] = []
    var badges: [Badge] = []
    var streakFlame: StreakFlame?
    var recentXPGain: Int? = nil
    var levelUpAward: LevelUpAward? = nil

    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Initialization

    func initializeGamification(for userId: UUID) {
        let existing = try? modelContext.fetch(
            FetchDescriptor<UserGamification>(predicate: #Predicate { $0.userId == userId })
        ).first

        if let existing {
            userGamification = existing
        } else {
            let newGamification = UserGamification(userId: userId)
            modelContext.insert(newGamification)
            userGamification = newGamification
            try? modelContext.save()
        }

        let existingFlame = try? modelContext.fetch(
            FetchDescriptor<StreakFlame>(predicate: #Predicate { $0.userId == userId })
        ).first

        if let existingFlame {
            streakFlame = existingFlame
        } else {
            let newFlame = StreakFlame(userId: userId)
            modelContext.insert(newFlame)
            streakFlame = newFlame
            try? modelContext.save()
        }

        loadQuests(for: userId)
        loadBadges(for: userId)
        seedDefaultQuestsIfNeeded(for: userId)
    }

    // MARK: - XP & Levels

    func addXP(_ amount: Int, reason: String) {
        guard let gamification = userGamification else { return }

        let oldLevel = gamification.currentLevel
        gamification.addXP(Int(Double(amount) * (streakFlame?.flameMultiplier ?? 1.0)))

        recentXPGain = amount
        HapticService.xpGain()

        if gamification.currentLevel > oldLevel {
            levelUpAward = LevelUpAward(oldLevel: oldLevel, newLevel: gamification.currentLevel)
            HapticService.levelUp()
        }

        try? modelContext.save()
    }

    // MARK: - Quest Management

    func progressQuest(questId: UUID) {
        guard let quest = quests.first(where: { $0.id == questId }), !quest.isCompleted else { return }

        quest.incrementProgress()

        if quest.isCompleted {
            addXP(quest.xpReward, reason: "Quest: \(quest.title)")
            HapticService.questComplete()
            checkQuestCompletionBadges()
        }

        try? modelContext.save()
    }

    func refreshQuests(for userId: UUID) {
        let now = Date.now
        let calendar = Calendar.current

        let expiredDaily = quests.filter { $0.type == .daily && $0.expiresAt < now }
        for quest in expiredDaily {
            modelContext.delete(quest)
        }

        let existingDaily = quests.filter { $0.type == .daily && $0.expiresAt > now }
        if existingDaily.isEmpty {
            createDailyQuests(for: userId)
        }

        let mondayOfThisWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
        let endOfWeek = calendar.date(byAdding: .day, value: 7, to: mondayOfThisWeek)!

        let expiredWeekly = quests.filter { $0.type == .weekly && $0.expiresAt < now }
        for quest in expiredWeekly {
            modelContext.delete(quest)
        }

        let existingWeekly = quests.filter { $0.type == .weekly && $0.expiresAt > now }
        if existingWeekly.isEmpty {
            createWeeklyQuests(for: userId, expiresAt: endOfWeek)
        }

        loadQuests(for: userId)
        try? modelContext.save()
    }

    private func createDailyQuests(for userId: UUID) {
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date.now)!

        let dailyQuests: [(String, String, String, Int)] = [
            ("Daily Check-In", "Log your mood today", "heart.fill", 10),
            ("Journal Feelings", "Write a journal entry", "book.fill", 15),
            ("No-Contact Victory", "Go 24 hours without contact", "lock.fill", 25),
            ("Self-Care Time", "Complete a self-care activity", "leaf.fill", 20)
        ]

        for (title, details, icon, xp) in dailyQuests {
            let quest = Quest(
                userId: userId,
                type: .daily,
                title: title,
                details: details,
                icon: icon,
                targetCount: 1,
                xpReward: xp,
                expiresAt: tomorrow
            )
            modelContext.insert(quest)
        }
    }

    private func createWeeklyQuests(for userId: UUID, expiresAt: Date) {
        let weeklyQuests: [(String, String, String, Int, Int)] = [
            ("Journal Warrior", "Write 5 journal entries", "book.fill", 5, 50),
            ("No-Contact Champion", "7 days without contact", "lock.fill", 7, 100),
            ("Mood Master", "Log mood 7 times", "heart.fill", 7, 50),
            ("Quest Crusader", "Complete 3 daily quests", "star.fill", 3, 75)
        ]

        for (title, details, icon, target, xp) in weeklyQuests {
            let quest = Quest(
                userId: userId,
                type: .weekly,
                title: title,
                details: details,
                icon: icon,
                targetCount: target,
                xpReward: xp,
                expiresAt: expiresAt
            )
            modelContext.insert(quest)
        }
    }

    private func seedDefaultQuestsIfNeeded(for userId: UUID) {
        let descriptor = FetchDescriptor<Quest>(predicate: #Predicate { $0.userId == userId })
        let existingCount = (try? modelContext.fetchCount(descriptor)) ?? 0

        if existingCount == 0 {
            createDailyQuests(for: userId)
            let endOfWeek = Calendar.current.date(byAdding: .day, value: 7, to: Date.now)!
            createWeeklyQuests(for: userId, expiresAt: endOfWeek)
            try? modelContext.save()
            loadQuests(for: userId)
        }
    }

    // MARK: - Badge System

    func unlockBadge(badgeId: String, title: String, details: String, icon: String, rarity: Badge.Rarity, isPremium: Bool = false) {
        guard let userId = userGamification?.userId else { return }

        let existingBadge = badges.first { $0.badgeId == badgeId }
        if existingBadge != nil { return }

        let badge = Badge(
            userId: userId,
            badgeId: badgeId,
            title: title,
            details: details,
            icon: icon,
            rarity: rarity,
            isPremiumCosmetic: isPremium
        )

        modelContext.insert(badge)
        badges.append(badge)

        HapticService.badgeUnlock(rarity.rawValue)
        try? modelContext.save()
    }

    private func checkQuestCompletionBadges() {
        guard let gamification = userGamification else { return }

        let dailyQuestCount = quests.filter { $0.type == .daily && $0.isCompleted }.count
        let weeklyQuestCount = quests.filter { $0.type == .weekly && $0.isCompleted }.count

        if dailyQuestCount == 1 && !badges.contains(where: { $0.badgeId == "first_quest" }) {
            unlockBadge(badgeId: "first_quest", title: "Quest Starter", details: "Complete your first daily quest", icon: "star.fill", rarity: .common)
        }

        if weeklyQuestCount == 1 && !badges.contains(where: { $0.badgeId == "weekly_champion" }) {
            unlockBadge(badgeId: "weekly_champion", title: "Weekly Champion", details: "Complete a weekly quest", icon: "crown.fill", rarity: .rare)
        }
    }

    // MARK: - Milestone Badges

    func checkMilestoneBadges(streakDays: Int, journalEntryCount: Int, moodCheckInCount: Int) {
        guard let gamification = userGamification else { return }

        if streakDays >= 7 && !badges.contains(where: { $0.badgeId == "week_strong" }) {
            unlockBadge(badgeId: "week_strong", title: "One Week Strong", details: "7 days of no-contact", icon: "flame.fill", rarity: .rare)
        }

        if streakDays >= 30 && !badges.contains(where: { $0.badgeId == "month_warrior" }) {
            unlockBadge(badgeId: "month_warrior", title: "30-Day Warrior", details: "One month of healing", icon: "shield.fill", rarity: .epic)
        }

        if streakDays >= 100 && !badges.contains(where: { $0.badgeId == "century_club" }) {
            unlockBadge(badgeId: "century_club", title: "Century Club", details: "100 days free", icon: "100.circle.fill", rarity: .epic)
        }

        if journalEntryCount >= 10 && !badges.contains(where: { $0.badgeId == "journal_keeper" }) {
            unlockBadge(badgeId: "journal_keeper", title: "Journal Keeper", details: "10 journal entries", icon: "book.fill", rarity: .common)
        }

        if moodCheckInCount >= 20 && !badges.contains(where: { $0.badgeId == "mood_tracker" }) {
            unlockBadge(badgeId: "mood_tracker", title: "Mood Tracker", details: "20 mood check-ins", icon: "heart.fill", rarity: .rare)
        }

        if gamification.currentLevel >= 5 && !badges.contains(where: { $0.badgeId == "rising_phoenix" }) {
            unlockBadge(badgeId: "rising_phoenix", title: "Rising Phoenix", details: "Reached level 5", icon: "flame.fill", rarity: .epic)
        }

        if gamification.currentLevel >= 10 && !badges.contains(where: { $0.badgeId == "fully_healed" }) {
            unlockBadge(badgeId: "fully_healed", title: "Fully Healed", details: "Reached ultimate level", icon: "heart.fill", rarity: .legendary)
        }
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

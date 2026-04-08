import SwiftData
import Foundation

@Model final class UserGamification {
    var id: UUID
    var userId: UUID
    var totalXP: Int
    var currentLevel: Int
    var xpTowardsNextLevel: Int
    var dailyStreakDays: Int
    var dailyStreakLastDate: Date?
    var weeklyQuestsCompleted: Int
    var totalBadgesEarned: Int
    var createdAt: Date
    var updatedAt: Date

    init(userId: UUID) {
        self.id = UUID()
        self.userId = userId
        self.totalXP = 0
        self.currentLevel = 1
        self.xpTowardsNextLevel = 0
        self.dailyStreakDays = 0
        self.weeklyQuestsCompleted = 0
        self.totalBadgesEarned = 0
        self.createdAt = .now
        self.updatedAt = .now
    }

    // MARK: - Computed Properties

    var xpForNextLevel: Int {
        let base = 100
        let multiplier = pow(1.15, Double(currentLevel - 1))
        return Int(Double(base) * multiplier)
    }

    var levelProgress: Double {
        let threshold = xpForNextLevel
        return threshold > 0 ? Double(xpTowardsNextLevel) / Double(threshold) : 0
    }

    var levelName: String {
        switch currentLevel {
        case 1: return "Broken Heart"
        case 2: return "First Light"
        case 3: return "Healing Heart"
        case 4: return "Growing Stronger"
        case 5: return "Inner Strength"
        case 6: return "Whole Again"
        case 7: return "Free Spirit"
        case 8: return "Phoenix Rising"
        case 9: return "Unstoppable"
        case 10: return "Fully Healed"
        default: return "Legend"
        }
    }

    var levelColor: String {
        switch currentLevel {
        case 1...2: return "gray"
        case 3...4: return "teal"
        case 5...6: return "purple"
        case 7...8: return "gold"
        default: return "rose"
        }
    }

    // MARK: - XP Methods

    func addXP(_ amount: Int) {
        totalXP += amount
        xpTowardsNextLevel += amount
        updatedAt = .now

        while xpTowardsNextLevel >= xpForNextLevel && currentLevel < 10 {
            xpTowardsNextLevel -= xpForNextLevel
            currentLevel += 1
        }
    }
}

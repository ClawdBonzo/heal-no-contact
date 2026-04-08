import SwiftData
import Foundation

@Model final class StreakFlame {
    var id: UUID
    var userId: UUID
    var currentFlameLevel: Int
    var flameMultiplier: Double
    var lastFlameIncrement: Date?
    var consecutiveDaysWithoutContact: Int
    var createdAt: Date

    init(userId: UUID) {
        self.id = UUID()
        self.userId = userId
        self.currentFlameLevel = 1
        self.flameMultiplier = 1.0
        self.consecutiveDaysWithoutContact = 0
        self.createdAt = .now
    }

    var flameName: String {
        switch currentFlameLevel {
        case 1...3: return "Ember"
        case 4...7: return "Flame"
        case 8...14: return "Inferno"
        case 15...30: return "Phoenix"
        default: return "Eternal Phoenix"
        }
    }

    func updateFlameLevel(for consecutiveDays: Int) {
        consecutiveDaysWithoutContact = consecutiveDays
        currentFlameLevel = min(10 + (consecutiveDays / 10), 50)
        flameMultiplier = 1.0 + (Double(currentFlameLevel - 1) * 0.15)
        lastFlameIncrement = .now
    }
}

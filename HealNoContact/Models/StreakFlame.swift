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
        case 1...3: return String(localized: "Ember")
        case 4...7: return String(localized: "Flame")
        case 8...14: return String(localized: "Inferno")
        case 15...30: return String(localized: "Phoenix")
        default: return String(localized: "Eternal Phoenix")
        }
    }

    /// One flame level per 3 days of no contact: Ember (days 0–8), Flame (9–20),
    /// Inferno (21–41), Phoenix (42–89), Eternal Phoenix (90+). XP multiplier grows
    /// linearly to ×1.5 at level 31 (90 days) and stays there.
    func updateFlameLevel(for consecutiveDays: Int) {
        consecutiveDaysWithoutContact = max(consecutiveDays, 0)
        currentFlameLevel = min(1 + consecutiveDaysWithoutContact / 3, 50)
        flameMultiplier = min(1.0 + Double(currentFlameLevel - 1) * (0.5 / 30.0), 1.5)
        lastFlameIncrement = .now
    }

    /// 0…1 progress toward the next named tier, for the journey card.
    var tierProgress: Double {
        let bounds: [(Int, Int)] = [(1, 3), (4, 7), (8, 14), (15, 30), (31, 50)]
        guard let (lo, hi) = bounds.first(where: { currentFlameLevel >= $0.0 && currentFlameLevel <= $0.1 }) else { return 1 }
        return Double(currentFlameLevel - lo) / Double(max(hi - lo, 1))
    }
}

import SwiftData
import Foundation

@Model final class Quest {
    var id: UUID
    var userId: UUID
    var type: QuestType
    var title: String
    var details: String
    var icon: String
    var targetCount: Int
    var currentProgress: Int
    var xpReward: Int
    var isCompleted: Bool
    var completedAt: Date?
    var expiresAt: Date
    var createdAt: Date

    enum QuestType: String, Codable {
        case daily, weekly
    }

    init(
        userId: UUID,
        type: QuestType,
        title: String,
        details: String,
        icon: String,
        targetCount: Int,
        xpReward: Int,
        expiresAt: Date
    ) {
        self.id = UUID()
        self.userId = userId
        self.type = type
        self.title = title
        self.details = details
        self.icon = icon
        self.targetCount = targetCount
        self.currentProgress = 0
        self.xpReward = xpReward
        self.isCompleted = false
        self.expiresAt = expiresAt
        self.createdAt = .now
    }

    var progressPercentage: Double {
        targetCount > 0 ? Double(currentProgress) / Double(targetCount) : 0
    }

    var isExpired: Bool {
        Date.now > expiresAt
    }

    func incrementProgress() {
        if !isCompleted && currentProgress < targetCount {
            currentProgress += 1
            if currentProgress >= targetCount {
                isCompleted = true
                completedAt = .now
            }
        }
    }
}

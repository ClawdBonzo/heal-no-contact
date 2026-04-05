import Foundation
import SwiftData

@Model
final class Milestone {
    var id: UUID
    var title: String
    var subtitle: String
    var dayTarget: Int
    var iconName: String
    var isUnlocked: Bool
    var unlockedAt: Date?
    var createdAt: Date

    init(
        title: String,
        subtitle: String,
        dayTarget: Int,
        iconName: String,
        isUnlocked: Bool = false
    ) {
        self.id = UUID()
        self.title = title
        self.subtitle = subtitle
        self.dayTarget = dayTarget
        self.iconName = iconName
        self.isUnlocked = isUnlocked
        self.unlockedAt = nil
        self.createdAt = .now
    }

    static let defaultMilestones: [(String, String, Int, String)] = [
        ("First Step", "You started your healing journey", 1, "foot.fill"),
        ("One Week Strong", "7 days of choosing yourself", 7, "star.fill"),
        ("Two Weeks", "Building new habits takes time", 14, "leaf.fill"),
        ("21-Day Mark", "New neural pathways are forming", 21, "brain.fill"),
        ("One Month", "A full month of growth", 30, "moon.fill"),
        ("45 Days", "You're rewriting your story", 45, "pencil.and.outline"),
        ("Two Months", "60 days of resilience", 60, "shield.fill"),
        ("90-Day Triumph", "The hardest part is behind you", 90, "trophy.fill"),
        ("Half Year Hero", "180 days of transformation", 180, "sun.max.fill"),
        ("One Year Free", "365 days — you are renewed", 365, "sparkles")
    ]
}

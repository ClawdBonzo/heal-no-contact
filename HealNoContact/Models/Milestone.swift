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
        (String(localized: "First Step"), String(localized: "You started your healing journey"), 1, "foot.fill"),
        (String(localized: "One Week Strong"), String(localized: "7 days of choosing yourself"), 7, "star.fill"),
        (String(localized: "Two Weeks"), String(localized: "Building new habits takes time"), 14, "leaf.fill"),
        (String(localized: "21-Day Mark"), String(localized: "New neural pathways are forming"), 21, "brain.fill"),
        (String(localized: "One Month"), String(localized: "A full month of growth"), 30, "moon.fill"),
        (String(localized: "45 Days"), String(localized: "You're rewriting your story"), 45, "pencil.and.outline"),
        (String(localized: "Two Months"), String(localized: "60 days of resilience"), 60, "shield.fill"),
        (String(localized: "90-Day Triumph"), String(localized: "The hardest part is behind you"), 90, "trophy.fill"),
        (String(localized: "Half Year Hero"), String(localized: "180 days of transformation"), 180, "sun.max.fill"),
        (String(localized: "One Year Free"), String(localized: "365 days — you are renewed"), 365, "sparkles")
    ]
}

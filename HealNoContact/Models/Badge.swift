import SwiftData
import Foundation

@Model final class Badge {
    var id: UUID
    var userId: UUID
    var badgeId: String
    var title: String
    var details: String
    var icon: String
    var rarity: Rarity
    var unlockedAt: Date
    var createdAt: Date
    var isPremiumCosmetic: Bool

    enum Rarity: String, Codable {
        case common, rare, epic, legendary

        var color: String {
            switch self {
            case .common: return "gray"
            case .rare: return "blue"
            case .epic: return "purple"
            case .legendary: return "gold"
            }
        }

        var emoji: String {
            switch self {
            case .common: return "⭐"
            case .rare: return "✨"
            case .epic: return "💜"
            case .legendary: return "👑"
            }
        }
    }

    init(
        userId: UUID,
        badgeId: String,
        title: String,
        details: String,
        icon: String,
        rarity: Rarity,
        isPremiumCosmetic: Bool = false
    ) {
        self.id = UUID()
        self.userId = userId
        self.badgeId = badgeId
        self.title = title
        self.details = details
        self.icon = icon
        self.rarity = rarity
        self.unlockedAt = .now
        self.createdAt = .now
        self.isPremiumCosmetic = isPremiumCosmetic
    }
}

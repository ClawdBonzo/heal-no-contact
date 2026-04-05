import Foundation
import SwiftData

@Model
final class JournalEntry {
    var id: UUID
    var title: String
    var body: String
    var mood: MoodType
    var tags: [String]
    var isFavorite: Bool
    var createdAt: Date
    var updatedAt: Date

    init(
        title: String = "",
        body: String = "",
        mood: MoodType = .neutral,
        tags: [String] = [],
        isFavorite: Bool = false
    ) {
        self.id = UUID()
        self.title = title
        self.body = body
        self.mood = mood
        self.tags = tags
        self.isFavorite = isFavorite
        self.createdAt = .now
        self.updatedAt = .now
    }

    enum MoodType: String, Codable, CaseIterable, Identifiable {
        case devastated = "Devastated"
        case sad = "Sad"
        case anxious = "Anxious"
        case neutral = "Neutral"
        case hopeful = "Hopeful"
        case strong = "Strong"
        case grateful = "Grateful"

        var id: String { rawValue }

        var emoji: String {
            switch self {
            case .devastated: "💔"
            case .sad: "😢"
            case .anxious: "😰"
            case .neutral: "😐"
            case .hopeful: "🌱"
            case .strong: "💪"
            case .grateful: "🙏"
            }
        }

        var color: String {
            switch self {
            case .devastated: "moodDevastate"
            case .sad: "moodSad"
            case .anxious: "moodAnxious"
            case .neutral: "moodNeutral"
            case .hopeful: "moodHopeful"
            case .strong: "moodStrong"
            case .grateful: "moodGrateful"
            }
        }

        var numericValue: Int {
            switch self {
            case .devastated: 1
            case .sad: 2
            case .anxious: 3
            case .neutral: 4
            case .hopeful: 5
            case .strong: 6
            case .grateful: 7
            }
        }
    }
}

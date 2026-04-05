import Foundation
import SwiftData

@Model
final class MoodEntry {
    var id: UUID
    var mood: JournalEntry.MoodType
    var intensity: Int // 1-10
    var note: String
    var createdAt: Date

    init(
        mood: JournalEntry.MoodType = .neutral,
        intensity: Int = 5,
        note: String = ""
    ) {
        self.id = UUID()
        self.mood = mood
        self.intensity = intensity
        self.note = note
        self.createdAt = .now
    }
}

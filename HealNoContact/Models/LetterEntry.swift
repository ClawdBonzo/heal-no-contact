import Foundation
import SwiftData

@Model
final class LetterEntry {
    var id: UUID
    var recipient: String
    var body: String
    var mood: JournalEntry.MoodType
    var createdAt: Date

    init(
        recipient: String = "",
        body: String = "",
        mood: JournalEntry.MoodType = .sad
    ) {
        self.id = UUID()
        self.recipient = recipient
        self.body = body
        self.mood = mood
        self.createdAt = .now
    }
}

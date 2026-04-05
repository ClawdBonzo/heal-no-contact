import Foundation
import SwiftData

@Model
final class EmergencyLog {
    var id: UUID
    var triggerReason: String
    var copingStrategyUsed: String
    var didResist: Bool
    var durationSeconds: Int
    var intensityLevel: Int // 1-10
    var note: String
    var createdAt: Date

    init(
        triggerReason: String = "",
        copingStrategyUsed: String = "",
        didResist: Bool = true,
        durationSeconds: Int = 0,
        intensityLevel: Int = 5,
        note: String = ""
    ) {
        self.id = UUID()
        self.triggerReason = triggerReason
        self.copingStrategyUsed = copingStrategyUsed
        self.didResist = didResist
        self.durationSeconds = durationSeconds
        self.intensityLevel = intensityLevel
        self.note = note
        self.createdAt = .now
    }
}

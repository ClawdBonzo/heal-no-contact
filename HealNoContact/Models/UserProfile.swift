import Foundation
import SwiftData

@Model
final class UserProfile {
    var id: UUID
    var exName: String
    var relationshipDuration: String
    var breakupDate: Date
    var noContactStartDate: Date
    var noContactGoalDays: Int
    var reasonForNoContact: String
    var personalMantra: String
    var hasCompletedOnboarding: Bool
    var dailyCheckInTime: Date
    var notificationsEnabled: Bool
    var streakBestDays: Int
    var currentStreakStartDate: Date?
    var lastCheckInDate: Date?
    var totalResets: Int
    var createdAt: Date

    init(
        exName: String = "",
        relationshipDuration: String = "",
        breakupDate: Date = .now,
        noContactStartDate: Date = .now,
        noContactGoalDays: Int = 30,
        reasonForNoContact: String = "",
        personalMantra: String = "",
        hasCompletedOnboarding: Bool = false,
        dailyCheckInTime: Date = Calendar.current.date(
            from: DateComponents(hour: 9, minute: 0)
        ) ?? .now,
        notificationsEnabled: Bool = true
    ) {
        self.id = UUID()
        self.exName = exName
        self.relationshipDuration = relationshipDuration
        self.breakupDate = breakupDate
        self.noContactStartDate = noContactStartDate
        self.noContactGoalDays = noContactGoalDays
        self.reasonForNoContact = reasonForNoContact
        self.personalMantra = personalMantra
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.dailyCheckInTime = dailyCheckInTime
        self.notificationsEnabled = notificationsEnabled
        self.streakBestDays = 0
        self.currentStreakStartDate = noContactStartDate
        self.totalResets = 0
        self.createdAt = .now
    }

    var currentStreakDays: Int {
        guard let start = currentStreakStartDate else { return 0 }
        return Calendar.current.dateComponents([.day], from: start, to: .now).day ?? 0
    }

    var goalProgress: Double {
        guard noContactGoalDays > 0 else { return 0 }
        return min(Double(currentStreakDays) / Double(noContactGoalDays), 1.0)
    }

    var daysSinceBreakup: Int {
        Calendar.current.dateComponents([.day], from: breakupDate, to: .now).day ?? 0
    }

    func resetStreak() {
        totalResets += 1
        if currentStreakDays > streakBestDays {
            streakBestDays = currentStreakDays
        }
        currentStreakStartDate = .now
    }
}

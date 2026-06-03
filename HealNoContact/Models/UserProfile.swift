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
    /// Streak start captured at the moment of a reset, enabling a 48h "undo".
    var previousStreakStartDate: Date? = nil
    /// When the most recent reset happened (for the recovery window).
    var lastResetDate: Date? = nil

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
        previousStreakStartDate = currentStreakStartDate
        lastResetDate = .now
        currentStreakStartDate = .now
    }

    /// Whole hours left in the post-reset recovery window (0 if expired/none).
    var recoveryWindowHoursRemaining: Int {
        guard previousStreakStartDate != nil, let reset = lastResetDate else { return 0 }
        let remaining = (48 * 3600) - Date.now.timeIntervalSince(reset)
        return remaining > 0 ? Int(remaining / 3600) + 1 : 0
    }

    var canRecoverStreak: Bool { recoveryWindowHoursRemaining > 0 }

    /// Restores the streak that was active before the most recent reset.
    /// Available for 48 hours after a reset — a gentle safety net, not a cheat:
    /// it only undoes the user's own most-recent reset.
    func recoverStreak() {
        guard canRecoverStreak, let prev = previousStreakStartDate else { return }
        currentStreakStartDate = prev
        previousStreakStartDate = nil
        lastResetDate = nil
        totalResets = max(0, totalResets - 1)
    }
}

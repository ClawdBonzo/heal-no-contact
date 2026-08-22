import Foundation
import StoreKit
import SwiftUI

/// Decides *when* to ask for an App Store rating. iOS already throttles to ~3 prompts a year;
/// this adds our own judgment: only after a genuinely good moment (resisted urge, milestone),
/// never in the first two days, and never more than once every 14 days.
enum ReviewPrompter {
    private static let lastPromptKey = "review.lastPromptDate"
    private static let minDaysBetweenPrompts = 14

    enum Moment { case resistedUrge, milestone(day: Int), checkInStreak(days: Int) }

    @MainActor
    static func maybeRequest(_ request: RequestReviewAction, moment: Moment, streakDays: Int) {
        guard streakDays >= 2 else { return }
        let worthy: Bool
        switch moment {
        case .resistedUrge:            worthy = streakDays >= 3
        case .milestone(let day):      worthy = [7, 14, 21, 30, 60, 90, 180, 365].contains(day)
        case .checkInStreak(let days): worthy = days >= 5
        }
        guard worthy else { return }
        if let last = UserDefaults.standard.object(forKey: lastPromptKey) as? Date,
           Calendar.current.dateComponents([.day], from: last, to: .now).day ?? 0 < minDaysBetweenPrompts {
            return
        }
        UserDefaults.standard.set(Date.now, forKey: lastPromptKey)
        request()
    }

    /// App Store "write a review" deep link for explicit, user-initiated rating.
    static let writeReviewURL = URL(string: "https://apps.apple.com/app/id6761851731?action=write-review")!
}

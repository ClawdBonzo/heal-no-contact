import Foundation
import SwiftUI

/// Decides *when* to offer Premium, beyond the hard feature locks.
///
/// Why this exists: telemetry (Aug 2026) showed Spain generating 90 of the app's 99
/// sessions and 14 downloads while never starting a single trial — the most engaged
/// cohort in the app was never actually asked. The only paywall entries were the
/// post-onboarding intro (before any value is felt) and two feature locks a casual
/// user never touches.
///
/// The rule here: ask once at a moment the user just felt good about — a milestone
/// they earned — never in the first days, and never more than once a fortnight.
enum PaywallMoments {
    private static let lastOfferKey  = "paywall.lastEarnedOfferDate"
    private static let offeredDaysKey = "paywall.offeredMilestoneDays"
    private static let minDaysBetween = 14

    /// Milestones worth celebrating *and* converting on. Day 1 is deliberately excluded:
    /// too early to have earned the ask.
    private static let convertibleMilestones: Set<Int> = [7, 14, 30, 60, 90, 180, 365]

    /// Call right after a milestone celebration is dismissed.
    /// Returns true if the caller should present the paywall.
    @MainActor
    static func shouldOfferAfterMilestone(day: Int, streakDays: Int, isPremium: Bool) -> Bool {
        guard !isPremium, streakDays >= 3, convertibleMilestones.contains(day) else { return false }

        // Never offer on the same milestone twice, even across reinstalls of the streak.
        var offered = Set(UserDefaults.standard.array(forKey: offeredDaysKey) as? [Int] ?? [])
        guard !offered.contains(day) else { return false }

        if let last = UserDefaults.standard.object(forKey: lastOfferKey) as? Date,
           Calendar.current.dateComponents([.day], from: last, to: .now).day ?? 0 < minDaysBetween {
            return false
        }
        offered.insert(day)
        UserDefaults.standard.set(Array(offered), forKey: offeredDaysKey)
        UserDefaults.standard.set(Date.now, forKey: lastOfferKey)
        return true
    }

    /// Clears the record so a fresh profile starts over (used by Delete All Data).
    static func reset() {
        UserDefaults.standard.removeObject(forKey: lastOfferKey)
        UserDefaults.standard.removeObject(forKey: offeredDaysKey)
    }
}

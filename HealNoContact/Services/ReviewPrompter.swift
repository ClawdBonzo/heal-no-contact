import Foundation
import StoreKit
import SwiftUI

/// Decides *when* to ask for an App Store rating. iOS already throttles to ~3 prompts a year;
/// this adds our own judgment: only after a genuinely good moment (resisted urge, milestone),
/// never on a user's very first day, and never more than once every 14 days.
///
/// Instrumentation note (2026-09-05): after five weeks live the app had exactly one rating,
/// so every decision this type makes is now logged and counted locally. `Log.reviews` shows
/// the decision on a device you control; `diagnostics` exposes the running tally so a DEBUG
/// build can display it. There is deliberately no field telemetry here — measuring this on
/// other people's devices would mean adding a third-party analytics SDK, which we have not.
enum ReviewPrompter {
    private static let lastPromptKey = "review.lastPromptDate"
    private static let attemptsKey   = "review.attempts"
    private static let firedKey      = "review.fired"
    private static let lastSkipKey   = "review.lastSkipReason"
    private static let minDaysBetweenPrompts = 14

    enum Moment {
        case resistedUrge
        case milestone(day: Int)
        case checkInStreak(days: Int)
        case badgeUnlocked(rarity: String)
        case journalEntries(count: Int)
        case levelUp(level: Int)

        var label: String {
            switch self {
            case .resistedUrge:            return "resistedUrge"
            case .milestone(let d):        return "milestone(\(d))"
            case .checkInStreak(let d):    return "checkInStreak(\(d))"
            case .badgeUnlocked(let r):    return "badgeUnlocked(\(r))"
            case .journalEntries(let n):   return "journalEntries(\(n))"
            case .levelUp(let l):          return "levelUp(\(l))"
            }
        }
    }

    /// Why a prompt did or didn't happen. Recorded so "the prompts never fire" is a
    /// question we can answer instead of guess at.
    enum Outcome: String {
        case requested          // we called requestReview (iOS may still suppress it)
        case tooEarly           // user hasn't reached day 1 of a streak
        case notWorthy          // moment didn't clear its own bar
        case throttled          // inside our own 14-day window
    }

    /// The screenshot harness seeds a 47-day streak, which is by definition a worthy
    /// moment — so every capture run got a rating dialog over the artwork. Never ask
    /// during a demo capture.
    private static var isDemoCapture: Bool {
        UserDefaults.standard.bool(forKey: "seedDemo")
    }

    @MainActor
    static func maybeRequest(_ request: RequestReviewAction, moment: Moment, streakDays: Int) {
        guard !isDemoCapture else { return }
        let d = UserDefaults.standard
        d.set(d.integer(forKey: attemptsKey) + 1, forKey: attemptsKey)

        func skip(_ outcome: Outcome) {
            d.set(outcome.rawValue, forKey: lastSkipKey)
            Log.reviews.debug("skip \(moment.label, privacy: .public) — \(outcome.rawValue, privacy: .public)")
        }

        // Day 0 is too soon to ask, but day 1 is not: most people who ever come back
        // come back within a day or two, and the old `>= 2` floor silently disqualified
        // every earned moment they hit before then.
        guard streakDays >= 1 else { return skip(.tooEarly) }

        let worthy: Bool
        switch moment {
        case .resistedUrge:            worthy = streakDays >= 3
        case .milestone(let day):      worthy = [3, 7, 14, 21, 30, 60, 90, 180, 365].contains(day)
        case .checkInStreak(let days): worthy = days >= 3
        case .badgeUnlocked(let r):    worthy = ["rare", "epic", "legendary"].contains(r)
        case .journalEntries(let n):   worthy = [5, 10, 25, 50].contains(n)
        case .levelUp(let level):      worthy = level >= 3
        }
        guard worthy else { return skip(.notWorthy) }

        if let last = d.object(forKey: lastPromptKey) as? Date,
           Calendar.current.dateComponents([.day], from: last, to: .now).day ?? 0 < minDaysBetweenPrompts {
            return skip(.throttled)
        }

        d.set(Date.now, forKey: lastPromptKey)
        d.set(d.integer(forKey: firedKey) + 1, forKey: firedKey)
        Log.reviews.notice("requesting review after \(moment.label, privacy: .public)")
        request()
    }

    /// Asks *after* the current screen has finished going away. `requestReview` is a no-op
    /// when the presenting scene is being dismissed, which is exactly what happened at the
    /// two best moments we had: the SOS success overlay and the journal save, both of which
    /// called this and then immediately dismissed themselves.
    @MainActor
    static func requestAfterDismissal(_ request: RequestReviewAction, moment: Moment,
                                      streakDays: Int, delay: Duration = .milliseconds(900)) {
        Task { @MainActor in
            try? await Task.sleep(for: delay)
            maybeRequest(request, moment: moment, streakDays: streakDays)
        }
    }

    /// Local tally for debugging why prompts do or don't appear. Not sent anywhere.
    static var diagnostics: (attempts: Int, fired: Int, lastSkip: String?, lastPrompt: Date?) {
        let d = UserDefaults.standard
        return (d.integer(forKey: attemptsKey),
                d.integer(forKey: firedKey),
                d.string(forKey: lastSkipKey),
                d.object(forKey: lastPromptKey) as? Date)
    }

    /// App Store "write a review" deep link for explicit, user-initiated rating.
    static let writeReviewURL = URL(string: "https://apps.apple.com/app/id6761851731?action=write-review")!
}

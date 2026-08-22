import Foundation
import WidgetKit

/// Bridges live app state into the home/lock-screen widgets via a shared App Group.
/// The app writes a small snapshot; the widget timelines read the same keys.
///
/// The streak is stored as its *start date* (not a day count) so the widget can
/// compute and advance the number itself at each midnight without the app running.
enum WidgetSync {
    static let appGroup = "group.com.clawdbonzo.HealNoContact"

    enum Key {
        static let streakStart   = "widget.streakStart"   // TimeInterval since 1970
        static let streakDays    = "widget.streakDays"    // legacy snapshot, still written
        static let goalDays      = "widget.goalDays"
        static let mantra        = "widget.mantra"
        static let checkedInDay  = "widget.checkedInDay"  // "yyyy-MM-dd" of the last check-in
    }

    private static var defaults: UserDefaults? { UserDefaults(suiteName: appGroup) }

    /// Pushes the current profile state to the shared store and refreshes widgets.
    static func update(profile: UserProfile) {
        update(streakStart: profile.currentStreakStartDate,
               streakDays: profile.currentStreakDays,
               goalDays: profile.noContactGoalDays,
               mantra: profile.personalMantra,
               lastCheckIn: profile.lastCheckInDate)
    }

    /// Legacy signature kept for call sites that only have the numbers.
    static func update(streakDays: Int, goalDays: Int, mantra: String) {
        update(streakStart: nil, streakDays: streakDays, goalDays: goalDays, mantra: mantra, lastCheckIn: nil)
    }

    static func update(streakStart: Date?, streakDays: Int, goalDays: Int, mantra: String, lastCheckIn: Date?) {
        guard let d = defaults else { return }
        if let streakStart { d.set(streakStart.timeIntervalSince1970, forKey: Key.streakStart) }
        d.set(max(streakDays, 0), forKey: Key.streakDays)
        d.set(max(goalDays, 1), forKey: Key.goalDays)
        let trimmed = mantra.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty { d.set(trimmed, forKey: Key.mantra) }
        if let lastCheckIn {
            d.set(dayString(lastCheckIn), forKey: Key.checkedInDay)
        }
        WidgetCenter.shared.reloadAllTimelines()
    }

    /// Wipes the shared snapshot (used by "Delete All Data") so the home-screen widget
    /// doesn't keep showing a deleted user's streak and mantra.
    static func clear() {
        guard let d = defaults else { return }
        for k in [Key.streakStart, Key.streakDays, Key.goalDays, Key.mantra, Key.checkedInDay] {
            d.removeObject(forKey: k)
        }
        WidgetCenter.shared.reloadAllTimelines()
    }

    static func dayString(_ date: Date) -> String {
        let c = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }
}

import Foundation
import WidgetKit

/// Bridges live app state into the home-screen widgets via a shared App Group.
/// The app writes a small snapshot; the widget timelines read the same keys.
enum WidgetSync {
    static let appGroup = "group.com.clawdbonzo.HealNoContact"

    enum Key {
        static let streakDays = "widget.streakDays"
        static let goalDays   = "widget.goalDays"
        static let mantra     = "widget.mantra"
    }

    private static var defaults: UserDefaults? { UserDefaults(suiteName: appGroup) }

    /// Pushes the current streak + goal + mantra to the shared store and refreshes widgets.
    static func update(streakDays: Int, goalDays: Int, mantra: String) {
        guard let d = defaults else { return }
        d.set(max(streakDays, 0), forKey: Key.streakDays)
        d.set(max(goalDays, 1), forKey: Key.goalDays)
        let trimmed = mantra.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty { d.set(trimmed, forKey: Key.mantra) }
        WidgetCenter.shared.reloadAllTimelines()
    }

    /// Wipes the shared snapshot (used by "Delete All Data") so the home-screen widget
    /// doesn't keep showing a deleted user's streak and mantra.
    static func clear() {
        guard let d = defaults else { return }
        d.removeObject(forKey: Key.streakDays)
        d.removeObject(forKey: Key.goalDays)
        d.removeObject(forKey: Key.mantra)
        WidgetCenter.shared.reloadAllTimelines()
    }
}

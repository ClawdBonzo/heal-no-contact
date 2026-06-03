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
        d.set(streakDays, forKey: Key.streakDays)
        d.set(max(goalDays, 1), forKey: Key.goalDays)
        let trimmed = mantra.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty { d.set(trimmed, forKey: Key.mantra) }
        WidgetCenter.shared.reloadAllTimelines()
    }
}

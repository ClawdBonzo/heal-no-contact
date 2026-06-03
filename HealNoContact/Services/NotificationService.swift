import Foundation
import UserNotifications

@MainActor
final class NotificationService {
    static let shared = NotificationService()

    private init() {}

    func requestPermission() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .badge, .sound])
        } catch {
            return false
        }
    }

    func scheduleDailyCheckIn(at time: Date) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["dailyCheckIn"])

        let content = UNMutableNotificationContent()
        content.title = String(localized: "Time for your check-in")
        content.body = QuoteService.shared.randomMotivational()
        content.sound = .default
        content.interruptionLevel = .timeSensitive

        let components = Calendar.current.dateComponents([.hour, .minute], from: time)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

        let request = UNNotificationRequest(
            identifier: "dailyCheckIn",
            content: content,
            trigger: trigger
        )
        center.add(request)
    }

    func scheduleMilestoneReminder(dayCount: Int, title: String) {
        let content = UNMutableNotificationContent()
        content.title = String(localized: "Milestone Unlocked! 🏆")
        content.body = String(localized: "\(title) — \(dayCount) days of no contact!")
        content.sound = .default
        content.interruptionLevel = .active

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "milestone_\(dayCount)",
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request)
    }

    func scheduleEncouragementNotifications() {
        // Premium feature: extra daily encouragement reminders.
        guard RevenueCatService.shared.isPremium else { return }
        let center = UNUserNotificationCenter.current()

        let encouragements = [
            (hour: 12, message: String(localized: "You're doing amazing. Every hour counts.")),
            (hour: 18, message: String(localized: "Evening check: You stayed strong today.")),
            (hour: 21, message: String(localized: "Nights can be tough. You've got this."))
        ]

        for (index, item) in encouragements.enumerated() {
            let content = UNMutableNotificationContent()
            content.title = "Heal"
            content.body = item.message
            content.sound = .default

            var components = DateComponents()
            components.hour = item.hour
            components.minute = 0

            let trigger = UNCalendarNotificationTrigger(
                dateMatching: components,
                repeats: true
            )
            let request = UNNotificationRequest(
                identifier: "encouragement_\(index)",
                content: content,
                trigger: trigger
            )
            center.add(request)
        }
    }


    // MARK: - Re-engagement reminders

    /// IDs for the dynamic re-engagement reminders. Cleared/rescheduled together.
    private static let engagementIDs = ["missedCheckIn", "streakAtRisk", "winBack2", "winBack4", "winBack7"]

    /// Schedules a ladder of one-shot reminders that only fire if the user stays away.
    /// Call this every time the user checks in *and* when the app comes to the foreground
    /// so the timers keep getting pushed forward while the user is active.
    func rescheduleEngagementReminders(streakDays: Int) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: Self.engagementIDs)

        let hour: TimeInterval = 3600
        let day: TimeInterval = 86400

        func schedule(_ id: String, after interval: TimeInterval, title: String, body: String,
                      level: UNNotificationInterruptionLevel = .active) {
            let content = UNMutableNotificationContent()
            content.title = title
            content.body = body
            content.sound = .default
            content.interruptionLevel = level
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(interval, 60), repeats: false)
            center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
        }

        // Missed check-in — next day if they haven't returned.
        schedule("missedCheckIn", after: 26 * hour,
                 title: String(localized: "Your daily check-in is waiting"),
                 body: String(localized: "A quick check-in keeps your momentum going. How are you today?"))

        // Streak at risk — loss-aversion nudge ~1.5 days out.
        if streakDays > 0 {
            schedule("streakAtRisk", after: 36 * hour,
                     title: String(localized: "Don't lose your \(streakDays)-day streak 🔥"),
                     body: String(localized: "You've come so far. Open Heal to keep your streak alive."),
                     level: .timeSensitive)
        }

        // Gentle win-back ladder for lapsed users.
        schedule("winBack2", after: 2 * day,
                 title: String(localized: "We're still here for you"),
                 body: String(localized: "Healing isn't linear. Come back when you're ready — today is a good day."))
        schedule("winBack4", after: 4 * day,
                 title: String(localized: "Your peace is worth protecting"),
                 body: String(localized: "It's been a few days. One small step forward is still progress."))
        schedule("winBack7", after: 7 * day,
                 title: String(localized: "A week is a fresh start"),
                 body: String(localized: "Reopen Heal and pick up your journey — your future self will thank you."))
    }

    func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}

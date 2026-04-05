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
        content.title = "Time for your check-in"
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
        content.title = "Milestone Unlocked! 🏆"
        content.body = "\(title) — \(dayCount) days of no contact!"
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
        let center = UNUserNotificationCenter.current()

        let encouragements = [
            (hour: 12, message: "You're doing amazing. Every hour counts."),
            (hour: 18, message: "Evening check: You stayed strong today."),
            (hour: 21, message: "Nights can be tough. You've got this.")
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

    func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}

import Foundation
import Observation
import UserNotifications

@Observable
@MainActor
final class NotificationService: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationService()

    /// Where a tapped notification wants to go (consumed by RootView via `onOpenURL`-style routing).
    var pendingDeepLink: URL?

    private override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }

    // Show banners even while the app is in the foreground (milestones, check-in nudges).
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter,
                                            willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }

    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter,
                                            didReceive response: UNNotificationResponse) async {
        let link = response.notification.request.content.userInfo["deepLink"] as? String
        await MainActor.run {
            if let link, let url = URL(string: link) { NotificationService.shared.pendingDeepLink = url }
        }
    }

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
        content.interruptionLevel = .active
        content.userInfo = ["deepLink": "heal://checkin"]

        let components = Calendar.current.dateComponents([.hour, .minute], from: time)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

        let request = UNNotificationRequest(
            identifier: "dailyCheckIn",
            content: content,
            trigger: trigger
        )
        center.add(request)
    }

    /// Pre-schedules the next few milestone celebrations at the moment they'll actually be
    /// reached (streak start + N days, 9:30 local), so they arrive even if the app is closed.
    /// Rescheduled on every foreground/reset/recover; identifiers are stable per day target.
    func scheduleMilestoneReminders(profile: UserProfile) {
        let center = UNUserNotificationCenter.current()
        let targets = Milestone.defaultMilestones.map { $0.2 }
        center.removePendingNotificationRequests(withIdentifiers: targets.map { "milestone_\($0)" })
        guard let start = profile.currentStreakStartDate else { return }

        let cal = Calendar.current
        let upcoming = targets.filter { $0 > profile.currentStreakDays }.prefix(3)
        for day in upcoming {
            guard let reached = cal.date(byAdding: .day, value: day, to: start) else { continue }
            var comps = cal.dateComponents([.year, .month, .day], from: reached)
            comps.hour = 9; comps.minute = 30
            guard let fireDate = cal.date(from: comps), fireDate > .now else { continue }
            let title = Milestone.defaultMilestones.first { $0.2 == day }?.0 ?? String(localized: "Milestone reached")

            let content = UNMutableNotificationContent()
            content.title = String(localized: "Milestone Unlocked! 🏆")
            content.body = String(localized: "\(title) — \(day) days of no contact!")
            content.sound = .default
            content.userInfo = ["deepLink": "heal://home"]
            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
            center.add(UNNotificationRequest(identifier: "milestone_\(day)", content: content, trigger: trigger))
        }
    }

    /// IDs for the premium encouragement reminders (12:00 / 18:00 / 21:00).
    private static let encouragementIDs = ["encouragement_0", "encouragement_1", "encouragement_2"]

    /// Keeps the premium encouragement reminders in sync with entitlement + the user's
    /// notification preference. Safe to call often (idempotent — fixed identifiers).
    /// Called after purchase/restore and on every foreground so renewals and lapses are honored.
    func syncPremiumReminders(notificationsEnabled: Bool) {
        if notificationsEnabled && RevenueCatService.shared.isPremium {
            scheduleEncouragementNotifications()
        } else {
            cancelEncouragementNotifications()
        }
    }

    func cancelEncouragementNotifications() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: Self.encouragementIDs)
    }

    func scheduleEncouragementNotifications() {
        // Premium feature: extra daily encouragement reminders.
        guard RevenueCatService.shared.isPremium else { return }
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: Self.encouragementIDs)

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
            content.userInfo = ["deepLink": "heal://checkin"]
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(interval, 60), repeats: false)
            center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
        }

        // Missed check-in — next day if they haven't returned.
        schedule("missedCheckIn", after: 26 * hour,
                 title: String(localized: "Your daily check-in is waiting"),
                 body: String(localized: "A quick check-in keeps your momentum going. How are you today?"))

        // Streak nudge ~1.5 days out. The no-contact streak only resets when the user
        // reports contact, so the copy celebrates the streak rather than threatening it.
        if streakDays > 0 {
            schedule("streakAtRisk", after: 36 * hour,
                     title: String(localized: "Your streak is still going 🔥"),
                     body: String(localized: "\(streakDays)+ days of no contact. Check in and add today to it."))
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

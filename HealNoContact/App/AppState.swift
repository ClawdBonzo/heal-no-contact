import SwiftUI
import Observation

@Observable
@MainActor
final class AppState {
    var selectedTab: AppTab = .dashboard
    var showEmergencySOS: Bool = false
    var showDailyCheckIn: Bool = false
    var showPaywall: Bool = false
    /// Set when onboarding finishes so the intro paywall is shown once on first entry.
    var pendingIntroPaywall: Bool = false

    /// Derives premium status from RevenueCat — always in sync
    var isPremium: Bool {
        RevenueCatService.shared.isPremium
    }

    enum AppTab: Int, CaseIterable, Identifiable {
        case dashboard = 0
        case journal = 1
        case stats = 2
        case settings = 3

        var id: Int { rawValue }

        var title: String {
            switch self {
            case .dashboard: String(localized: "Home")
            case .journal: String(localized: "Journal")
            case .stats: String(localized: "Stats")
            case .settings: String(localized: "Settings")
            }
        }

        var icon: String {
            switch self {
            case .dashboard: "house.fill"
            case .journal: "book.closed.fill"
            case .stats: "chart.line.uptrend.xyaxis"
            case .settings: "gearshape.fill"
            }
        }

        var iconInactive: String {
            switch self {
            case .dashboard: "house"
            case .journal: "book.closed"
            case .stats: "chart.line.uptrend.xyaxis"
            case .settings: "gearshape"
            }
        }

        var customIcon: String {
            switch self {
            case .dashboard: "Tab-Home"
            case .journal: "Tab-Journal"
            case .stats: "Tab-Streak"
            case .settings: "Tab-Settings"
            }
        }
    }
}

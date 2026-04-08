import SwiftUI
import Observation

@Observable
@MainActor
final class AppState {
    var selectedTab: AppTab = .dashboard
    var showEmergencySOS: Bool = false
    var showDailyCheckIn: Bool = false
    var showPaywall: Bool = false

    /// Derives premium status from RevenueCat — always in sync
    var isPremium: Bool {
        RevenueCatService.shared.isPremium
    }

    enum AppTab: Int, CaseIterable, Identifiable {
        case dashboard = 0
        case journal = 1
        case growth = 2
        case progress = 3
        case insights = 4
        case settings = 5

        var id: Int { rawValue }

        var title: String {
            switch self {
            case .dashboard: "Home"
            case .journal: "Journal"
            case .growth: "Growth"
            case .progress: "Progress"
            case .insights: "Insights"
            case .settings: "Settings"
            }
        }

        var icon: String {
            switch self {
            case .dashboard: "heart.fill"
            case .journal: "book.fill"
            case .growth: "flame.fill"
            case .progress: "chart.line.uptrend.xyaxis"
            case .insights: "brain.head.profile.fill"
            case .settings: "gearshape.fill"
            }
        }

        /// Custom asset-based tab icon name (from asset pack)
        var customIcon: String {
            switch self {
            case .dashboard: "Tab-Home"
            case .journal: "Tab-Journal"
            case .growth: "Tab-Streak"
            case .progress: "Tab-Streak"
            case .insights: "Tab-Community"
            case .settings: "Tab-Settings"
            }
        }
    }
}

import SwiftUI
import Observation

@Observable
final class AppState {
    var selectedTab: AppTab = .dashboard
    var showEmergencySOS: Bool = false
    var showDailyCheckIn: Bool = false
    var showPaywall: Bool = false
    var isPremium: Bool = false

    enum AppTab: Int, CaseIterable, Identifiable {
        case dashboard = 0
        case journal = 1
        case progress = 2
        case insights = 3
        case settings = 4

        var id: Int { rawValue }

        var title: String {
            switch self {
            case .dashboard: "Home"
            case .journal: "Journal"
            case .progress: "Progress"
            case .insights: "Insights"
            case .settings: "Settings"
            }
        }

        var icon: String {
            switch self {
            case .dashboard: "heart.fill"
            case .journal: "book.fill"
            case .progress: "chart.line.uptrend.xyaxis"
            case .insights: "brain.head.profile.fill"
            case .settings: "gearshape.fill"
            }
        }
    }
}

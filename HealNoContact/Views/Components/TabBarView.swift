import SwiftUI
import SwiftData

struct MainTabBarView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        @Bindable var state = appState

        ZStack(alignment: .bottom) {
            TabView(selection: $state.selectedTab) {
                DashboardView()
                    .tag(AppState.AppTab.dashboard)

                JournalListView()
                    .tag(AppState.AppTab.journal)

                StatsView()
                    .tag(AppState.AppTab.stats)

                SettingsView()
                    .tag(AppState.AppTab.settings)
            }
            .tabViewStyle(.automatic)

            // Custom tab bar
            CustomTabBar(selectedTab: $state.selectedTab)
        }
        .sheet(isPresented: $state.showPaywall) {
            PaywallView()
        }
        .onAppear {
            // Present the intro paywall once, right after onboarding finishes.
            if state.pendingIntroPaywall {
                state.pendingIntroPaywall = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    state.showPaywall = true
                }
            }
        }
    }
}

struct CustomTabBar: View {
    @Binding var selectedTab: AppState.AppTab

    var body: some View {
        HStack {
            ForEach(AppState.AppTab.allCases) { tab in
                Button {
                    selectedTab = tab
                    HapticService.selection()
                } label: {
                    let isActive = selectedTab == tab
                    VStack(spacing: 4) {
                        Image(systemName: isActive ? tab.icon : tab.iconInactive)
                            .font(.system(size: 20, weight: isActive ? .semibold : .regular))
                            .symbolEffect(.bounce, value: selectedTab)
                            .frame(height: 22)

                        Text(tab.title)
                            .font(.system(size: 10, weight: isActive ? .semibold : .medium))
                    }
                    .foregroundStyle(
                        isActive
                        ? Color.theme.healPurple
                        : Color.theme.textTertiary
                    )
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.top, 10)
        .padding(.bottom, 20)
        .background(
            Rectangle()
                .fill(.ultraThinMaterial)
                .overlay(
                    Rectangle()
                        .fill(Color.theme.deepBackground.opacity(0.8))
                )
                .ignoresSafeArea(edges: .bottom)
        )
    }
}

import SwiftUI

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

                HealProgressView()
                    .tag(AppState.AppTab.progress)

                InsightsView()
                    .tag(AppState.AppTab.insights)

                SettingsView()
                    .tag(AppState.AppTab.settings)
            }
            .tabViewStyle(.automatic)

            // Custom tab bar
            CustomTabBar(selectedTab: $state.selectedTab)
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
                    VStack(spacing: 4) {
                        Image(tab.customIcon)
                            .renderingMode(.template)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 22, height: 22)

                        Text(tab.title)
                            .font(.system(size: 10, weight: .medium))
                    }
                    .foregroundStyle(
                        selectedTab == tab
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

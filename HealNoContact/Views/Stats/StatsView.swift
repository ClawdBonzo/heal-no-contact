import SwiftUI

struct StatsView: View {
    @Environment(AppState.self) private var appState
    @State private var section: Section = .progress

    enum Section: String, CaseIterable, Identifiable {
        case progress = "Progress"
        case insights = "Insights"
        var id: String { rawValue }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Section", selection: $section) {
                    ForEach(Section.allCases) { s in
                        Text(LocalizedStringKey(s.rawValue)).tag(s)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 12)

                Group {
                    switch section {
                    case .progress: HealProgressView()
                    case .insights:
                        if appState.isPremium {
                            InsightsView()
                        } else {
                            PremiumLockedCard(
                                icon: "brain.head.profile.fill",
                                title: String(localized: "Unlock Advanced Insights"),
                                message: String(localized: "Your healing score, mood pattern detection, and weekly summaries are part of Heal Premium.")
                            ) {
                                appState.showPaywall = true
                            }
                        }
                    }
                }
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.2), value: section)
            }
            .background(Color.theme.deepBackground)
            .onAppear {
                #if DEBUG
                if let t = DemoConfig.shared.statsTab {
                    section = (t == 1) ? .insights : .progress
                }
                #endif
            }
            .navigationTitle("Stats")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}

/// Reusable locked-feature upsell shown where a premium feature would render.
struct PremiumLockedCard: View {
    let icon: String
    let title: String
    let message: String
    let action: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            Spacer(minLength: 40)
            ZStack {
                Circle()
                    .fill(Color.theme.healGold.opacity(0.14))
                    .frame(width: 86, height: 86)
                Image(systemName: icon)
                    .font(.system(size: 34))
                    .foregroundStyle(Color.theme.healGold)
            }
            .overlay(alignment: .bottomTrailing) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(7)
                    .background(Color.theme.healPurple)
                    .clipShape(Circle())
                    .offset(x: 4, y: 4)
            }

            Text(title)
                .font(.title3.weight(.bold))
                .foregroundStyle(Color.theme.textPrimary)
                .multilineTextAlignment(.center)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(Color.theme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)

            Button(action: action) {
                HStack(spacing: 8) {
                    Image(systemName: "crown.fill")
                    Text("Upgrade to Premium")
                        .font(.headline)
                }
                .foregroundStyle(.white)
                .padding(.vertical, 15)
                .padding(.horizontal, 28)
                .background(
                    LinearGradient(
                        colors: [Color.theme.healPurple, Color.theme.healBlue],
                        startPoint: .leading, endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: Color.theme.healPurple.opacity(0.4), radius: 12, y: 4)
            }
            .padding(.top, 4)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 20)
    }
}

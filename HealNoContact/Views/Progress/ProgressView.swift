import SwiftUI
import SwiftData

struct HealProgressView: View {
    @Query(sort: \Milestone.dayTarget) private var milestones: [Milestone]
    @Query(sort: \MoodEntry.createdAt) private var moodEntries: [MoodEntry]
    @Query(sort: \EmergencyLog.createdAt, order: .reverse) private var emergencyLogs: [EmergencyLog]
    @Query private var profiles: [UserProfile]

    private var profile: UserProfile? { profiles.first }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Overall stats
                    if let profile {
                        OverallStatsSection(
                            profile: profile,
                            emergencyCount: emergencyLogs.count,
                            resistedCount: emergencyLogs.filter(\.didResist).count
                        )
                    }

                    // Milestones timeline
                    MilestonesSection(
                        milestones: milestones,
                        currentDays: profile?.currentStreakDays ?? 0
                    )

                    // Mood trend
                    if moodEntries.count >= 2 {
                        MoodTrendSection(entries: moodEntries)
                    }

                    // Emergency log summary
                    if !emergencyLogs.isEmpty {
                        EmergencyLogSection(logs: emergencyLogs)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 100)
            }
            .scrollIndicators(.hidden)
            .background(Color.theme.deepBackground)
            .navigationTitle("Progress")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}

// MARK: - Overall Stats

private struct OverallStatsSection: View {
    let profile: UserProfile
    let emergencyCount: Int
    let resistedCount: Int

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                StatCard(
                    value: "\(profile.currentStreakDays)",
                    label: "Current Streak",
                    icon: "flame.fill",
                    color: Color.theme.healPurple
                )
                StatCard(
                    value: "\(max(profile.streakBestDays, profile.currentStreakDays))",
                    label: "Best Streak",
                    icon: "trophy.fill",
                    color: Color.theme.healGold
                )
            }
            HStack(spacing: 12) {
                StatCard(
                    value: "\(profile.daysSinceBreakup)",
                    label: "Days Since BU",
                    icon: "calendar",
                    color: Color.theme.healTeal
                )
                StatCard(
                    value: "\(resistedCount)/\(emergencyCount)",
                    label: "Urges Resisted",
                    icon: "shield.fill",
                    color: Color.theme.healPink
                )
            }
        }
    }
}

private struct StatCard: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)

            Text(value)
                .font(.title2.weight(.bold).monospacedDigit())
                .foregroundStyle(Color.theme.textPrimary)

            Text(label)
                .font(.caption)
                .foregroundStyle(Color.theme.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.theme.cardBackground)
        )
    }
}

// MARK: - Milestones Section

private struct MilestonesSection: View {
    let milestones: [Milestone]
    let currentDays: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Milestones")
                .font(.headline)
                .foregroundStyle(Color.theme.textPrimary)

            ForEach(milestones) { milestone in
                MilestoneCardView(
                    milestone: milestone,
                    currentDays: currentDays
                )
            }
        }
    }
}

// MARK: - Mood Trend

private struct MoodTrendSection: View {
    let entries: [MoodEntry]

    private var averageMood: Double {
        guard !entries.isEmpty else { return 0 }
        let sum = entries.reduce(0) { $0 + $1.mood.numericValue }
        return Double(sum) / Double(entries.count)
    }

    private var trend: String {
        guard entries.count >= 2 else { return "Not enough data" }
        let recent = Array(entries.suffix(7))
        let older = Array(entries.prefix(max(entries.count - 7, 1)))

        let recentAvg = Double(recent.reduce(0) { $0 + $1.mood.numericValue }) / Double(recent.count)
        let olderAvg = Double(older.reduce(0) { $0 + $1.mood.numericValue }) / Double(older.count)

        if recentAvg > olderAvg + 0.5 { return "Trending up" }
        if recentAvg < olderAvg - 0.5 { return "Trending down" }
        return "Stable"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Mood Trend")
                .font(.headline)
                .foregroundStyle(Color.theme.textPrimary)

            HStack(spacing: 20) {
                VStack(spacing: 4) {
                    Text(String(format: "%.1f", averageMood))
                        .font(.title.weight(.bold).monospacedDigit())
                        .foregroundStyle(Color.theme.textPrimary)
                    Text("Avg / 7")
                        .font(.caption)
                        .foregroundStyle(Color.theme.textTertiary)
                }

                VStack(spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: trend == "Trending up" ? "arrow.up.right" :
                                trend == "Trending down" ? "arrow.down.right" : "arrow.right")
                            .foregroundStyle(
                                trend == "Trending up" ? Color.theme.healTeal :
                                trend == "Trending down" ? Color.theme.healPink :
                                Color.theme.textSecondary
                            )
                        Text(trend)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Color.theme.textPrimary)
                    }
                    Text("\(entries.count) check-ins")
                        .font(.caption)
                        .foregroundStyle(Color.theme.textTertiary)
                }

                Spacer()
            }
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.theme.cardBackground)
            )

            // Mini mood bars
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 3) {
                    ForEach(entries.suffix(30)) { entry in
                        VStack(spacing: 4) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.theme.moodColor(entry.mood))
                                .frame(
                                    width: 8,
                                    height: CGFloat(entry.mood.numericValue) * 6
                                )

                            Text(entry.mood.emoji)
                                .font(.system(size: 8))
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Emergency Logs

private struct EmergencyLogSection: View {
    let logs: [EmergencyLog]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Emergency Sessions")
                .font(.headline)
                .foregroundStyle(Color.theme.textPrimary)

            ForEach(logs.prefix(5)) { log in
                HStack(spacing: 12) {
                    Image(systemName: log.didResist
                          ? "checkmark.shield.fill" : "exclamationmark.triangle.fill")
                        .foregroundStyle(
                            log.didResist ? Color.theme.healTeal : Color.theme.healPink
                        )

                    VStack(alignment: .leading, spacing: 2) {
                        Text(log.didResist ? "Resisted" : "Slipped")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Color.theme.textPrimary)

                        Text("\(log.durationSeconds / 60)m • \(log.createdAt.relativeFormatted)")
                            .font(.caption)
                            .foregroundStyle(Color.theme.textTertiary)
                    }

                    Spacer()

                    Text("Level \(log.intensityLevel)")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Color.theme.textSecondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color.theme.cardBackground))
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.theme.cardBackground)
                )
            }
        }
    }
}

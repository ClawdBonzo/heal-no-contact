import SwiftUI
import SwiftData

struct InsightsView: View {
    @Query(sort: \JournalEntry.createdAt, order: .reverse) private var journals: [JournalEntry]
    @Query(sort: \MoodEntry.createdAt, order: .reverse) private var moods: [MoodEntry]
    @Query(sort: \EmergencyLog.createdAt, order: .reverse) private var emergencyLogs: [EmergencyLog]
    @Query private var profiles: [UserProfile]
    @Query(sort: \LetterEntry.createdAt, order: .reverse) private var letters: [LetterEntry]

    private var profile: UserProfile? { profiles.first }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Healing score
                    if let profile {
                        HealingScoreCard(profile: profile, moods: moods)
                    }

                    // Weekly summary
                    WeeklySummaryCard(
                        journalCount: weeklyJournals.count,
                        checkInCount: weeklyMoods.count,
                        emergencyCount: weeklyEmergencies.count
                    )

                    // Patterns
                    if moods.count >= 7 {
                        PatternsCard(moods: moods)
                    }

                    // Journaling streak
                    JournalingStreakCard(entries: journals)

                    // Letters written
                    if !letters.isEmpty {
                        LettersCard(count: letters.count)
                    }

                    // Motivational
                    InsightQuoteCard()
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 100)
            }
            .scrollIndicators(.hidden)
            .background(Color.theme.deepBackground)
            .navigationTitle("Insights")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    private var weeklyJournals: [JournalEntry] {
        let weekAgo = Date.now.adding(days: -7)
        return journals.filter { $0.createdAt > weekAgo }
    }

    private var weeklyMoods: [MoodEntry] {
        let weekAgo = Date.now.adding(days: -7)
        return moods.filter { $0.createdAt > weekAgo }
    }

    private var weeklyEmergencies: [EmergencyLog] {
        let weekAgo = Date.now.adding(days: -7)
        return emergencyLogs.filter { $0.createdAt > weekAgo }
    }
}

// MARK: - Healing Score

private struct HealingScoreCard: View {
    let profile: UserProfile
    let moods: [MoodEntry]

    private var score: Int {
        var s = 0

        // Streak contribution (max 40)
        s += min(profile.currentStreakDays * 2, 40)

        // Recent mood contribution (max 30)
        let recentMoods = moods.prefix(7)
        if !recentMoods.isEmpty {
            let avg = Double(recentMoods.reduce(0) { $0 + $1.mood.numericValue }) / Double(recentMoods.count)
            s += Int((avg / 7.0) * 30)
        }

        // Consistency (max 30)
        let uniqueDays = Set(moods.prefix(14).map { Calendar.current.startOfDay(for: $0.createdAt) }).count
        s += min(uniqueDays * 4, 30)

        return min(s, 100)
    }

    var body: some View {
        VStack(spacing: 16) {
            Text("Healing Score")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.theme.textSecondary)

            ZStack {
                Circle()
                    .stroke(Color.theme.textTertiary.opacity(0.15), lineWidth: 10)
                    .frame(width: 120, height: 120)

                Circle()
                    .trim(from: 0, to: Double(score) / 100.0)
                    .stroke(
                        AngularGradient(
                            colors: [Color.theme.healTeal, Color.theme.healBlue, Color.theme.healPurple],
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 10, lineCap: .round)
                    )
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 2) {
                    Text("\(score)")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.theme.textPrimary)
                    Text("/ 100")
                        .font(.caption)
                        .foregroundStyle(Color.theme.textTertiary)
                }
            }

            Text(scoreMessage)
                .font(.subheadline)
                .foregroundStyle(Color.theme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.theme.cardBackground)
        )
    }

    private var scoreMessage: String {
        switch score {
        case 0..<20: return "Just starting out. Every journey begins here."
        case 20..<40: return "Building momentum. Keep going!"
        case 40..<60: return "You're making real progress."
        case 60..<80: return "Strong and steady. You're thriving."
        default: return "Incredible healing. You're inspiring."
        }
    }
}

// MARK: - Weekly Summary

private struct WeeklySummaryCard: View {
    let journalCount: Int
    let checkInCount: Int
    let emergencyCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("This Week")
                .font(.headline)
                .foregroundStyle(Color.theme.textPrimary)

            HStack(spacing: 16) {
                WeekStat(value: "\(journalCount)", label: "Entries", icon: "book.fill", color: Color.theme.healPurple)
                WeekStat(value: "\(checkInCount)", label: "Check-ins", icon: "checkmark.circle.fill", color: Color.theme.healTeal)
                WeekStat(value: "\(emergencyCount)", label: "SOS Used", icon: "sos", color: Color.theme.healPink)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.theme.cardBackground)
        )
    }
}

private struct WeekStat: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(color)
            Text(value)
                .font(.title3.weight(.bold))
                .foregroundStyle(Color.theme.textPrimary)
            Text(label)
                .font(.caption2)
                .foregroundStyle(Color.theme.textTertiary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Patterns

private struct PatternsCard: View {
    let moods: [MoodEntry]

    private var mostCommonMood: JournalEntry.MoodType? {
        let counts = Dictionary(grouping: moods, by: \.mood).mapValues(\.count)
        return counts.max(by: { $0.value < $1.value })?.key
    }

    private var hardestTimeOfDay: String {
        let hourCounts = Dictionary(grouping: moods.filter { $0.mood.numericValue <= 3 }) {
            Calendar.current.component(.hour, from: $0.createdAt)
        }.mapValues(\.count)

        guard let peak = hourCounts.max(by: { $0.value < $1.value })?.key else {
            return "No pattern yet"
        }

        switch peak {
        case 6..<12: return "Mornings"
        case 12..<17: return "Afternoons"
        case 17..<21: return "Evenings"
        default: return "Late nights"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Patterns")
                .font(.headline)
                .foregroundStyle(Color.theme.textPrimary)

            if let mood = mostCommonMood {
                PatternRow(
                    icon: mood.emoji,
                    label: "Most common mood",
                    value: mood.rawValue
                )
            }

            PatternRow(
                icon: "clock.fill",
                label: "Hardest time",
                value: hardestTimeOfDay
            )
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.theme.cardBackground)
        )
    }
}

private struct PatternRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack {
            if icon.count <= 2 {
                Text(icon).font(.title3)
            } else {
                Image(systemName: icon)
                    .foregroundStyle(Color.theme.healPurple)
            }

            Text(label)
                .font(.subheadline)
                .foregroundStyle(Color.theme.textSecondary)

            Spacer()

            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.theme.textPrimary)
        }
    }
}

// MARK: - Journaling Streak

private struct JournalingStreakCard: View {
    let entries: [JournalEntry]

    private var journalingStreak: Int {
        guard !entries.isEmpty else { return 0 }
        var streak = 0
        var currentDate = Date.now.startOfDay

        for _ in 0..<365 {
            let hasEntry = entries.contains {
                Calendar.current.isDate($0.createdAt, inSameDayAs: currentDate)
            }
            if hasEntry {
                streak += 1
                currentDate = currentDate.adding(days: -1)
            } else {
                break
            }
        }
        return streak
    }

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "pencil.and.outline")
                .font(.title2)
                .foregroundStyle(Color.theme.healPurple)
                .frame(width: 44, height: 44)
                .background(Color.theme.healPurple.opacity(0.15))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text("Journaling Streak")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.theme.textPrimary)

                Text("\(journalingStreak) consecutive \(journalingStreak == 1 ? "day" : "days")")
                    .font(.caption)
                    .foregroundStyle(Color.theme.textSecondary)
            }

            Spacer()

            Text("\(entries.count)")
                .font(.title3.weight(.bold))
                .foregroundStyle(Color.theme.healPurple)
            Text("total")
                .font(.caption)
                .foregroundStyle(Color.theme.textTertiary)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.theme.cardBackground)
        )
    }
}

// MARK: - Letters Card

private struct LettersCard: View {
    let count: Int

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "envelope.fill")
                .font(.title2)
                .foregroundStyle(Color.theme.healPink)
                .frame(width: 44, height: 44)
                .background(Color.theme.healPink.opacity(0.15))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text("Unsent Letters")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.theme.textPrimary)

                Text("\(count) \(count == 1 ? "letter" : "letters") written and sealed")
                    .font(.caption)
                    .foregroundStyle(Color.theme.textSecondary)
            }

            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.theme.cardBackground)
        )
    }
}

// MARK: - Quote Card

private struct InsightQuoteCard: View {
    private let quote = QuoteService.shared.randomQuote()

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "sparkles")
                .foregroundStyle(Color.theme.healGold)

            Text(quote.text)
                .font(.subheadline)
                .foregroundStyle(Color.theme.textPrimary)
                .multilineTextAlignment(.center)
                .lineSpacing(3)

            Text("�� \(quote.author)")
                .font(.caption)
                .foregroundStyle(Color.theme.textTertiary)
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.theme.cardBackground)
        )
    }
}

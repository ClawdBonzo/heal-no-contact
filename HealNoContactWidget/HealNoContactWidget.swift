import WidgetKit
import SwiftUI
import SwiftData

// MARK: - Streak Widget

struct StreakEntry: TimelineEntry {
    let date: Date
    let streakDays: Int
    let goalDays: Int
}

struct StreakProvider: TimelineProvider {
    func placeholder(in context: Context) -> StreakEntry {
        StreakEntry(date: .now, streakDays: 12, goalDays: 30)
    }

    func getSnapshot(in context: Context, completion: @escaping (StreakEntry) -> Void) {
        completion(StreakEntry(date: .now, streakDays: 12, goalDays: 30))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<StreakEntry>) -> Void) {
        // In production, read from shared UserDefaults or SwiftData
        let entry = StreakEntry(date: .now, streakDays: 0, goalDays: 30)
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: .now)!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

struct StreakWidgetView: View {
    var entry: StreakEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            SmallStreakView(entry: entry)
        case .systemMedium:
            MediumStreakView(entry: entry)
        default:
            SmallStreakView(entry: entry)
        }
    }
}

private struct SmallStreakView: View {
    let entry: StreakEntry

    private var progress: Double {
        guard entry.goalDays > 0 else { return 0 }
        return min(Double(entry.streakDays) / Double(entry.goalDays), 1.0)
    }

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(Color.purple.opacity(0.2), lineWidth: 6)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        LinearGradient(
                            colors: [.blue, .purple, .pink],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 0) {
                    Text("\(entry.streakDays)")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Text("days")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 80, height: 80)

            Text("No Contact")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .containerBackground(for: .widget) {
            ZStack {
                Color(red: 0.06, green: 0.04, blue: 0.12)
                Image("Widget-Small")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .opacity(0.15)
            }
        }
    }
}

private struct MediumStreakView: View {
    let entry: StreakEntry

    private var progress: Double {
        guard entry.goalDays > 0 else { return 0 }
        return min(Double(entry.streakDays) / Double(entry.goalDays), 1.0)
    }

    var body: some View {
        HStack(spacing: 20) {
            ZStack {
                Circle()
                    .stroke(Color.purple.opacity(0.2), lineWidth: 8)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        LinearGradient(
                            colors: [.blue, .purple, .pink],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 0) {
                    Text("\(entry.streakDays)")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Text("days")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 90, height: 90)

            VStack(alignment: .leading, spacing: 6) {
                Text("No Contact Streak")
                    .font(.headline)
                    .foregroundStyle(.white)

                Text("\(Int(progress * 100))% of \(entry.goalDays)-day goal")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text("Keep going, you're doing great!")
                    .font(.caption)
                    .foregroundStyle(Color.purple.opacity(0.8))
            }
        }
        .containerBackground(for: .widget) {
            ZStack {
                Color(red: 0.06, green: 0.04, blue: 0.12)
                Image("Widget-Medium")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .opacity(0.12)
            }
        }
    }
}

struct StreakWidget: Widget {
    let kind: String = "StreakWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: StreakProvider()) { entry in
            StreakWidgetView(entry: entry)
        }
        .configurationDisplayName("No-Contact Streak")
        .description("See your current no-contact streak at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Mantra Widget

struct MantraEntry: TimelineEntry {
    let date: Date
    let mantra: String
}

struct MantraProvider: TimelineProvider {
    func placeholder(in context: Context) -> MantraEntry {
        MantraEntry(date: .now, mantra: "I choose myself today and every day")
    }

    func getSnapshot(in context: Context, completion: @escaping (MantraEntry) -> Void) {
        completion(MantraEntry(date: .now, mantra: "I choose myself today and every day"))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<MantraEntry>) -> Void) {
        let entry = MantraEntry(date: .now, mantra: "I choose myself today and every day")
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 6, to: .now)!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

struct MantraWidgetView: View {
    var entry: MantraEntry

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "sparkles")
                .font(.title3)
                .foregroundStyle(
                    LinearGradient(
                        colors: [.purple, .pink],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Text(entry.mantra)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .minimumScaleFactor(0.8)
        }
        .padding()
        .containerBackground(for: .widget) {
            ZStack {
                Color(red: 0.06, green: 0.04, blue: 0.12)
                Image("Widget-Small")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .opacity(0.12)
            }
        }
    }
}

struct MantraWidget: Widget {
    let kind: String = "MantraWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MantraProvider()) { entry in
            MantraWidgetView(entry: entry)
        }
        .configurationDisplayName("Daily Mantra")
        .description("Your personal healing mantra on your home screen.")
        .supportedFamilies([.systemSmall])
    }
}

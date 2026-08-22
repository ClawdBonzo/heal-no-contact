import WidgetKit
import SwiftUI

// MARK: - Shared store

private let widgetAppGroup = "group.com.clawdbonzo.HealNoContact"

/// What the app writes (see WidgetSync in the app target — keys must match exactly).
private struct Snapshot {
    let streakStart: Date?
    let legacyDays: Int
    let goalDays: Int
    let mantra: String?
    let checkedInDay: String?

    static func load() -> Snapshot {
        let d = UserDefaults(suiteName: widgetAppGroup)
        let startInterval = d?.double(forKey: "widget.streakStart") ?? 0
        return Snapshot(
            streakStart: startInterval > 0 ? Date(timeIntervalSince1970: startInterval) : nil,
            legacyDays: d?.integer(forKey: "widget.streakDays") ?? 0,
            goalDays: max(d?.integer(forKey: "widget.goalDays") ?? 30, 1),
            mantra: d?.string(forKey: "widget.mantra"),
            checkedInDay: d?.string(forKey: "widget.checkedInDay")
        )
    }

    /// Whole days of no contact as of `date` — computed here so the number advances at
    /// midnight without the app ever being opened.
    func streakDays(at date: Date) -> Int {
        guard let streakStart else { return legacyDays }
        return max(Calendar.current.dateComponents([.day], from: streakStart, to: date).day ?? 0, 0)
    }

    func checkedIn(on date: Date) -> Bool {
        let c = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return checkedInDay == String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }
}

// MARK: - Streak Widget

struct StreakEntry: TimelineEntry {
    let date: Date
    let streakDays: Int
    let goalDays: Int
    let checkedInToday: Bool
}

struct StreakProvider: TimelineProvider {
    func placeholder(in context: Context) -> StreakEntry {
        StreakEntry(date: .now, streakDays: 12, goalDays: 30, checkedInToday: false)
    }

    func getSnapshot(in context: Context, completion: @escaping (StreakEntry) -> Void) {
        if context.isPreview {
            completion(placeholder(in: context)); return
        }
        let s = Snapshot.load()
        completion(StreakEntry(date: .now, streakDays: s.streakDays(at: .now), goalDays: s.goalDays,
                               checkedInToday: s.checkedIn(on: .now)))
    }

    /// One entry now plus one at each of the next 7 midnights, so the day count rolls over
    /// on its own. The app still reloads timelines whenever something changes.
    func getTimeline(in context: Context, completion: @escaping (Timeline<StreakEntry>) -> Void) {
        let s = Snapshot.load()
        let cal = Calendar.current
        var entries: [StreakEntry] = [
            StreakEntry(date: .now, streakDays: s.streakDays(at: .now), goalDays: s.goalDays,
                        checkedInToday: s.checkedIn(on: .now))
        ]
        var day = cal.startOfDay(for: .now)
        for _ in 0..<7 {
            guard let next = cal.date(byAdding: .day, value: 1, to: day) else { break }
            day = next
            entries.append(StreakEntry(date: day, streakDays: s.streakDays(at: day), goalDays: s.goalDays,
                                       checkedInToday: false))
        }
        completion(Timeline(entries: entries, policy: .atEnd))
    }
}

struct StreakWidgetView: View {
    var entry: StreakEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemMedium:       MediumStreakView(entry: entry)
        case .accessoryCircular:  CircularStreakView(entry: entry)
        case .accessoryRectangular: RectangularStreakView(entry: entry)
        case .accessoryInline:    Text("🔥 \(entry.streakDays) days no contact")
        default:                  SmallStreakView(entry: entry)
        }
    }
}

private func progress(_ e: StreakEntry) -> Double {
    min(Double(e.streakDays) / Double(max(e.goalDays, 1)), 1.0)
}

private struct Ring: View {
    let progress: Double
    let lineWidth: CGFloat
    var body: some View {
        ZStack {
            Circle().stroke(Color.purple.opacity(0.2), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    LinearGradient(colors: [.blue, .purple, .pink], startPoint: .topLeading, endPoint: .bottomTrailing),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
        }
    }
}

private struct SmallStreakView: View {
    let entry: StreakEntry

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Ring(progress: progress(entry), lineWidth: 6)
                VStack(spacing: 0) {
                    Text("\(entry.streakDays)")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .contentTransition(.numericText())
                    Text("days")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
            .frame(width: 80, height: 80)

            Text("No Contact")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .widgetURL(URL(string: "heal://home"))
        .containerBackground(for: .widget) { WidgetBackground(image: "Widget-Small") }
        .accessibilityLabel(Text("\(entry.streakDays) days of no contact"))
    }
}

private struct MediumStreakView: View {
    let entry: StreakEntry

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Ring(progress: progress(entry), lineWidth: 7)
                VStack(spacing: 0) {
                    Text("\(entry.streakDays)")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .contentTransition(.numericText())
                    Text("days")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
            .frame(width: 92, height: 92)

            VStack(alignment: .leading, spacing: 6) {
                Text("No Contact Streak")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)

                Text("\(Int(progress(entry) * 100))% of \(entry.goalDays)-day goal")
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.7))

                Spacer(minLength: 0)

                // One tap to today's check-in (or a reminder that it's done).
                Link(destination: URL(string: "heal://checkin")!) {
                    HStack(spacing: 6) {
                        Image(systemName: entry.checkedInToday ? "checkmark.seal.fill" : "checkmark.circle.fill")
                        Text(entry.checkedInToday ? "Checked in today" : "Check in")
                    }
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(entry.checkedInToday ? Color.teal : .white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(
                        Capsule().fill(entry.checkedInToday ? Color.teal.opacity(0.18) : Color.purple.opacity(0.8))
                    )
                }
            }
            Spacer(minLength: 0)
        }
        .widgetURL(URL(string: "heal://home"))
        .containerBackground(for: .widget) { WidgetBackground(image: "Widget-Medium") }
    }
}

private struct CircularStreakView: View {
    let entry: StreakEntry
    var body: some View {
        Gauge(value: progress(entry)) {
            Image(systemName: "flame.fill")
        } currentValueLabel: {
            Text("\(entry.streakDays)")
                .font(.system(size: 18, weight: .bold, design: .rounded))
        }
        .gaugeStyle(.accessoryCircularCapacity)
        .widgetURL(URL(string: "heal://home"))
        .containerBackground(for: .widget) { Color.clear }
        .accessibilityLabel(Text("\(entry.streakDays) days of no contact"))
    }
}

private struct RectangularStreakView: View {
    let entry: StreakEntry
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "flame.fill")
                .font(.title2)
            VStack(alignment: .leading, spacing: 2) {
                Text("\(entry.streakDays) days no contact")
                    .font(.headline)
                Text("\(Int(progress(entry) * 100))% of \(entry.goalDays)-day goal")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .widgetURL(URL(string: "heal://home"))
        .containerBackground(for: .widget) { Color.clear }
    }
}

private struct WidgetBackground: View {
    let image: String
    var body: some View {
        ZStack {
            Color(red: 0.06, green: 0.04, blue: 0.12)
            Image(image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .opacity(0.14)
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
        .description("Your streak, counting up on its own — and one tap to check in.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}

// MARK: - SOS Widget (lock screen / home): one tap into the emergency toolkit

struct SOSEntry: TimelineEntry { let date: Date }

struct SOSProvider: TimelineProvider {
    func placeholder(in context: Context) -> SOSEntry { SOSEntry(date: .now) }
    func getSnapshot(in context: Context, completion: @escaping (SOSEntry) -> Void) { completion(SOSEntry(date: .now)) }
    func getTimeline(in context: Context, completion: @escaping (Timeline<SOSEntry>) -> Void) {
        completion(Timeline(entries: [SOSEntry(date: .now)], policy: .never))
    }
}

struct SOSWidgetView: View {
    @Environment(\.widgetFamily) var family
    var body: some View {
        Group {
            switch family {
            case .accessoryCircular:
                ZStack {
                    AccessoryWidgetBackground()
                    Image(systemName: "heart.fill").font(.title2)
                }
            case .accessoryInline:
                Text("❤️ I need help now")
            default:
                VStack(spacing: 8) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundStyle(LinearGradient(colors: [.pink, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                    Text("I need help now")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                }
                .containerBackground(for: .widget) { WidgetBackground(image: "Widget-Small") }
            }
        }
        .widgetURL(URL(string: "heal://sos"))
        .accessibilityLabel(Text("Open emergency support"))
    }
}

struct SOSWidget: Widget {
    let kind: String = "SOSWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SOSProvider()) { _ in
            SOSWidgetView()
        }
        .configurationDisplayName("SOS")
        .description("One tap to breathing, coping strategies and your mantra when the urge hits.")
        .supportedFamilies([.systemSmall, .accessoryCircular, .accessoryInline])
    }
}

// MARK: - Mantra Widget

struct MantraEntry: TimelineEntry {
    let date: Date
    let mantra: String
}

struct MantraProvider: TimelineProvider {
    private static var fallback: String { String(localized: "I choose myself today and every day") }

    private func liveEntry() -> MantraEntry {
        let stored = Snapshot.load().mantra
        let mantra = (stored?.isEmpty == false) ? stored! : Self.fallback
        return MantraEntry(date: .now, mantra: mantra)
    }

    func placeholder(in context: Context) -> MantraEntry {
        MantraEntry(date: .now, mantra: Self.fallback)
    }

    func getSnapshot(in context: Context, completion: @escaping (MantraEntry) -> Void) {
        completion(context.isPreview ? MantraEntry(date: .now, mantra: Self.fallback) : liveEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<MantraEntry>) -> Void) {
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 6, to: .now)!
        completion(Timeline(entries: [liveEntry()], policy: .after(nextUpdate)))
    }
}

struct MantraWidgetView: View {
    var entry: MantraEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        Group {
            if family == .accessoryRectangular {
                Text(entry.mantra)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .lineLimit(3)
                    .containerBackground(for: .widget) { Color.clear }
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.title3)
                        .foregroundStyle(LinearGradient(colors: [.purple, .pink], startPoint: .topLeading, endPoint: .bottomTrailing))
                    Text(entry.mantra)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                        .minimumScaleFactor(0.8)
                }
                .padding()
                .containerBackground(for: .widget) { WidgetBackground(image: "Widget-Small") }
            }
        }
        .widgetURL(URL(string: "heal://home"))
    }
}

struct MantraWidget: Widget {
    let kind: String = "MantraWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MantraProvider()) { entry in
            MantraWidgetView(entry: entry)
        }
        .configurationDisplayName("Daily Mantra")
        .description("Your personal healing mantra on your home or lock screen.")
        .supportedFamilies([.systemSmall, .accessoryRectangular])
    }
}

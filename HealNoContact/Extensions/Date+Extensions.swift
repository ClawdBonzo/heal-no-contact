import Foundation

extension Date {
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }

    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }

    var isYesterday: Bool {
        Calendar.current.isDateInYesterday(self)
    }

    /// "Today" / "Yesterday" / weekday / "Aug 17" / "Aug 17, 2025" — all locale-aware.
    var relativeFormatted: String {
        if isToday { return String(localized: "Today") }
        if isYesterday { return String(localized: "Yesterday") }
        let daysDiff = Calendar.current.dateComponents([.day], from: self, to: .now).day ?? 0
        if daysDiff < 7 {
            return formatted(.dateTime.weekday(.wide))
        } else if daysDiff < 365 {
            return formatted(.dateTime.month(.abbreviated).day())
        } else {
            return formatted(.dateTime.month(.abbreviated).day().year())
        }
    }

    /// Respects the user's 12/24-hour setting.
    var shortTime: String {
        formatted(date: .omitted, time: .shortened)
    }

    var monthDay: String {
        formatted(.dateTime.month(.abbreviated).day())
    }

    func daysUntil(_ date: Date) -> Int {
        Calendar.current.dateComponents([.day], from: self.startOfDay, to: date.startOfDay).day ?? 0
    }

    func adding(days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: self) ?? self
    }

    static func daysBetween(_ from: Date, _ to: Date) -> Int {
        Calendar.current.dateComponents([.day], from: from.startOfDay, to: to.startOfDay).day ?? 0
    }
}

extension Int {
    var daysFormatted: String {
        if self == 1 { return "1 day" }
        return "\(self) days"
    }

    var compactDaysFormatted: String {
        if self < 30 { return "\(self)d" }
        if self < 365 { return "\(self / 30)mo" }
        return "\(self / 365)y"
    }
}

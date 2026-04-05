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

    var relativeFormatted: String {
        if isToday { return "Today" }
        if isYesterday { return "Yesterday" }

        let formatter = DateFormatter()
        let daysDiff = Calendar.current.dateComponents([.day], from: self, to: .now).day ?? 0

        if daysDiff < 7 {
            formatter.dateFormat = "EEEE"
        } else if daysDiff < 365 {
            formatter.dateFormat = "MMM d"
        } else {
            formatter.dateFormat = "MMM d, yyyy"
        }
        return formatter.string(from: self)
    }

    var shortTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: self)
    }

    var monthDay: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: self)
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

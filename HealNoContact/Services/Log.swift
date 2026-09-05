import OSLog

/// Unified logging categories. Prefer these over `print` so messages carry
/// subsystem/category metadata and are visible in Console.app for release builds.
enum Log {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.clawdbonzo.HealNoContact"

    static let app = Logger(subsystem: subsystem, category: "app")
    static let purchases = Logger(subsystem: subsystem, category: "purchases")
    static let reviews   = Logger(subsystem: subsystem, category: "reviews")
}

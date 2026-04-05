import SwiftUI

extension Color {
    static let theme = ColorTheme()
}

struct ColorTheme {
    let accent = Color("AccentColor", bundle: nil)
    let healPurple = Color(red: 0.55, green: 0.35, blue: 0.95)
    let healBlue = Color(red: 0.30, green: 0.50, blue: 0.95)
    let healPink = Color(red: 0.90, green: 0.35, blue: 0.55)
    let healTeal = Color(red: 0.30, green: 0.80, blue: 0.75)
    let healGold = Color(red: 0.95, green: 0.75, blue: 0.30)

    let cardBackground = Color(white: 0.12)
    let surfaceBackground = Color(white: 0.08)
    let deepBackground = Color(red: 0.04, green: 0.03, blue: 0.08)

    let textPrimary = Color.white
    let textSecondary = Color(white: 0.65)
    let textTertiary = Color(white: 0.40)

    var gradientPrimary: LinearGradient {
        LinearGradient(
            colors: [healPurple, healBlue],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var gradientWarm: LinearGradient {
        LinearGradient(
            colors: [healPink, healPurple],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var gradientHope: LinearGradient {
        LinearGradient(
            colors: [healTeal, healBlue],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var gradientBackground: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.06, green: 0.04, blue: 0.12),
                Color(red: 0.03, green: 0.02, blue: 0.06)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    func moodColor(_ mood: JournalEntry.MoodType) -> Color {
        switch mood {
        case .devastated: Color(red: 0.85, green: 0.20, blue: 0.25)
        case .sad: Color(red: 0.40, green: 0.50, blue: 0.90)
        case .anxious: Color(red: 0.90, green: 0.60, blue: 0.20)
        case .neutral: Color(white: 0.55)
        case .hopeful: Color(red: 0.40, green: 0.80, blue: 0.55)
        case .strong: Color(red: 0.55, green: 0.35, blue: 0.95)
        case .grateful: Color(red: 0.95, green: 0.75, blue: 0.30)
        }
    }
}

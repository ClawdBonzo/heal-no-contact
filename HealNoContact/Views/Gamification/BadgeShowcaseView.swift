import SwiftUI

struct BadgeShowcaseView: View {
    let badges: [Badge]
    let allBadges: [(id: String, title: String, details: String, icon: String, rarity: Badge.Rarity)]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Achievements")
                .font(.headline.weight(.bold))
                .foregroundStyle(Color.theme.textPrimary)

            if badges.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(Color.theme.textTertiary)

                    Text("Earn badges through your healing journey")
                        .font(.caption)
                        .foregroundStyle(Color.theme.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(24)
                .background(Color.theme.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(badges, id: \.id) { badge in
                        BadgeCardView(badge: badge)
                    }
                }
            }
        }
    }
}

struct BadgeCardView: View {
    let badge: Badge

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: badge.icon)
                .font(.system(size: 28))
                .foregroundStyle(colorForRarity(badge.rarity))
                .frame(height: 40)

            Text(badge.title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.theme.textPrimary)
                .lineLimit(2)
                .multilineTextAlignment(.center)

            Text(badge.details)
                .font(.caption2)
                .foregroundStyle(Color.theme.textSecondary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(Color.theme.cardBackground)
        .border(
            colorForRarity(badge.rarity).opacity(0.3),
            width: 1.5
        )
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func colorForRarity(_ rarity: Badge.Rarity) -> Color {
        switch rarity {
        case .common: return .gray
        case .rare: return Color.theme.healBlue
        case .epic: return Color.theme.healPurple
        case .legendary: return Color.theme.healGold
        }
    }
}

#Preview {
    let badge = Badge(
        userId: UUID(),
        badgeId: "test",
        title: "Test Badge",
        details: "Test description",
        icon: "star.fill",
        rarity: .rare
    )

    return BadgeShowcaseView(badges: [badge], allBadges: [])
        .preferredColorScheme(.dark)
}

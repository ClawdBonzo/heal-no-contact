import SwiftUI

/// Every badge the app can award, locked ones dimmed — so the next goal is always visible.
struct BadgeCatalogView: View {
    @Environment(GameificationService.self) private var game

    private let columns = [GridItem(.adaptive(minimum: 96), spacing: 10)]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(GameificationService.catalog, id: \.id) { spec in
                let unlocked = game.hasBadge(spec.id)
                VStack(spacing: 6) {
                    Image(systemName: unlocked ? spec.icon : "lock.fill")
                        .font(.title3)
                        .foregroundStyle(unlocked ? tint(spec.rarity) : Color.theme.textTertiary)
                        .frame(width: 44, height: 44)
                        .background((unlocked ? tint(spec.rarity) : Color.theme.textTertiary).opacity(0.12), in: Circle())
                    Text(spec.title)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(unlocked ? Color.theme.textPrimary : Color.theme.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                    Text(spec.details)
                        .font(.system(size: 9))
                        .foregroundStyle(Color.theme.textTertiary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .padding(.horizontal, 6)
                .background(RoundedRectangle(cornerRadius: 14).fill(Color.theme.cardBackground))
                .opacity(unlocked ? 1 : 0.7)
                .accessibilityElement(children: .combine)
                .accessibilityValue(Text(unlocked ? String(localized: "Unlocked") : String(localized: "Locked")))
            }
        }
    }

    private func tint(_ r: Badge.Rarity) -> Color {
        switch r {
        case .common: return Color.theme.healTeal
        case .rare: return Color.theme.healBlue
        case .epic: return Color.theme.healPurple
        case .legendary: return Color.theme.healGold
        }
    }
}

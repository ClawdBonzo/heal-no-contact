import SwiftUI

struct StreakFlameView: View {
    let flame: StreakFlame

    var flameColor: Color {
        switch flame.currentFlameLevel {
        case 1...3: return Color.orange
        case 4...7: return Color.red
        case 8...14: return Color.theme.healPink
        default: return Color.theme.healGold
        }
    }

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                flameColor.opacity(0.2),
                                flameColor.opacity(0.05)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)

                VStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(flameColor)

                    Text("\(flame.currentFlameLevel)")
                        .font(.body.weight(.bold))
                        .foregroundStyle(Color.theme.textPrimary)
                }
            }

            VStack(spacing: 4) {
                Text(flame.flameName)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(Color.theme.textPrimary)

                Text("×\(String(format: "%.2f", flame.flameMultiplier)) XP Multiplier")
                    .font(.caption)
                    .foregroundStyle(Color.theme.textSecondary)
            }

            HStack(spacing: 4) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Color.theme.healGold)

                Text("\(flame.consecutiveDaysWithoutContact) days strong")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.theme.textPrimary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.theme.healGold.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(Color.theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    let flame = StreakFlame(userId: UUID())
    flame.updateFlameLevel(for: 15)

    return StreakFlameView(flame: flame)
        .preferredColorScheme(.dark)
}

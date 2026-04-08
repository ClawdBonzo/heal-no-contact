import SwiftUI

struct XPBarView: View {
    let gamification: UserGamification

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Progress to next level")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.theme.textSecondary)

                Spacer()

                Text("\(gamification.xpTowardsNextLevel) / \(gamification.xpForNextLevel)")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.theme.healGold)
            }

            ProgressView(value: gamification.levelProgress)
                .tint(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.theme.healTeal,
                            Color.theme.healPurple
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 10)
                .clipShape(RoundedRectangle(cornerRadius: 5))
        }
        .padding(16)
        .background(Color.theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    XPBarView(gamification: UserGamification(userId: UUID()))
        .preferredColorScheme(.dark)
}

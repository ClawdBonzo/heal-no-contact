import SwiftUI

struct LevelBadgeView: View {
    let gamification: UserGamification
    let showAnimation: Bool

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.theme.healPurple.opacity(0.3),
                                Color.theme.healTeal.opacity(0.2)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 140, height: 140)

                Circle()
                    .stroke(Color.theme.healGold.opacity(0.4), lineWidth: 2)
                    .frame(width: 140, height: 140)

                VStack(spacing: 8) {
                    Text("\(gamification.currentLevel)")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.theme.textPrimary)

                    Text(gamification.levelName)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.theme.textSecondary)
                }
            }
            .scaleEffect(showAnimation ? 1.0 : 0.85)
            .opacity(showAnimation ? 1.0 : 0)

            ProgressView(value: gamification.levelProgress)
                .tint(Color.theme.gradientPrimary)
                .frame(height: 8)

            HStack(spacing: 8) {
                Text("\(gamification.xpTowardsNextLevel)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.theme.textPrimary)

                Text("/ \(gamification.xpForNextLevel) XP")
                    .font(.caption)
                    .foregroundStyle(Color.theme.textSecondary)

                Spacer()
            }
            .padding(.horizontal, 20)
        }
        .onAppear {
            if showAnimation {
                withAnimation(.easeOut(duration: 0.6)) {
                    // Animation handled by scaleEffect binding
                }
            }
        }
    }
}

#Preview {
    LevelBadgeView(gamification: UserGamification(userId: UUID()), showAnimation: true)
        .preferredColorScheme(.dark)
}

import SwiftUI

struct LevelUpModalView: View {
    let oldLevel: Int
    let newLevel: Int
    let levelName: String
    let onDismiss: () -> Void

    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0
    @State private var rotation: Double = -15

    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                VStack(spacing: 16) {
                    Text("LEVEL UP! 🎉")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.theme.healGold)

                    HStack(spacing: 16) {
                        VStack(spacing: 8) {
                            Text("\(oldLevel)")
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                                .foregroundStyle(Color.theme.textSecondary)

                            Text("Previous")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color.theme.textTertiary)
                        }

                        Image(systemName: "arrow.right")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(Color.theme.healGold)

                        VStack(spacing: 8) {
                            Text("\(newLevel)")
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                                .foregroundStyle(Color.theme.healGold)

                            Text("Now")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color.theme.textTertiary)
                        }
                    }

                    Text(levelName)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(Color.theme.textPrimary)
                        .padding(.top, 8)
                }
                .frame(maxWidth: .infinity)
                .padding(24)
                .background(Color.theme.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 16))

                Button(action: onDismiss) {
                    Text("Continue Your Journey")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(14)
                        .background(Color.theme.gradientPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(24)
            .scaleEffect(scale)
            .opacity(opacity)
            .rotation3DEffect(
                .degrees(rotation),
                axis: (x: 0.5, y: 1, z: 0)
            )
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                scale = 1.0
                opacity = 1.0
                rotation = 0
            }
        }
    }
}

#Preview {
    LevelUpModalView(oldLevel: 2, newLevel: 3, levelName: "Healing Heart") {
    }
    .preferredColorScheme(.dark)
}

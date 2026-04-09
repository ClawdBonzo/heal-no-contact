import SwiftUI

struct LevelUpModalView: View {
    let oldLevel: Int
    let newLevel: Int
    let levelName: String
    let onDismiss: () -> Void

    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0
    @State private var showStars = false
    @State private var glowPulse = false
    @State private var numberScale: CGFloat = 0.6
    @State private var confetti: [ConfettiPiece] = []

    var body: some View {
        ZStack {
            Color.black.opacity(0.7).ignoresSafeArea()

            // Confetti layer
            GeometryReader { geo in
                ForEach(confetti) { piece in
                    Text(piece.symbol)
                        .font(.system(size: piece.size))
                        .foregroundStyle(piece.color)
                        .opacity(piece.opacity)
                        .position(x: piece.x, y: piece.y)
                }
            }
            .ignoresSafeArea()
            .allowsHitTesting(false)

            VStack(spacing: 20) {
                // Phoenix glow ring + number
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.theme.healGold.opacity(glowPulse ? 0.35 : 0.15),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 10,
                                endRadius: 75
                            )
                        )
                        .frame(width: 150, height: 150)
                        .animation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true), value: glowPulse)

                    Circle()
                        .stroke(
                            AngularGradient(
                                colors: [
                                    Color.theme.healPink,
                                    Color.theme.healGold,
                                    Color.theme.healTeal,
                                    Color.theme.healPink
                                ],
                                center: .center
                            ),
                            style: StrokeStyle(lineWidth: 3, lineCap: .round)
                        )
                        .frame(width: 110, height: 110)
                        .shadow(color: Color.theme.healGold.opacity(0.5), radius: 8)

                    VStack(spacing: 0) {
                        Text("🔥")
                            .font(.system(size: 32))
                        Text("\(newLevel)")
                            .font(.system(size: 36, weight: .black, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.theme.healGold, Color(red: 0.95, green: 0.55, blue: 0.35)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .scaleEffect(numberScale)
                    }
                }

                // Title
                VStack(spacing: 6) {
                    Text("LEVEL UP!")
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.theme.healPink, Color.theme.healGold, Color.theme.healTeal],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .shadow(color: Color.theme.healGold.opacity(0.3), radius: 8)

                    Text(levelName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.theme.textPrimary)

                    HStack(spacing: 12) {
                        levelChip(level: oldLevel, label: "Was", dimmed: true)
                        Image(systemName: "arrow.right")
                            .foregroundStyle(Color.theme.healGold)
                            .font(.body.weight(.bold))
                        levelChip(level: newLevel, label: "Now", dimmed: false)
                    }
                    .padding(.top, 4)
                }

                // Star row
                HStack(spacing: 10) {
                    ForEach(0..<5, id: \.self) { i in
                        Image(systemName: "star.fill")
                            .font(.title3)
                            .foregroundStyle(Color.theme.healGold)
                            .opacity(showStars ? 1 : 0)
                            .scaleEffect(showStars ? 1 : 0.2)
                            .rotationEffect(.degrees(showStars ? 0 : -30))
                            .animation(
                                .spring(response: 0.5, dampingFraction: 0.55).delay(0.35 + Double(i) * 0.08),
                                value: showStars
                            )
                    }
                }

                // CTA
                Button(action: onDismiss) {
                    Text("Continue Your Journey")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [Color.theme.healPurple, Color.theme.healBlue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .shadow(color: Color.theme.healPurple.opacity(0.4), radius: 10, y: 4)
                }
            }
            .padding(28)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(white: 0.07))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(
                                LinearGradient(
                                    colors: [Color.theme.healGold.opacity(0.35), Color.theme.healPink.opacity(0.20)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    )
            )
            .padding(.horizontal, 28)
            .scaleEffect(scale)
            .opacity(opacity)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                scale = 1.0
                opacity = 1.0
            }
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6).delay(0.2)) {
                numberScale = 1.0
            }
            showStars = true
            glowPulse = true
            spawnConfetti()
        }
    }

    @ViewBuilder
    private func levelChip(level: Int, label: String, dimmed: Bool) -> some View {
        VStack(spacing: 4) {
            Text("\(level)")
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(dimmed ? Color.theme.textSecondary : Color.theme.healGold)
            Text(label)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(Color.theme.textTertiary)
        }
        .frame(width: 60)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(dimmed ? Color(white: 0.12) : Color.theme.healGold.opacity(0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(dimmed ? Color.clear : Color.theme.healGold.opacity(0.30), lineWidth: 1)
                )
        )
    }

    private func spawnConfetti() {
        let symbols = ["✦", "✧", "★", "◆", "✿", "❀"]
        let colors: [Color] = [Color.theme.healGold, Color.theme.healPink, Color.theme.healTeal, .white.opacity(0.7)]
        let w = UIScreen.main.bounds.width
        confetti = (0..<30).map { _ in
            ConfettiPiece(
                x: CGFloat.random(in: 0...w),
                y: CGFloat.random(in: -20...200),
                opacity: Double.random(in: 0.5...0.9),
                size: CGFloat.random(in: 10...20),
                symbol: symbols.randomElement()!,
                color: colors.randomElement()!
            )
        }
        let h = UIScreen.main.bounds.height
        for i in confetti.indices {
            let duration = Double.random(in: 2.5...4.5)
            withAnimation(.linear(duration: duration).repeatForever(autoreverses: false)) {
                confetti[i].y += h + 60
                confetti[i].opacity = 0
            }
        }
    }
}

// MARK: - Confetti Piece

private struct ConfettiPiece: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var opacity: Double
    var size: CGFloat
    var symbol: String
    var color: Color
}

#Preview {
    LevelUpModalView(oldLevel: 2, newLevel: 3, levelName: "Healing Heart") {}
        .preferredColorScheme(.dark)
}

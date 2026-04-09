import SwiftUI

struct StreakRingView: View {
    let currentDays: Int
    let goalDays: Int
    let animate: Bool

    private var progress: Double {
        guard goalDays > 0 else { return 0 }
        return min(Double(currentDays) / Double(goalDays), 1.0)
    }

    // Outer pulse ring animation
    @State private var outerPulse = false

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                // Pulsing outer aura ring
                Circle()
                    .stroke(
                        AngularGradient(
                            colors: [
                                Color.theme.healPink.opacity(outerPulse ? 0.22 : 0.06),
                                Color.theme.healGold.opacity(outerPulse ? 0.18 : 0.04),
                                Color.theme.healTeal.opacity(outerPulse ? 0.18 : 0.05),
                                Color.theme.healPink.opacity(outerPulse ? 0.22 : 0.06)
                            ],
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .frame(width: 214, height: 214)
                    .blur(radius: outerPulse ? 4 : 2)
                    .animation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true), value: outerPulse)

                // Deep glow blob
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.theme.healPink.opacity(0.10),
                                Color.theme.healGold.opacity(0.06),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 50,
                            endRadius: 140
                        )
                    )
                    .frame(width: 280, height: 280)

                // Track
                Circle()
                    .stroke(
                        Color.theme.textTertiary.opacity(0.12),
                        style: StrokeStyle(lineWidth: 14, lineCap: .round)
                    )
                    .frame(width: 180, height: 180)

                // Progress arc — rose → gold → teal
                Circle()
                    .trim(from: 0, to: animate ? progress : 0)
                    .stroke(
                        AngularGradient(
                            colors: [
                                Color.theme.healPink,
                                Color(red: 0.95, green: 0.55, blue: 0.30),
                                Color.theme.healGold,
                                Color.theme.healTeal,
                                Color.theme.healPink
                            ],
                            center: .center,
                            startAngle: .degrees(-90),
                            endAngle: .degrees(270)
                        ),
                        style: StrokeStyle(lineWidth: 14, lineCap: .round)
                    )
                    .frame(width: 180, height: 180)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeOut(duration: 1.4), value: animate)
                    // soft glow on the arc
                    .shadow(color: Color.theme.healGold.opacity(0.35), radius: 8)

                // Center content
                VStack(spacing: 4) {
                    Text("\(currentDays)")
                        .font(.system(size: 52, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.theme.textPrimary)
                        .contentTransition(.numericText())

                    Text(currentDays == 1 ? "day" : "days")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color.theme.textSecondary)

                    Text("of \(goalDays)-day goal")
                        .font(.caption)
                        .foregroundStyle(Color.theme.textTertiary)
                }

                // Glowing dot at arc tip
                if animate && progress > 0.02 {
                    Circle()
                        .fill(Color.theme.healGold)
                        .frame(width: 14, height: 14)
                        .shadow(color: Color.theme.healGold.opacity(0.8), radius: 8)
                        .shadow(color: Color.theme.healGold.opacity(0.4), radius: 16)
                        .offset(y: -90)
                        .rotationEffect(.degrees(progress * 360))
                        .animation(.easeOut(duration: 1.4), value: animate)
                }
            }
            .onAppear { outerPulse = true }

            // Progress label — rose→gold gradient text
            Text("\(Int(progress * 100))% complete")
                .font(.caption.weight(.semibold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.theme.healPink, Color.theme.healGold],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Color.theme.healGold.opacity(0.10))
                        .overlay(
                            Capsule()
                                .stroke(Color.theme.healGold.opacity(0.20), lineWidth: 1)
                        )
                )
        }
    }
}

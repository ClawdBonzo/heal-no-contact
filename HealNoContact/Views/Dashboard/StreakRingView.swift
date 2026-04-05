import SwiftUI

struct StreakRingView: View {
    let currentDays: Int
    let goalDays: Int
    let animate: Bool

    private var progress: Double {
        guard goalDays > 0 else { return 0 }
        return min(Double(currentDays) / Double(goalDays), 1.0)
    }

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                // Outer glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.theme.healPurple.opacity(0.15),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 60,
                            endRadius: 130
                        )
                    )
                    .frame(width: 260, height: 260)

                // Track
                Circle()
                    .stroke(
                        Color.theme.textTertiary.opacity(0.15),
                        style: StrokeStyle(lineWidth: 14, lineCap: .round)
                    )
                    .frame(width: 180, height: 180)

                // Progress arc
                Circle()
                    .trim(from: 0, to: animate ? progress : 0)
                    .stroke(
                        AngularGradient(
                            colors: [
                                Color.theme.healBlue,
                                Color.theme.healPurple,
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
                    .animation(.easeOut(duration: 1.2), value: animate)

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

                // Milestone dot at end of arc
                if animate && progress > 0.02 {
                    Circle()
                        .fill(Color.theme.healPink)
                        .frame(width: 12, height: 12)
                        .shadow(color: Color.theme.healPink.opacity(0.5), radius: 6)
                        .offset(y: -90)
                        .rotationEffect(.degrees(progress * 360))
                        .animation(.easeOut(duration: 1.2), value: animate)
                }
            }

            // Progress label
            Text("\(Int(progress * 100))% complete")
                .font(.caption.weight(.medium))
                .foregroundStyle(Color.theme.healPurple)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Color.theme.healPurple.opacity(0.15))
                )
        }
    }
}

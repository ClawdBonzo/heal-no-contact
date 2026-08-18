import SwiftUI

struct UrgeWaveView: View {
    /// When the urge started — the timer is derived from this, so it stays accurate
    /// through backgrounding and scrolling (a counter-based timer drifted).
    let startedAt: Date
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(startedAt: Date = .now) {
        self.startedAt = startedAt
    }

    var body: some View {
        // Ticks once per second; the wave phase is derived from elapsed time (no Timer, no drift).
        TimelineView(.periodic(from: startedAt, by: 1)) { context in
            let elapsed = max(0, context.date.timeIntervalSince(startedAt))
            let phase = reduceMotion ? 0 : CGFloat(elapsed) * 0.1

            VStack(spacing: 16) {
                Text("Urge Wave Timer")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.theme.textSecondary)

                // Wave animation
                ZStack {
                    WaveShape(phase: phase, amplitude: 8)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.theme.healPurple.opacity(0.3),
                                    Color.theme.healBlue.opacity(0.1)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(height: 60)

                    WaveShape(phase: phase + .pi / 2, amplitude: 6)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.theme.healPink.opacity(0.2),
                                    Color.theme.healPurple.opacity(0.05)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(height: 60)
                }
                .frame(height: 60)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .animation(reduceMotion ? nil : .linear(duration: 1), value: phase)
                .accessibilityHidden(true)

                // Timer display
                HStack(spacing: 4) {
                    Image(systemName: "clock.fill")
                        .foregroundStyle(Color.theme.healPurple)
                    Text(timeString(for: elapsed))
                        .font(.title3.weight(.bold).monospacedDigit())
                        .foregroundStyle(Color.theme.textPrimary)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel(Text("Time riding this urge"))
                .accessibilityValue(Text(timeString(for: elapsed)))

                Text("Most urges peak at 10-20 minutes then fade. You're doing great.")
                    .font(.caption)
                    .foregroundStyle(Color.theme.textTertiary)
                    .multilineTextAlignment(.center)
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.theme.cardBackground)
            )
        }
    }

    private func timeString(for elapsed: TimeInterval) -> String {
        let total = Int(elapsed)
        let minutes = total / 60
        let seconds = total % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

struct WaveShape: Shape {
    var phase: CGFloat
    var amplitude: CGFloat

    var animatableData: CGFloat {
        get { phase }
        set { phase = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        let midY = height / 2

        path.move(to: CGPoint(x: 0, y: midY))

        for x in stride(from: 0, through: width, by: 1) {
            let relativeX = x / width
            let y = midY + amplitude * sin(2 * .pi * relativeX * 3 + phase * 10)
            path.addLine(to: CGPoint(x: x, y: y))
        }

        path.addLine(to: CGPoint(x: width, y: height))
        path.addLine(to: CGPoint(x: 0, y: height))
        path.closeSubpath()

        return path
    }
}

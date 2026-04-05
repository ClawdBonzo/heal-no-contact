import SwiftUI

struct UrgeWaveView: View {
    @State private var elapsedSeconds = 0
    @State private var timer: Timer?
    @State private var wavePhase: CGFloat = 0

    var body: some View {
        VStack(spacing: 16) {
            Text("Urge Wave Timer")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.theme.textSecondary)

            // Wave animation
            ZStack {
                // Wave
                WaveShape(phase: wavePhase, amplitude: 8)
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

                WaveShape(phase: wavePhase + .pi / 2, amplitude: 6)
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

            // Timer display
            HStack(spacing: 4) {
                Image(systemName: "clock.fill")
                    .foregroundStyle(Color.theme.healPurple)
                Text(timeString)
                    .font(.title3.weight(.bold).monospacedDigit())
                    .foregroundStyle(Color.theme.textPrimary)
            }

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
        .onAppear {
            startTimer()
        }
        .onDisappear {
            timer?.invalidate()
        }
    }

    private var timeString: String {
        let minutes = elapsedSeconds / 60
        let seconds = elapsedSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            elapsedSeconds += 1
            withAnimation(.linear(duration: 1)) {
                wavePhase += 0.1
            }
        }
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

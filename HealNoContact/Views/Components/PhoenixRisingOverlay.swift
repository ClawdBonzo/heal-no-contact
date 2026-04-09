import SwiftUI

// MARK: - Particle

private struct PhoenixParticle: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var opacity: Double
    var scale: CGFloat
    var drift: CGFloat
    var symbol: String
    var color: Color
}

// MARK: - PhoenixRisingOverlay

/// Full-screen celebration overlay triggered on streak milestones and level-ups.
/// Respects `accessibilityReduceMotion` — skips particles and springs when enabled.
struct PhoenixRisingOverlay: View {
    let day: Int?           // nil = level-up context
    let onDismiss: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var particles: [PhoenixParticle] = []
    @State private var showContent = false
    @State private var ringScale: CGFloat = 0.4
    @State private var ringOpacity: Double = 0
    @State private var glowPulse = false
    @State private var textScale: CGFloat = 0.7
    @State private var emojiOffset: CGFloat = 40
    @State private var containerSize: CGSize = .zero

    private let symbols = ["✦", "✧", "◆", "❋", "✿", "❀"]
    private let particleColors: [Color] = [
        Color(red: 0.95, green: 0.75, blue: 0.30),  // gold
        Color(red: 0.90, green: 0.35, blue: 0.55),  // rose
        Color(red: 0.30, green: 0.80, blue: 0.75),  // teal
        .white.opacity(0.8)
    ]

    var body: some View {
        ZStack {
            // Scrim
            Color.black.opacity(0.78)
                .ignoresSafeArea()
                .onTapGesture { dismissOverlay() }

            // Ambient radial glow — static when reduceMotion
            RadialGradient(
                colors: [
                    Color(red: 0.95, green: 0.55, blue: 0.25).opacity(reduceMotion ? 0.22 : (glowPulse ? 0.30 : 0.15)),
                    Color(red: 0.55, green: 0.35, blue: 0.95).opacity(0.10),
                    Color.clear
                ],
                center: .center,
                startRadius: 40,
                endRadius: 280
            )
            .ignoresSafeArea()
            .animation(
                reduceMotion ? nil : .easeInOut(duration: 2.2).repeatForever(autoreverses: true),
                value: glowPulse
            )

            // Floating particles — hidden entirely when reduceMotion
            if !reduceMotion {
                GeometryReader { geo in
                    let _ = Task { @MainActor in
                        if containerSize == .zero {
                            containerSize = geo.size
                        }
                    }
                    ForEach(particles) { p in
                        Text(p.symbol)
                            .font(.system(size: 14 * p.scale))
                            .foregroundStyle(p.color)
                            .opacity(p.opacity)
                            .position(x: p.x, y: p.y)
                    }
                }
                .ignoresSafeArea()
                .accessibilityHidden(true)
            }

            // Main celebration card
            VStack(spacing: 0) {
                // Phoenix emoji with glow ring
                ZStack {
                    if !reduceMotion {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        Color(red: 0.95, green: 0.65, blue: 0.20).opacity(0.35),
                                        Color.clear
                                    ],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 80
                                )
                            )
                            .frame(width: 160, height: 160)
                            .scaleEffect(glowPulse ? 1.12 : 1.0)
                            .animation(
                                .easeInOut(duration: 1.8).repeatForever(autoreverses: true),
                                value: glowPulse
                            )
                    }

                    Text("🔥")
                        .font(.system(size: 72))
                        .offset(y: reduceMotion ? 0 : -emojiOffset)
                        .opacity(showContent ? 1 : 0)
                        .accessibilityHidden(true) // decorative; context given by headline
                }
                .frame(height: 110)
                .padding(.bottom, 8)

                // Headline
                if let day {
                    Text("Day \(day)")
                        .font(.system(size: 48, weight: .black, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.95, green: 0.75, blue: 0.30),
                                    Color(red: 0.95, green: 0.45, blue: 0.65),
                                    Color(red: 0.30, green: 0.80, blue: 0.75)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .scaleEffect(reduceMotion ? 1 : textScale)
                        .opacity(showContent ? 1 : 0)
                        .accessibilityLabel("Milestone: Day \(day)")

                    Text(milestoneLabel(for: day))
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.85))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .padding(.top, 6)
                        .opacity(showContent ? 1 : 0)
                } else {
                    Text("Level Up!")
                        .font(.system(size: 44, weight: .black, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.95, green: 0.75, blue: 0.30),
                                    Color(red: 0.95, green: 0.45, blue: 0.65)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .scaleEffect(reduceMotion ? 1 : textScale)
                        .opacity(showContent ? 1 : 0)
                        .accessibilityLabel("Level Up! Your healing grows stronger.")

                    Text("Your healing grows stronger")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.85))
                        .padding(.top, 6)
                        .opacity(showContent ? 1 : 0)
                        .accessibilityHidden(true) // already in label above
                }

                // Gold star row — hidden from VoiceOver (decorative)
                HStack(spacing: 8) {
                    ForEach(0..<5, id: \.self) { i in
                        Image(systemName: "star.fill")
                            .font(.body)
                            .foregroundStyle(Color(red: 0.95, green: 0.75, blue: 0.30))
                            .opacity(showContent ? 1 : 0)
                            .scaleEffect(showContent ? 1 : 0.3)
                            .animation(
                                reduceMotion ? nil : .spring(response: 0.5, dampingFraction: 0.6)
                                    .delay(0.4 + Double(i) * 0.07),
                                value: showContent
                            )
                    }
                }
                .accessibilityHidden(true)
                .padding(.top, 18)

                // CTA
                Button(action: dismissOverlay) {
                    Text("Keep Going")
                        .font(.headline)
                        .foregroundStyle(.black)
                        .frame(width: 200)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.95, green: 0.75, blue: 0.30),
                                    Color(red: 0.95, green: 0.55, blue: 0.35)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(Capsule())
                        .shadow(color: Color(red: 0.95, green: 0.65, blue: 0.20).opacity(0.55), radius: 16, y: 6)
                }
                .accessibilityLabel("Continue — Keep Going")
                .padding(.top, 28)
                .opacity(showContent ? 1 : 0)
            }
            .scaleEffect(reduceMotion ? 1 : ringScale)
            .opacity(ringOpacity)
        }
        .background(GeometryReader { geo in
            Color.clear.onAppear { containerSize = geo.size }
        })
        .onAppear {
            if reduceMotion {
                // Instantly show everything, no motion
                ringScale = 1.0
                ringOpacity = 1.0
                showContent = true
                textScale = 1.0
                emojiOffset = 0
            } else {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    ringScale = 1.0
                    ringOpacity = 1.0
                }
                withAnimation(.spring(response: 0.6, dampingFraction: 0.75).delay(0.15)) {
                    showContent = true
                    textScale = 1.0
                    emojiOffset = 0
                }
                glowPulse = true
                spawnAndAnimateParticles()
            }
        }
    }

    // MARK: - Actions

    private func dismissOverlay() {
        if reduceMotion {
            onDismiss()
        } else {
            withAnimation(.easeIn(duration: 0.25)) {
                ringOpacity = 0
                ringScale = 0.9
            }
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(0.25))
                onDismiss()
            }
        }
    }

    // MARK: - Particle system

    private func spawnAndAnimateParticles() {
        let w = containerSize.width > 0 ? containerSize.width : 390
        let h = containerSize.height > 0 ? containerSize.height : 844

        // 20 particles — balanced for 60fps on A15 and newer
        particles = (0..<20).map { _ in
            PhoenixParticle(
                x: CGFloat.random(in: 0...w),
                y: CGFloat.random(in: 0...h),
                opacity: Double.random(in: 0.3...0.8),
                scale: CGFloat.random(in: 0.6...1.6),
                drift: CGFloat.random(in: -30...30),
                symbol: symbols.randomElement()!,
                color: particleColors.randomElement()!
            )
        }

        for i in particles.indices {
            let duration = Double.random(in: 3.0...6.0)
            let delay    = Double.random(in: 0...1.5)
            withAnimation(.linear(duration: duration).delay(delay).repeatForever(autoreverses: false)) {
                particles[i].y -= h + 100
                particles[i].x += particles[i].drift
                particles[i].opacity = 0
            }
        }
    }

    // MARK: - Milestone copy

    private func milestoneLabel(for day: Int) -> String {
        switch day {
        case 1:   return "The journey of a thousand miles\nbegins with a single step."
        case 7:   return "One full week. The fog is lifting."
        case 14:  return "Two weeks strong. You're rewriting your story."
        case 21:  return "21 days. A new habit is forming."
        case 30:  return "30 days. You are healing."
        case 45:  return "45 days. The phoenix is rising."
        case 60:  return "60 days. You chose yourself."
        case 90:  return "90 days. Fully transformed."
        case 180: return "Half a year. Unbreakable."
        case 365: return "One year. You are the phoenix."
        default:  return "Every day you choose yourself."
        }
    }
}

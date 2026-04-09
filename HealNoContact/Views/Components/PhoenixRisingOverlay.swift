import SwiftUI

// MARK: - Particle

private struct PhoenixParticle: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var opacity: Double
    var scale: CGFloat
    var speed: CGFloat
    var drift: CGFloat
    var symbol: String
    var color: Color
}

// MARK: - PhoenixRisingOverlay

/// Full-screen celebration overlay triggered on streak milestones and level-ups.
/// Reads `showPhoenixRisingAnimation` from the environment GamificationManager (or receives bindings).
struct PhoenixRisingOverlay: View {
    let day: Int?           // nil = level-up context
    let onDismiss: () -> Void

    @State private var particles: [PhoenixParticle] = []
    @State private var showContent = false
    @State private var ringScale: CGFloat = 0.4
    @State private var ringOpacity: Double = 0
    @State private var glowPulse = false
    @State private var textScale: CGFloat = 0.7
    @State private var emojiOffset: CGFloat = 40

    private let symbols = ["✦", "✧", "◆", "❋", "✿", "❀", "✦"]
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
                .onTapGesture { dismiss() }

            // Ambient radial glow
            RadialGradient(
                colors: [
                    Color(red: 0.95, green: 0.55, blue: 0.25).opacity(glowPulse ? 0.30 : 0.15),
                    Color(red: 0.55, green: 0.35, blue: 0.95).opacity(0.10),
                    Color.clear
                ],
                center: .center,
                startRadius: 40,
                endRadius: 280
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true), value: glowPulse)

            // Floating particles
            GeometryReader { geo in
                ForEach(particles) { p in
                    Text(p.symbol)
                        .font(.system(size: 14 * p.scale))
                        .foregroundStyle(p.color)
                        .opacity(p.opacity)
                        .position(x: p.x, y: p.y)
                }
                .ignoresSafeArea()
            }

            // Main card
            VStack(spacing: 0) {
                // Phoenix emoji with glow ring
                ZStack {
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
                        .animation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true), value: glowPulse)

                    Text("🔥")
                        .font(.system(size: 72))
                        .offset(y: -emojiOffset)
                        .opacity(showContent ? 1 : 0)
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
                        .scaleEffect(textScale)
                        .opacity(showContent ? 1 : 0)

                    Text(milestoneLabel(for: day))
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.85))
                        .multilineTextAlignment(.center)
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
                        .scaleEffect(textScale)
                        .opacity(showContent ? 1 : 0)

                    Text("Your healing grows stronger")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.85))
                        .padding(.top, 6)
                        .opacity(showContent ? 1 : 0)
                }

                // Gold star row
                HStack(spacing: 8) {
                    ForEach(0..<5, id: \.self) { i in
                        Image(systemName: "star.fill")
                            .font(.body)
                            .foregroundStyle(Color(red: 0.95, green: 0.75, blue: 0.30))
                            .opacity(showContent ? 1 : 0)
                            .scaleEffect(showContent ? 1 : 0.3)
                            .animation(
                                .spring(response: 0.5, dampingFraction: 0.6).delay(0.4 + Double(i) * 0.07),
                                value: showContent
                            )
                    }
                }
                .padding(.top, 18)

                // CTA
                Button(action: dismiss) {
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
                .padding(.top, 28)
                .opacity(showContent ? 1 : 0)
            }
            .scaleEffect(ringScale)
            .opacity(ringOpacity)
        }
        .onAppear {
            spawnParticles()
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
            animateParticles()
        }
    }

    private func dismiss() {
        withAnimation(.easeIn(duration: 0.25)) {
            ringOpacity = 0
            ringScale = 0.9
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            onDismiss()
        }
    }

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

    private func spawnParticles() {
        let screenW = UIScreen.main.bounds.width
        let screenH = UIScreen.main.bounds.height
        particles = (0..<40).map { _ in
            PhoenixParticle(
                x: CGFloat.random(in: 0...screenW),
                y: CGFloat.random(in: 0...screenH),
                opacity: Double.random(in: 0.3...0.8),
                scale: CGFloat.random(in: 0.6...1.8),
                speed: CGFloat.random(in: 60...160),
                drift: CGFloat.random(in: -30...30),
                symbol: symbols.randomElement()!,
                color: particleColors.randomElement()!
            )
        }
    }

    private func animateParticles() {
        let screenH = UIScreen.main.bounds.height
        for i in particles.indices {
            let duration = Double.random(in: 3.0...6.0)
            let delay = Double.random(in: 0...2.0)
            withAnimation(.linear(duration: duration).delay(delay).repeatForever(autoreverses: false)) {
                particles[i].y -= screenH + 100
                particles[i].x += particles[i].drift
                particles[i].opacity = 0
            }
        }
    }
}

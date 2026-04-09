import SwiftUI

// MARK: - HealingShareCard
// A shareable "Healing Day X" card rendered via ImageRenderer and presented via ShareLink.

struct HealingShareCard: View {
    let streakDays: Int
    let userName: String       // can be empty
    let mantra: String         // can be empty

    private var phoenixStage: String {
        switch streakDays {
        case 0..<7:   return "Ember"
        case 7..<21:  return "Flame"
        case 21..<60: return "Phoenix"
        default:      return "Legend"
        }
    }

    private var phoenixEmoji: String {
        switch streakDays {
        case 0..<7:   return "🕯️"
        case 7..<21:  return "🔥"
        case 21..<60: return "🦅"
        default:      return "⚡️"
        }
    }

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.03, blue: 0.12),
                    Color(red: 0.10, green: 0.04, blue: 0.18),
                    Color(red: 0.04, green: 0.08, blue: 0.14)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Ambient glow
            Circle()
                .fill(Color(red: 0.95, green: 0.55, blue: 0.30).opacity(0.18))
                .frame(width: 260)
                .blur(radius: 70)
                .offset(x: -60, y: -80)

            Circle()
                .fill(Color(red: 0.30, green: 0.80, blue: 0.75).opacity(0.12))
                .frame(width: 200)
                .blur(radius: 60)
                .offset(x: 80, y: 60)

            VStack(spacing: 0) {
                // Top app label
                HStack {
                    Text("HEAL NO CONTACT")
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .tracking(2.5)
                        .foregroundStyle(Color(red: 0.95, green: 0.75, blue: 0.30).opacity(0.7))
                    Spacer()
                    Text("@HealNoContact")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.white.opacity(0.35))
                }
                .padding(.horizontal, 28)
                .padding(.top, 28)

                Spacer()

                // Emoji
                Text(phoenixEmoji)
                    .font(.system(size: 64))
                    .shadow(color: Color(red: 0.95, green: 0.65, blue: 0.20).opacity(0.6), radius: 20)

                // Day counter
                VStack(spacing: 4) {
                    Text("HEALING DAY")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .tracking(3)
                        .foregroundStyle(.white.opacity(0.55))

                    Text("\(streakDays)")
                        .font(.system(size: 88, weight: .black, design: .rounded))
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
                        .shadow(color: Color(red: 0.95, green: 0.55, blue: 0.30).opacity(0.4), radius: 16)
                }

                // Phoenix stage badge
                Text(phoenixStage + " Stage")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(red: 0.95, green: 0.75, blue: 0.30))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(Color(red: 0.95, green: 0.75, blue: 0.30).opacity(0.15))
                            .overlay(
                                Capsule()
                                    .stroke(Color(red: 0.95, green: 0.75, blue: 0.30).opacity(0.35), lineWidth: 1)
                            )
                    )
                    .padding(.top, 8)

                // Mantra (if set)
                if !mantra.isEmpty {
                    Text("\u{201C}\(mantra)\u{201D}")
                        .font(.system(size: 14, weight: .medium, design: .serif).italic())
                        .foregroundStyle(.white.opacity(0.70))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, 36)
                        .padding(.top, 18)
                }

                Spacer()

                // Bottom strip
                HStack {
                    Text("No contact. No regrets. Just healing.")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.white.opacity(0.40))
                    Spacer()
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 28)
            }
        }
        .frame(width: 390, height: 500)
        .clipShape(RoundedRectangle(cornerRadius: 28))
    }
}

// MARK: - ShareButton

struct HealingShareButton: View {
    let streakDays: Int
    let userName: String
    let mantra: String

    @State private var isRendering = false

    var body: some View {
        Button {
            renderAndShare()
        } label: {
            HStack(spacing: 6) {
                if isRendering {
                    ProgressView()
                        .scaleEffect(0.8)
                        .tint(.white)
                } else {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 13, weight: .semibold))
                    Text("Share Day \(streakDays)")
                        .font(.system(size: 13, weight: .semibold))
                }
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .background(
                LinearGradient(
                    colors: [
                        Color(red: 0.95, green: 0.65, blue: 0.25),
                        Color(red: 0.90, green: 0.40, blue: 0.60)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(Capsule())
            .shadow(color: Color(red: 0.95, green: 0.55, blue: 0.25).opacity(0.4), radius: 10, y: 4)
        }
        .buttonStyle(.plain)
        .disabled(isRendering)
    }

    @MainActor
    private func renderAndShare() {
        guard !isRendering else { return }
        isRendering = true
        HapticService.impact(.medium)

        let card = HealingShareCard(
            streakDays: streakDays,
            userName: userName,
            mantra: mantra
        )

        let renderer = ImageRenderer(content: card)
        renderer.scale = 3.0

        guard let uiImage = renderer.uiImage else {
            isRendering = false
            return
        }

        let vc = UIActivityViewController(
            activityItems: [uiImage, "Healing Day \(streakDays) \u{1F525} #HealNoContact"],
            applicationActivities: nil
        )

        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let root = scene.windows.first?.rootViewController {
            var presenter = root
            while let presented = presenter.presentedViewController {
                presenter = presented
            }
            presenter.present(vc, animated: true)
        }

        isRendering = false
    }
}

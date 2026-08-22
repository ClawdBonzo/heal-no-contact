import SwiftUI
import SwiftData

struct EmergencyView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @State private var currentStrategy: String = QuoteService.shared.randomCopingStrategy()
    @State private var showUrgeWave = false
    @State private var intensityLevel: Double = 5
    @State private var breathingActive = true
    @State private var ambientPulse = false
    @State private var urgeStartTime = Date.now
    @State private var showCompleted = false
    @Environment(GameificationService.self) private var game
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.requestReview) private var requestReview

    private var profile: UserProfile? { profiles.first }

    var body: some View {
        ZStack {
            // Dark overlay with pulse
            Color.theme.deepBackground.ignoresSafeArea()

            // Animated gradient pulse
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.theme.healPink.opacity(ambientPulse ? 0.2 : 0.05),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 10,
                        endRadius: ambientPulse ? 250 : 100
                    )
                )
                .animation(
                    reduceMotion ? nil : .easeInOut(duration: 4).repeatForever(autoreverses: true),
                    value: ambientPulse
                )
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 32) {
                    // Header
                    VStack(spacing: 8) {
                        Text("You've Got This")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.theme.textPrimary)

                        Text("The urge to reach out is temporary.\nLet's ride this wave together.")
                            .font(.subheadline)
                            .foregroundStyle(Color.theme.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)

                    // Breathing exercise (4-4-6: in, hold, out)
                    BreathingBubble(isActive: $breathingActive)

                    // Urge intensity — captured so the log reflects reality, not a default
                    UrgeIntensityCard(intensity: $intensityLevel)

                    // Current streak reminder
                    if let profile {
                        HStack(spacing: 12) {
                            Image(systemName: "flame.fill")
                                .foregroundStyle(Color.theme.healPurple)
                            Group {
                                if profile.currentStreakDays > 0 {
                                    Text("You're on a **\(profile.currentStreakDays)-day** streak. Don't break it now.")
                                } else {
                                    Text("Every streak starts at day 0. Get through this moment and day 1 is yours.")
                                }
                            }
                            .font(.subheadline)
                            .foregroundStyle(Color.theme.textPrimary)
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.theme.healPurple.opacity(0.1))
                        )
                    }

                    // Coping strategy
                    VStack(spacing: 14) {
                        Text("Try This")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.theme.healTeal)

                        Text(currentStrategy)
                            .font(.body)
                            .foregroundStyle(Color.theme.textPrimary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)

                        Button {
                            withAnimation(.spring(response: 0.3)) {
                                currentStrategy = QuoteService.shared.randomCopingStrategy()
                            }
                            HapticService.impact(.light)
                        } label: {
                            Label("Another Strategy", systemImage: "arrow.clockwise")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(Color.theme.healTeal)
                        }
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.theme.cardBackground)
                    )

                    // Mantra reminder
                    if let mantra = profile?.personalMantra, !mantra.isEmpty {
                        VStack(spacing: 8) {
                            Text("Your Mantra")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color.theme.healGold)

                            Text(mantra)
                                .font(.subheadline.italic())
                                .foregroundStyle(Color.theme.textPrimary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.theme.healGold.opacity(0.08))
                        )
                    }

                    // Urge wave timer
                    UrgeWaveView(startedAt: urgeStartTime)

                    // Action buttons
                    VStack(spacing: 12) {
                        Button {
                            logEmergencyResisted()
                        } label: {
                            Label("I Resisted — I'm Okay", systemImage: "checkmark.shield.fill")
                                .font(.headline)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.theme.gradientHope)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }

                        Button {
                            dismiss()
                        } label: {
                            Text("Close")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(Color.theme.textSecondary)
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }

            // Success overlay
            if showCompleted {
                EmergencyCompletedOverlay {
                    // A resisted urge is the best moment to ask for a rating (throttled).
                    ReviewPrompter.maybeRequest(requestReview, moment: .resistedUrge,
                                                streakDays: profile?.currentStreakDays ?? 0)
                    dismiss()
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .onAppear {
            HapticService.urgePulse()
            urgeStartTime = .now
            ambientPulse = true
        }
    }

    private func logEmergencyResisted() {
        guard !showCompleted else { return } // one log + one XP award per SOS session
        let duration = Int(Date.now.timeIntervalSince(urgeStartTime))
        let log = EmergencyLog(
            triggerReason: "Urge to contact",
            copingStrategyUsed: currentStrategy,
            didResist: true,
            durationSeconds: duration,
            intensityLevel: Int(intensityLevel)
        )
        modelContext.insert(log)

        // Award XP for resisting (self-care quests progress on their own)
        game.addXP(25, reason: String(localized: "Urge resisted"))
        game.progressQuests(ofKind: .selfCare)

        HapticService.milestone()

        withAnimation(.spring(response: 0.4)) {
            showCompleted = true
        }
    }
}

// MARK: - Breathing Bubble

/// Guided 4-4-6 breathing (inhale 4s, hold 4s, exhale 6s). One task drives both the
/// label and the bubble so they can never disagree; Pause/Resume really pauses.
private struct BreathingBubble: View {
    @Binding var isActive: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var phase: Phase = .idle

    private enum Phase { case idle, inhale, hold, exhale }

    private var expanded: Bool { phase == .inhale || phase == .hold }

    /// How long the bubble takes to reach the current phase's size.
    private var bubbleDuration: Double {
        switch phase {
        case .idle:   return 0.6
        case .inhale: return 4
        case .hold:   return 4
        case .exhale: return 6
        }
    }

    private var label: LocalizedStringKey {
        switch phase {
        case .idle:   return "Ready when you are"
        case .inhale: return "Breathe In"
        case .hold:   return "Hold"
        case .exhale: return "Breathe Out"
        }
    }

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                // The bubble eases over the whole phase (4s in / 6s out)…
                Group {
                    Circle()
                        .fill(Color.theme.healBlue.opacity(0.1))
                        .frame(width: expanded ? 140 : 80, height: expanded ? 140 : 80)

                    Circle()
                        .fill(Color.theme.healBlue.opacity(0.2))
                        .frame(width: expanded ? 100 : 60, height: expanded ? 100 : 60)
                }
                .animation(reduceMotion ? nil : .easeInOut(duration: bubbleDuration), value: expanded)

                // …while the label swaps quickly so two words never overlap.
                Text(label)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.theme.healBlue)
                    .contentTransition(.opacity)
                    .animation(.easeInOut(duration: 0.25), value: phase)
            }
            .frame(height: 140)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text("Breathing exercise"))
            .accessibilityValue(Text(label))

            Button {
                isActive.toggle()
                HapticService.selection()
            } label: {
                Text(isActive ? "Pause Breathing Exercise" : "Resume Breathing Exercise")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.theme.healBlue)
            }
        }
        .task(id: isActive) {
            guard isActive else { phase = .idle; return }
            while !Task.isCancelled {
                await step(.inhale, seconds: 4)
                await step(.hold,   seconds: 4)
                await step(.exhale, seconds: 6)
            }
        }
    }

    private func step(_ next: Phase, seconds: Double) async {
        guard !Task.isCancelled else { return }
        phase = next
        try? await Task.sleep(for: .seconds(seconds))
    }
}

// MARK: - Urge Intensity

private struct UrgeIntensityCard: View {
    @Binding var intensity: Double

    private var descriptor: LocalizedStringKey {
        switch Int(intensity) {
        case ...3:  return "Manageable"
        case 4...6: return "Strong"
        case 7...8: return "Very strong"
        default:    return "Overwhelming"
        }
    }

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Text("How strong is the urge right now?")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.theme.textPrimary)
                Spacer()
                Text("\(Int(intensity))/10")
                    .font(.subheadline.weight(.bold).monospacedDigit())
                    .foregroundStyle(Color.theme.healPink)
            }
            Slider(value: $intensity, in: 1...10, step: 1) {
                Text("Urge intensity")
            } minimumValueLabel: {
                Text("1").font(.caption2).foregroundStyle(Color.theme.textTertiary)
            } maximumValueLabel: {
                Text("10").font(.caption2).foregroundStyle(Color.theme.textTertiary)
            }
            .tint(Color.theme.healPink)
            .onChange(of: intensity) { _, _ in HapticService.selection() }

            Text(descriptor)
                .font(.caption)
                .foregroundStyle(Color.theme.textSecondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.theme.cardBackground)
        )
    }
}

// MARK: - Completed Overlay

private struct EmergencyCompletedOverlay: View {
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.7).ignoresSafeArea()

            VStack(spacing: 24) {
                Image(systemName: "checkmark.shield.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(Color.theme.healTeal)
                    .symbolEffect(.bounce)

                Text("You did it!")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text("You resisted the urge.\nThat takes real strength.")
                    .font(.subheadline)
                    .foregroundStyle(Color.theme.textSecondary)
                    .multilineTextAlignment(.center)

                Button(action: onDismiss) {
                    Text("Back to Dashboard")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.theme.gradientPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal, 40)
            }
        }
    }
}

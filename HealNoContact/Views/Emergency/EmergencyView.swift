import SwiftUI
import SwiftData

struct EmergencyView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @State private var currentStrategy: String = QuoteService.shared.randomCopingStrategy()
    @State private var showUrgeWave = false
    @State private var intensityLevel: Double = 5
    @State private var breathingActive = false
    @State private var breatheIn = false
    @State private var urgeStartTime = Date.now
    @State private var showCompleted = false
    @State private var gamificationService: GameificationService?

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
                            Color.theme.healPink.opacity(breatheIn ? 0.2 : 0.05),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 10,
                        endRadius: breatheIn ? 250 : 100
                    )
                )
                .animation(
                    .easeInOut(duration: breathingActive ? 4 : 2).repeatForever(autoreverses: true),
                    value: breatheIn
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

                    // Breathing exercise
                    BreathingBubble(isActive: $breathingActive, breatheIn: $breatheIn)

                    // Current streak reminder
                    if let profile {
                        HStack(spacing: 12) {
                            Image(systemName: "flame.fill")
                                .foregroundStyle(Color.theme.healPurple)
                            Text("You're on a **\(profile.currentStreakDays)-day** streak. Don't break it now.")
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
                    UrgeWaveView()

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
                    dismiss()
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .onAppear {
            HapticService.urgePulse()
            urgeStartTime = .now
            withAnimation {
                breatheIn = true
            }
        }
    }

    private func logEmergencyResisted() {
        let duration = Int(Date.now.timeIntervalSince(urgeStartTime))
        let log = EmergencyLog(
            triggerReason: "Urge to contact",
            copingStrategyUsed: currentStrategy,
            didResist: true,
            durationSeconds: duration,
            intensityLevel: Int(intensityLevel)
        )
        modelContext.insert(log)

        // Award XP for resisting emergency SOS
        if gamificationService == nil, let userId = profile?.id {
            let service = GameificationService(modelContext: modelContext)
            service.initializeGamification(for: userId)
            gamificationService = service
        }
        gamificationService?.addXP(25, reason: "SOS Resisted")

        HapticService.milestone()

        withAnimation(.spring(response: 0.4)) {
            showCompleted = true
        }
    }
}

// MARK: - Breathing Bubble

private struct BreathingBubble: View {
    @Binding var isActive: Bool
    @Binding var breatheIn: Bool

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.theme.healBlue.opacity(0.1))
                    .frame(width: breatheIn ? 140 : 80, height: breatheIn ? 140 : 80)

                Circle()
                    .fill(Color.theme.healBlue.opacity(0.2))
                    .frame(width: breatheIn ? 100 : 60, height: breatheIn ? 100 : 60)

                Text(breatheIn ? "Breathe In" : "Breathe Out")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.theme.healBlue)
            }
            .animation(.easeInOut(duration: 4).repeatForever(autoreverses: true), value: breatheIn)

            Button {
                isActive.toggle()
                if isActive {
                    breatheIn.toggle()
                }
            } label: {
                Text(isActive ? "Stop Breathing Exercise" : "Start Breathing Exercise")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.theme.healBlue)
            }
        }
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

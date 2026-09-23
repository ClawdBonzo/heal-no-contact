import SwiftUI

struct WelcomePageView: View {
    let onNext: () -> Void
    @State private var showContent = false
    @State private var showButton = false
    @State private var heartbeat = false
    @State private var glowPulse = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 0) {
            // The logo, title and feature rows are taller than a 6.3" screen at the old fixed
            // spacing, so the stack overflowed and pushed the button down onto the page dots.
            // They now scroll when they don't fit, and the button stays pinned above the dots.
            GeometryReader { geo in
                ScrollView {
                    VStack(spacing: 28) {
                        // Single large logo with heartbeat animation + glow
                        ZStack {
                            // Outer soft glow
                            Circle()
                                .fill(Color.theme.healPurple.opacity(0.18))
                                // Kept inside the page: the onboarding pager clips at the status bar,
                                // and a larger glow showed a hard seam there.
                                .frame(width: 220, height: 220)
                                .blur(radius: 32)
                                .scaleEffect(glowPulse ? 1.15 : 0.9)

                            // Inner glow
                            Circle()
                                .fill(Color.theme.healPurple.opacity(0.25))
                                .frame(width: 200, height: 200)
                                .blur(radius: 25)
                                .scaleEffect(glowPulse ? 1.12 : 0.95)

                            Image("BrandIcon")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 160, height: 160)
                                .clipShape(RoundedRectangle(cornerRadius: 38))
                                .shadow(color: Color.theme.healPurple.opacity(0.5), radius: 24, y: 8)
                                .scaleEffect(heartbeat ? 1.06 : 1.0)
                        }
                        .frame(width: 200, height: 200)   // glow draws beyond this; layout doesn't pay for it
                        .opacity(showContent ? 1 : 0)
                        .scaleEffect(showContent ? 1 : 0.7)

                        VStack(spacing: 12) {
                            Text("Heal")
                                .font(.system(size: 52, weight: .bold, design: .rounded))
                                .foregroundStyle(Color.theme.gradientPrimary)
                                .opacity(showContent ? 1 : 0)
                                .offset(y: showContent ? 0 : 20)

                            Text("Your no-contact companion")
                                .font(.title3)
                                .foregroundStyle(Color.theme.textSecondary)
                                .opacity(showContent ? 1 : 0)
                                .offset(y: showContent ? 0 : 10)
                        }

                        VStack(spacing: 14) {
                            FeatureRow(
                                icon: "shield.checkered",
                                title: String(localized: "Stay Strong"),
                                subtitle: String(localized: "Track your no-contact streak with support")
                            )
                            FeatureRow(
                                icon: "book.fill",
                                title: String(localized: "Process & Reflect"),
                                subtitle: String(localized: "Journal your healing journey privately")
                            )
                            FeatureRow(
                                icon: "chart.line.uptrend.xyaxis",
                                title: String(localized: "See Your Growth"),
                                subtitle: String(localized: "Watch your progress and unlock milestones")
                            )
                            FeatureRow(
                                icon: "sos",
                                title: String(localized: "Emergency Support"),
                                subtitle: String(localized: "Instant help when the urge hits")
                            )
                        }
                        .padding(.horizontal, 24)
                        .opacity(showContent ? 1 : 0)
                    }
                    .padding(.top, 28)
                    .padding(.bottom, 12)
                    .frame(maxWidth: .infinity, minHeight: geo.size.height)
                }
                .scrollBounceBehavior(.basedOnSize)
                .scrollIndicators(.hidden)
                .scrollClipDisabled()   // let the logo glow bleed past the scroll bounds
            }

            Button(action: onNext) {
                Text("Begin Your Healing")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(Color.theme.gradientPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: Color.theme.healPurple.opacity(0.35), radius: 14, y: 4)
            }
            .padding(.horizontal, 32)
            .opacity(showButton ? 1 : 0)
            .offset(y: showButton ? 0 : 20)
            .padding(.top, 12)

            Spacer().frame(height: 60)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                showContent = true
            }
            withAnimation(.easeOut(duration: 0.6).delay(0.5)) {
                showButton = true
            }
            if !reduceMotion {
                withAnimation(.easeInOut(duration: 3.5).repeatForever(autoreverses: true)) {
                    glowPulse = true
                }
            }
        }
        // Heartbeat — double-pulse pattern (fast-fast-rest) at ~1Hz. Bound to the view's
        // lifetime via `.task`, so it stops when the welcome page is gone.
        .task {
            guard !reduceMotion else { return }
            await runHeartbeat()
        }
    }

    /// Heartbeat pattern: quick contraction, quick release, pause, repeat. Returns on cancellation.
    private func runHeartbeat() async {
        while !Task.isCancelled {
            withAnimation(.easeInOut(duration: 0.18)) { heartbeat = true }
            try? await Task.sleep(for: .milliseconds(180))
            withAnimation(.easeInOut(duration: 0.18)) { heartbeat = false }
            try? await Task.sleep(for: .milliseconds(120))
            withAnimation(.easeInOut(duration: 0.18)) { heartbeat = true }
            try? await Task.sleep(for: .milliseconds(180))
            withAnimation(.easeInOut(duration: 0.25)) { heartbeat = false }
            try? await Task.sleep(for: .milliseconds(900))
        }
    }
}

private struct FeatureRow: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(Color.theme.healPurple)
                .frame(width: 44, height: 44)
                .background(Color.theme.healPurple.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 12))


            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.theme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(Color.theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
    }
}

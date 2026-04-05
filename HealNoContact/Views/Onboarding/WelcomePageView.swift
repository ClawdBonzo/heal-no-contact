import SwiftUI

struct WelcomePageView: View {
    let onNext: () -> Void
    @State private var showContent = false
    @State private var showButton = false

    var body: some View {
        VStack(spacing: 40) {
            Spacer()

            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.theme.healPurple.opacity(0.3),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 20,
                                endRadius: 80
                            )
                        )
                        .frame(width: 160, height: 160)

                    Image(systemName: "heart.circle.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(Color.theme.gradientPrimary)
                        .symbolEffect(.breathe, options: .repeating)
                }
                .opacity(showContent ? 1 : 0)
                .scaleEffect(showContent ? 1 : 0.5)

                Text("Heal")
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.theme.gradientPrimary)
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 20)

                Text("Your no-contact companion")
                    .font(.title3)
                    .foregroundStyle(Color.theme.textSecondary)
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 10)
            }

            VStack(spacing: 16) {
                FeatureRow(
                    icon: "shield.checkered",
                    title: "Stay Strong",
                    subtitle: "Track your no-contact streak with support"
                )
                FeatureRow(
                    icon: "book.fill",
                    title: "Process & Reflect",
                    subtitle: "Journal your healing journey privately"
                )
                FeatureRow(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "See Your Growth",
                    subtitle: "Watch your progress and unlock milestones"
                )
                FeatureRow(
                    icon: "sos",
                    title: "Emergency Support",
                    subtitle: "Instant help when the urge hits"
                )
            }
            .padding(.horizontal, 24)
            .opacity(showContent ? 1 : 0)

            Spacer()

            Button(action: onNext) {
                Text("Begin Your Healing")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(Color.theme.gradientPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal, 32)
            .opacity(showButton ? 1 : 0)
            .offset(y: showButton ? 0 : 20)

            Spacer().frame(height: 60)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                showContent = true
            }
            withAnimation(.easeOut(duration: 0.6).delay(0.5)) {
                showButton = true
            }
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
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(Color.theme.textSecondary)
            }

            Spacer()
        }
    }
}

import SwiftUI

struct CommitmentPageView: View {
    @Binding var personalMantra: String
    let onComplete: () -> Void
    @State private var showContent = false
    @State private var showPledge = false
    @State private var hasAgreed = false

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                Spacer().frame(height: 20)

                VStack(spacing: 12) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 48))
                        .foregroundStyle(Color.theme.healGold)
                        .symbolEffect(.variableColor, options: .repeating)

                    Text("Make your commitment")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.theme.textPrimary)

                    Text("Write a mantra to remind yourself\nwhy you're doing this.")
                        .font(.subheadline)
                        .foregroundStyle(Color.theme.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .opacity(showContent ? 1 : 0)

                // Mantra input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Your personal mantra")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color.theme.textSecondary)

                    TextField(
                        "e.g., I choose myself today and every day",
                        text: $personalMantra,
                        axis: .vertical
                    )
                    .lineLimit(2...4)
                    .textFieldStyle(HealTextFieldStyle())

                    Text("This will appear on your dashboard as a daily reminder")
                        .font(.caption)
                        .foregroundStyle(Color.theme.textTertiary)
                }
                .padding(.horizontal, 24)
                .opacity(showContent ? 1 : 0)

                // Pledge card
                VStack(spacing: 16) {
                    Text("Your Pledge")
                        .font(.headline)
                        .foregroundStyle(Color.theme.healGold)

                    Text("I commit to no contact because I deserve peace, growth, and a future built on self-respect. When the urge hits, I will open this app instead of reaching out.")
                        .font(.subheadline)
                        .foregroundStyle(Color.theme.textPrimary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)

                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            hasAgreed.toggle()
                        }
                        HapticService.impact(.medium)
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: hasAgreed
                                  ? "checkmark.square.fill"
                                  : "square")
                                .font(.title3)
                                .foregroundStyle(
                                    hasAgreed
                                    ? Color.theme.healPurple
                                    : Color.theme.textTertiary
                                )

                            Text("I'm ready to commit")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(Color.theme.textPrimary)
                        }
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 8)
                }
                .padding(24)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.theme.cardBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.theme.healGold.opacity(0.2), lineWidth: 1)
                        )
                )
                .padding(.horizontal, 24)
                .opacity(showPledge ? 1 : 0)
                .scaleEffect(showPledge ? 1 : 0.95)

                Button(action: onComplete) {
                    Text("Start My Journey")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            hasAgreed
                            ? AnyShapeStyle(Color.theme.gradientPrimary)
                            : AnyShapeStyle(Color.theme.textTertiary)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .disabled(!hasAgreed)
                .padding(.horizontal, 32)

                Spacer().frame(height: 80)
            }
        }
        .scrollIndicators(.hidden)
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                showContent = true
            }
            withAnimation(.easeOut(duration: 0.6).delay(0.3)) {
                showPledge = true
            }
        }
    }
}

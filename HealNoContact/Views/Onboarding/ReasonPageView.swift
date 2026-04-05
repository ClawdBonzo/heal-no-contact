import SwiftUI

struct ReasonPageView: View {
    @Binding var reason: String
    let onNext: () -> Void
    @State private var showContent = false

    private let reasons = [
        ("heart.slash.fill", "They hurt me and I need space to heal"),
        ("arrow.triangle.2.circlepath", "I keep going back and need to break the cycle"),
        ("person.fill.checkmark", "I need to rediscover who I am"),
        ("brain.fill", "I want clarity and emotional distance"),
        ("sparkles", "I'm choosing growth over comfort"),
        ("pencil.line", "Other reason...")
    ]

    var body: some View {
        VStack(spacing: 32) {
            Spacer().frame(height: 20)

            VStack(spacing: 12) {
                Text("Why are you going\nno contact?")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.theme.textPrimary)
                    .multilineTextAlignment(.center)

                Text("This helps us personalize your journey.\nYour answer stays private on this device.")
                    .font(.subheadline)
                    .foregroundStyle(Color.theme.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .opacity(showContent ? 1 : 0)

            VStack(spacing: 12) {
                ForEach(Array(reasons.enumerated()), id: \.offset) { index, item in
                    ReasonButton(
                        icon: item.0,
                        text: item.1,
                        isSelected: reason == item.1,
                        action: {
                            withAnimation(.spring(response: 0.3)) {
                                reason = item.1
                            }
                            HapticService.selection()
                        }
                    )
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 20)
                    .animation(
                        .easeOut(duration: 0.4).delay(Double(index) * 0.08),
                        value: showContent
                    )
                }
            }
            .padding(.horizontal, 24)

            Spacer()

            Button(action: onNext) {
                Text("Continue")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        reason.isEmpty
                        ? AnyShapeStyle(Color.theme.textTertiary)
                        : AnyShapeStyle(Color.theme.gradientPrimary)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .disabled(reason.isEmpty)
            .padding(.horizontal, 32)

            Spacer().frame(height: 60)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                showContent = true
            }
        }
    }
}

private struct ReasonButton: View {
    let icon: String
    let text: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.body)
                    .foregroundStyle(
                        isSelected ? Color.theme.healPurple : Color.theme.textSecondary
                    )
                    .frame(width: 32)

                Text(text)
                    .font(.subheadline)
                    .foregroundStyle(
                        isSelected ? Color.theme.textPrimary : Color.theme.textSecondary
                    )
                    .multilineTextAlignment(.leading)

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(
                        isSelected ? Color.theme.healPurple : Color.theme.textTertiary
                    )
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.theme.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(
                                isSelected
                                ? Color.theme.healPurple.opacity(0.6)
                                : Color.clear,
                                lineWidth: 1.5
                            )
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

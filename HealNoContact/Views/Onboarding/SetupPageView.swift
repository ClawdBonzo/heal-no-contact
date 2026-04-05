import SwiftUI

struct SetupPageView: View {
    @Binding var exName: String
    @Binding var breakupDate: Date
    @Binding var relationshipDuration: String
    @Binding var goalDays: Int
    let onNext: () -> Void
    @State private var showContent = false

    private let goalOptions = [14, 21, 30, 60, 90, 180, 365]
    private let durationOptions = [
        "Less than 6 months",
        "6 months – 1 year",
        "1 – 2 years",
        "2 – 5 years",
        "5+ years"
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                Spacer().frame(height: 20)

                VStack(spacing: 12) {
                    Text("Let's set things up")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.theme.textPrimary)

                    Text("This information is stored only on your device.")
                        .font(.subheadline)
                        .foregroundStyle(Color.theme.textSecondary)
                }
                .opacity(showContent ? 1 : 0)

                VStack(spacing: 20) {
                    // Ex name (optional)
                    FormField(label: "Their name (optional)") {
                        TextField("First name or initials", text: $exName)
                            .textFieldStyle(HealTextFieldStyle())
                    }

                    // Breakup date
                    FormField(label: "When did you break up?") {
                        DatePicker(
                            "Breakup date",
                            selection: $breakupDate,
                            in: ...Date.now,
                            displayedComponents: .date
                        )
                        .datePickerStyle(.compact)
                        .tint(Color.theme.healPurple)
                        .labelsHidden()
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color.theme.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    // Relationship duration
                    FormField(label: "How long were you together?") {
                        FlowLayout(spacing: 8) {
                            ForEach(durationOptions, id: \.self) { option in
                                ChipButton(
                                    text: option,
                                    isSelected: relationshipDuration == option,
                                    action: { relationshipDuration = option }
                                )
                            }
                        }
                    }

                    // Goal days
                    FormField(label: "Your no-contact goal") {
                        FlowLayout(spacing: 8) {
                            ForEach(goalOptions, id: \.self) { days in
                                ChipButton(
                                    text: days == 365 ? "1 year" : "\(days) days",
                                    isSelected: goalDays == days,
                                    action: { goalDays = days }
                                )
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
                .opacity(showContent ? 1 : 0)

                Button(action: onNext) {
                    Text("Continue")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(Color.theme.gradientPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .padding(.horizontal, 32)

                Spacer().frame(height: 80)
            }
        }
        .scrollIndicators(.hidden)
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                showContent = true
            }
        }
    }
}

private struct FormField<Content: View>: View {
    let label: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Color.theme.textSecondary)
            content
        }
    }
}

private struct ChipButton: View {
    let text: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: {
            action()
            HapticService.selection()
        }) {
            Text(text)
                .font(.subheadline)
                .foregroundStyle(
                    isSelected ? .white : Color.theme.textSecondary
                )
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    isSelected
                    ? AnyShapeStyle(Color.theme.healPurple)
                    : AnyShapeStyle(Color.theme.cardBackground)
                )
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(
                            isSelected
                            ? Color.clear
                            : Color.theme.textTertiary.opacity(0.3),
                            lineWidth: 1
                        )
                )
        }
        .buttonStyle(.plain)
    }
}

struct HealTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color.theme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .foregroundStyle(Color.theme.textPrimary)
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = layout(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = layout(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                proposal: .unspecified
            )
        }
    }

    private func layout(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var maxX: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > maxWidth, currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            positions.append(CGPoint(x: currentX, y: currentY))
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
            maxX = max(maxX, currentX)
        }

        return (
            CGSize(width: maxX, height: currentY + lineHeight),
            positions
        )
    }
}

import SwiftUI

struct SetupPageView: View {
    @Binding var exName: String
    @Binding var breakupDate: Date
    @Binding var relationshipDuration: String
    @Binding var goalDays: Int
    let onNext: () -> Void
    @State private var showContent = false
    @State private var glowPulse = false
    @State private var showCustomGoal = false
    @State private var customGoalText = ""
    @FocusState private var customFieldFocused: Bool

    private let goalOptions = [14, 21, 30, 60, 90, 180, 365]
    private let durationOptions = [
        "Less than 6 months",
        "6 months – 1 year",
        "1 – 2 years",
        "2 – 5 years",
        "5+ years"
    ]

    private var isCustomGoal: Bool {
        !goalOptions.contains(goalDays)
    }

    var body: some View {
        VStack(spacing: 22) {
            Spacer().frame(height: 30)

            // Header icon with purple glow
            ZStack {
                Circle()
                    .fill(Color.theme.healPurple.opacity(0.18))
                    .frame(width: 110, height: 110)
                    .blur(radius: 20)
                    .scaleEffect(glowPulse ? 1.12 : 0.95)

                Circle()
                    .fill(Color.theme.healPurple.opacity(0.12))
                    .frame(width: 84, height: 84)

                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundStyle(Color.theme.gradientPrimary)
                    .shadow(color: Color.theme.healPurple.opacity(0.5), radius: 10)
            }
            .opacity(showContent ? 1 : 0)
            .scaleEffect(showContent ? 1 : 0.6)

            VStack(spacing: 6) {
                Text("Let's set things up")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.theme.textPrimary)

                Text("Stored only on your device.")
                    .font(.footnote)
                    .foregroundStyle(Color.theme.textSecondary)
            }
            .opacity(showContent ? 1 : 0)

            VStack(spacing: 20) {
                // Name + Date side by side
                HStack(alignment: .top, spacing: 12) {
                    FormField(label: "Their name") {
                        TextField("Optional", text: $exName)
                            .textFieldStyle(HealTextFieldStyle())
                    }

                    FormField(label: "Breakup date") {
                        DatePicker(
                            "Breakup date",
                            selection: $breakupDate,
                            in: ...Date.now,
                            displayedComponents: .date
                        )
                        .datePickerStyle(.compact)
                        .tint(Color.theme.healPurple)
                        .labelsHidden()
                        .padding(.horizontal, 10)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.theme.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
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

                // Goal days + custom
                FormField(label: "Your no-contact goal") {
                    VStack(alignment: .leading, spacing: 10) {
                        FlowLayout(spacing: 8) {
                            ForEach(goalOptions, id: \.self) { days in
                                ChipButton(
                                    text: days == 365 ? "1 year" : "\(days) days",
                                    isSelected: goalDays == days && !showCustomGoal,
                                    action: {
                                        showCustomGoal = false
                                        customFieldFocused = false
                                        goalDays = days
                                    }
                                )
                            }
                            ChipButton(
                                text: isCustomGoal ? "\(goalDays) days" : "Custom",
                                isSelected: showCustomGoal || isCustomGoal,
                                action: {
                                    withAnimation(.spring(response: 0.3)) {
                                        showCustomGoal.toggle()
                                    }
                                    if showCustomGoal {
                                        customGoalText = isCustomGoal ? "\(goalDays)" : ""
                                        customFieldFocused = true
                                    }
                                }
                            )
                        }

                        if showCustomGoal {
                            HStack(spacing: 10) {
                                TextField("Enter days (1–365)", text: $customGoalText)
                                    .keyboardType(.numberPad)
                                    .focused($customFieldFocused)
                                    .textFieldStyle(HealTextFieldStyle())
                                    .onChange(of: customGoalText) { _, newValue in
                                        if let value = Int(newValue), value >= 1, value <= 365 {
                                            goalDays = value
                                        }
                                    }

                                Text("days")
                                    .font(.subheadline)
                                    .foregroundStyle(Color.theme.textSecondary)
                            }
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                }
            }
            .padding(.horizontal, 24)
            .opacity(showContent ? 1 : 0)

            Spacer()

            Button(action: onNext) {
                Text("Continue")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(Color.theme.gradientPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: Color.theme.healPurple.opacity(0.3), radius: 12, y: 4)
            }
            .padding(.horizontal, 32)

            Spacer().frame(height: 70)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                showContent = true
            }
            withAnimation(.easeInOut(duration: 3.5).repeatForever(autoreverses: true)) {
                glowPulse = true
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

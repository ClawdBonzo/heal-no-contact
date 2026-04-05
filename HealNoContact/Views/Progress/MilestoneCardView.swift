import SwiftUI

struct MilestoneCardView: View {
    let milestone: Milestone
    let currentDays: Int

    private var isUpcoming: Bool {
        !milestone.isUnlocked && milestone.dayTarget > currentDays
    }

    private var progressToMilestone: Double {
        guard milestone.dayTarget > 0 else { return 0 }
        return min(Double(currentDays) / Double(milestone.dayTarget), 1.0)
    }

    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(
                        milestone.isUnlocked
                        ? Color.theme.healGold.opacity(0.2)
                        : Color.theme.textTertiary.opacity(0.1)
                    )
                    .frame(width: 48, height: 48)

                Image(systemName: milestone.iconName)
                    .font(.title3)
                    .foregroundStyle(
                        milestone.isUnlocked
                        ? Color.theme.healGold
                        : Color.theme.textTertiary
                    )
            }

            // Content
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(milestone.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(
                            milestone.isUnlocked
                            ? Color.theme.textPrimary
                            : Color.theme.textSecondary
                        )

                    if milestone.isUnlocked {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.caption)
                            .foregroundStyle(Color.theme.healGold)
                    }
                }

                Text(milestone.subtitle)
                    .font(.caption)
                    .foregroundStyle(Color.theme.textTertiary)

                if milestone.isUnlocked, let unlockedAt = milestone.unlockedAt {
                    Text("Unlocked \(unlockedAt.relativeFormatted)")
                        .font(.caption2)
                        .foregroundStyle(Color.theme.healGold.opacity(0.7))
                } else if isUpcoming {
                    // Progress bar
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.theme.textTertiary.opacity(0.2))
                                .frame(height: 4)

                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.theme.healPurple)
                                .frame(
                                    width: geo.size.width * progressToMilestone,
                                    height: 4
                                )
                        }
                    }
                    .frame(height: 4)
                    .padding(.top, 4)
                }
            }

            Spacer()

            // Day target
            Text("Day \(milestone.dayTarget)")
                .font(.caption.weight(.medium).monospacedDigit())
                .foregroundStyle(
                    milestone.isUnlocked
                    ? Color.theme.healGold
                    : Color.theme.textTertiary
                )
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.theme.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(
                            milestone.isUnlocked
                            ? Color.theme.healGold.opacity(0.15)
                            : Color.clear,
                            lineWidth: 1
                        )
                )
        )
        .opacity(isUpcoming && milestone.dayTarget > currentDays + 30 ? 0.6 : 1.0)
    }
}

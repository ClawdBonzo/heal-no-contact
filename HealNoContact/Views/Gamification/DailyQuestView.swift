import SwiftUI

struct DailyQuestView: View {
    let quest: Quest
    let onProgress: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: quest.icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Color.theme.healGold)
                    .frame(width: 40, height: 40)
                    .background(Color.theme.healGold.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                VStack(alignment: .leading, spacing: 4) {
                    Text(quest.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.theme.textPrimary)

                    Text(quest.details)
                        .font(.caption)
                        .foregroundStyle(Color.theme.textSecondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("+\(quest.xpReward)")
                        .font(.body.weight(.bold))
                        .foregroundStyle(Color.theme.healGold)

                    Text("XP")
                        .font(.caption2)
                        .foregroundStyle(Color.theme.textTertiary)
                }
            }

            if quest.targetCount > 1 {
                HStack(spacing: 8) {
                    ProgressView(value: quest.progressPercentage)
                        .tint(quest.isCompleted ? Color.theme.healGold : Color.theme.healPurple)

                    Text("\(quest.currentProgress)/\(quest.targetCount)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.theme.textSecondary)
                }
            }

            if !quest.isCompleted {
                Button(action: onProgress) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Progress")
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(10)
                    .background(Color.theme.gradientPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            } else {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Completed!")
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.theme.healGold)
                .frame(maxWidth: .infinity)
                .padding(10)
                .background(Color.theme.healGold.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
        .padding(14)
        .background(Color.theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .opacity(quest.isExpired ? 0.5 : 1.0)
    }
}

#Preview {
    let userId = UUID()
    let quest = Quest(
        userId: userId,
        type: .daily,
        title: "Daily Check-In",
        details: "Log your mood today",
        icon: "heart.fill",
        targetCount: 1,
        xpReward: 10,
        expiresAt: Date.now.addingTimeInterval(86400)
    )

    return DailyQuestView(quest: quest, onProgress: {})
        .preferredColorScheme(.dark)
}

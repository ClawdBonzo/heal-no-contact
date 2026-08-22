import SwiftUI

/// One quest, one row. Quests progress on their own from real actions (check-in, journal,
/// riding out an urge, another day of no contact) — there is nothing to tap.
struct QuestRow: View {
    let quest: Quest

    private var tint: Color { quest.isCompleted ? Color.theme.healTeal : Color.theme.healGold }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .stroke(tint.opacity(0.25), lineWidth: 3)
                Circle()
                    .trim(from: 0, to: quest.isCompleted ? 1 : quest.progressPercentage)
                    .stroke(tint, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.easeOut(duration: 0.5), value: quest.currentProgress)
                Image(systemName: quest.isCompleted ? "checkmark" : quest.icon)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(tint)
            }
            .frame(width: 36, height: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text(quest.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(quest.isCompleted ? Color.theme.textSecondary : Color.theme.textPrimary)
                    .strikethrough(quest.isCompleted, color: Color.theme.textTertiary)
                Text(quest.targetCount > 1
                     ? String(localized: "\(quest.currentProgress) of \(quest.targetCount) · \(quest.details)")
                     : quest.details)
                    .font(.caption)
                    .foregroundStyle(Color.theme.textTertiary)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            Text(quest.isCompleted ? String(localized: "Done") : "+\(quest.xpReward) XP")
                .font(.caption.weight(.bold).monospacedDigit())
                .foregroundStyle(tint)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.theme.cardBackground)
        )
        .accessibilityElement(children: .combine)
        .accessibilityValue(Text(quest.isCompleted ? String(localized: "Done") : String(localized: "\(quest.currentProgress) of \(quest.targetCount)")))
    }
}

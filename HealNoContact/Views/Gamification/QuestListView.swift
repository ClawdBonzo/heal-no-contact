import SwiftUI

struct QuestListView: View {
    let quests: [Quest]
    let onProgressQuest: (UUID) -> Void

    var dailyQuests: [Quest] {
        quests.filter { $0.type == .daily && !$0.isExpired }
    }

    var weeklyQuests: [Quest] {
        quests.filter { $0.type == .weekly && !$0.isExpired }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            if !dailyQuests.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Daily Quests")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(Color.theme.textPrimary)

                    ForEach(dailyQuests, id: \.id) { quest in
                        DailyQuestView(quest: quest) {
                            onProgressQuest(quest.id)
                        }
                    }
                }
            }

            if !weeklyQuests.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Weekly Quests")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(Color.theme.textPrimary)

                    ForEach(weeklyQuests, id: \.id) { quest in
                        DailyQuestView(quest: quest) {
                            onProgressQuest(quest.id)
                        }
                    }
                }
            }

            if dailyQuests.isEmpty && weeklyQuests.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "list.dash")
                        .font(.system(size: 32))
                        .foregroundStyle(Color.theme.textTertiary)

                    Text("No active quests")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.theme.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(32)
            }
        }
    }
}

#Preview {
    QuestListView(quests: [], onProgressQuest: { _ in })
        .preferredColorScheme(.dark)
}

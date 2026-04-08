import SwiftUI
import SwiftData

struct GameificationDashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var gamificationService: GameificationService?
    @State private var showLevelUpModal = false
    @State private var levelUpData: (oldLevel: Int, newLevel: Int)? = nil

    var userId: UUID
    var gamification: UserGamification?
    var streakDays: Int = 0
    var journalEntryCount: Int = 0
    var moodCheckInCount: Int = 0

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if let gamification = gamification, let service = gamificationService {
                    LevelBadgeView(gamification: gamification, showAnimation: true)

                    XPBarView(gamification: gamification)

                    if let flame = service.streakFlame {
                        StreakFlameView(flame: flame)
                    }

                    QuestListView(quests: service.quests) { questId in
                        service.progressQuest(questId: questId)
                    }

                    BadgeShowcaseView(badges: service.badges, allBadges: [])
                }
            }
            .padding(20)
        }
        .background(Color.theme.deepBackground)
        .onAppear {
            setupGamification()
            checkMilestones()
        }
        .onChange(of: gamificationService?.levelUpAward) { _, newValue in
            if let award = newValue {
                levelUpData = award
                showLevelUpModal = true
            }
        }
        .sheet(isPresented: $showLevelUpModal) {
            if let levelUp = levelUpData {
                ZStack {
                    Color.black.opacity(0.5).ignoresSafeArea()

                    VStack {
                        LevelUpModalView(
                            oldLevel: levelUp.oldLevel,
                            newLevel: levelUp.newLevel,
                            levelName: ""
                        ) {
                            showLevelUpModal = false
                            gamificationService?.levelUpAward = nil
                        }
                    }
                }
                .presentationBackground(.clear)
            }
        }
    }

    private func setupGamification() {
        if gamificationService == nil {
            let service = GameificationService(modelContext: modelContext)
            service.initializeGamification(for: userId)
            gamificationService = service
        }
    }

    private func checkMilestones() {
        gamificationService?.checkMilestoneBadges(
            streakDays: streakDays,
            journalEntryCount: journalEntryCount,
            moodCheckInCount: moodCheckInCount
        )
    }
}

#Preview {
    GameificationDashboardView(userId: UUID())
        .preferredColorScheme(.dark)
}

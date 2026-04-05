import SwiftUI
import SwiftData

struct OnboardingContainerView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var currentPage = 0
    @State private var exName = ""
    @State private var breakupDate = Date.now
    @State private var noContactGoalDays = 30
    @State private var reasonForNoContact = ""
    @State private var personalMantra = ""
    @State private var relationshipDuration = ""

    private let totalPages = 4

    var body: some View {
        ZStack {
            Color.theme.deepBackground.ignoresSafeArea()
            AnimatedGradientBackground()

            TabView(selection: $currentPage) {
                WelcomePageView(onNext: nextPage)
                    .tag(0)

                ReasonPageView(
                    reason: $reasonForNoContact,
                    onNext: nextPage
                )
                .tag(1)

                SetupPageView(
                    exName: $exName,
                    breakupDate: $breakupDate,
                    relationshipDuration: $relationshipDuration,
                    goalDays: $noContactGoalDays,
                    onNext: nextPage
                )
                .tag(2)

                CommitmentPageView(
                    personalMantra: $personalMantra,
                    onComplete: completeOnboarding
                )
                .tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut(duration: 0.3), value: currentPage)

            // Page indicator
            VStack {
                Spacer()
                HStack(spacing: 8) {
                    ForEach(0..<totalPages, id: \.self) { index in
                        Capsule()
                            .fill(index == currentPage
                                  ? Color.theme.healPurple
                                  : Color.theme.textTertiary)
                            .frame(
                                width: index == currentPage ? 24 : 8,
                                height: 8
                            )
                            .animation(.spring(response: 0.3), value: currentPage)
                    }
                }
                .padding(.bottom, 30)
            }
        }
    }

    private func nextPage() {
        withAnimation {
            currentPage = min(currentPage + 1, totalPages - 1)
        }
        HapticService.selection()
    }

    private func completeOnboarding() {
        let profile = UserProfile(
            exName: exName,
            relationshipDuration: relationshipDuration,
            breakupDate: breakupDate,
            noContactStartDate: .now,
            noContactGoalDays: noContactGoalDays,
            reasonForNoContact: reasonForNoContact,
            personalMantra: personalMantra.isEmpty
                ? "I choose myself today and every day"
                : personalMantra,
            hasCompletedOnboarding: true
        )
        modelContext.insert(profile)

        // Seed default milestones
        for milestone in Milestone.defaultMilestones {
            let m = Milestone(
                title: milestone.0,
                subtitle: milestone.1,
                dayTarget: milestone.2,
                iconName: milestone.3
            )
            modelContext.insert(m)
        }

        // Request notification permissions
        Task {
            let granted = await NotificationService.shared.requestPermission()
            if granted {
                NotificationService.shared.scheduleDailyCheckIn(at: profile.dailyCheckInTime)
                NotificationService.shared.scheduleEncouragementNotifications()
            }
        }

        HapticService.milestone()
    }
}

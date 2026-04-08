import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @State private var showResetAlert = false
    @State private var showDeleteAlert = false
    @State private var showPaywall = false

    private var profile: UserProfile? { profiles.first }

    var body: some View {
        NavigationStack {
            List {
                // Premium section
                if !appState.isPremium {
                    Section {
                        Button {
                            showPaywall = true
                        } label: {
                            HStack(spacing: 14) {
                                Image(systemName: "crown.fill")
                                    .font(.title2)
                                    .foregroundStyle(Color.theme.healGold)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Upgrade to Premium")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(Color.theme.textPrimary)
                                    Text("Unlock all features & support development")
                                        .font(.caption)
                                        .foregroundStyle(Color.theme.textSecondary)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .listRowBackground(Color.theme.healGold.opacity(0.08))
                }

                // Profile section
                Section("Your Journey") {
                    if let profile {
                        SettingsRow(
                            icon: "calendar",
                            label: "No-contact start",
                            value: profile.noContactStartDate.monthDay,
                            color: Color.theme.healPurple
                        )

                        SettingsRow(
                            icon: "target",
                            label: "Goal",
                            value: "\(profile.noContactGoalDays) days",
                            color: Color.theme.healTeal
                        )

                        SettingsRow(
                            icon: "flame.fill",
                            label: "Current streak",
                            value: "\(profile.currentStreakDays) days",
                            color: Color.theme.healPink
                        )

                        SettingsRow(
                            icon: "trophy.fill",
                            label: "Best streak",
                            value: "\(max(profile.streakBestDays, profile.currentStreakDays)) days",
                            color: Color.theme.healGold
                        )

                        SettingsRow(
                            icon: "arrow.counterclockwise",
                            label: "Total resets",
                            value: "\(profile.totalResets)",
                            color: Color.theme.textSecondary
                        )
                    }
                }
                .listRowBackground(Color.theme.cardBackground)

                // Notifications
                Section("Notifications") {
                    if let profile {
                        Toggle(isOn: Binding(
                            get: { profile.notificationsEnabled },
                            set: { newValue in
                                profile.notificationsEnabled = newValue
                                if newValue {
                                    Task {
                                        let granted = await NotificationService.shared.requestPermission()
                                        if granted {
                                            NotificationService.shared.scheduleDailyCheckIn(
                                                at: profile.dailyCheckInTime
                                            )
                                            NotificationService.shared.scheduleEncouragementNotifications()
                                        }
                                    }
                                } else {
                                    NotificationService.shared.cancelAll()
                                }
                            }
                        )) {
                            Label("Daily Reminders", systemImage: "bell.fill")
                                .foregroundStyle(Color.theme.textPrimary)
                        }
                        .tint(Color.theme.healPurple)
                    }
                }
                .listRowBackground(Color.theme.cardBackground)

                // Edit journey
                Section("Manage") {
                    Button {
                        showResetAlert = true
                    } label: {
                        Label("Reset Streak", systemImage: "arrow.counterclockwise")
                            .foregroundStyle(Color.theme.healPink)
                    }

                    Button {
                        showDeleteAlert = true
                    } label: {
                        Label("Delete All Data", systemImage: "trash")
                            .foregroundStyle(.red)
                    }
                }
                .listRowBackground(Color.theme.cardBackground)

                // About
                Section {
                    VStack(spacing: 12) {
                        Image("BrandIcon")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 64, height: 64)
                            .clipShape(RoundedRectangle(cornerRadius: 15))

                        Text("Heal")
                            .font(.headline)
                            .foregroundStyle(Color.theme.textPrimary)

                        Text("No-Contact Recovery")
                            .font(.caption)
                            .foregroundStyle(Color.theme.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                } header: {
                    Text("About")
                }
                .listRowBackground(Color.theme.cardBackground)

                Section {
                    SettingsRow(
                        icon: "lock.shield.fill",
                        label: "Privacy",
                        value: "100% on-device",
                        color: Color.theme.healTeal
                    )

                    SettingsRow(
                        icon: "info.circle.fill",
                        label: "Version",
                        value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0",
                        color: Color.theme.textSecondary
                    )

                    Link(destination: URL(string: "https://apple.com")!) {
                        Label("Rate on App Store", systemImage: "star.fill")
                            .foregroundStyle(Color.theme.healGold)
                    }
                }
                .listRowBackground(Color.theme.cardBackground)
            }
            .scrollContentBackground(.hidden)
            .background(Color.theme.deepBackground)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .alert("Reset your streak?", isPresented: $showResetAlert) {
                Button("Reset", role: .destructive) {
                    profile?.resetStreak()
                    HapticService.notification(.warning)
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Your current streak will be reset to 0. Your best streak and history will be preserved.")
            }
            .alert("Delete all data?", isPresented: $showDeleteAlert) {
                Button("Delete Everything", role: .destructive) {
                    deleteAllData()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will permanently delete all your journal entries, mood data, milestones, and profile. This cannot be undone.")
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
        }
    }

    private func deleteAllData() {
        do {
            try modelContext.delete(model: UserProfile.self)
            try modelContext.delete(model: JournalEntry.self)
            try modelContext.delete(model: MoodEntry.self)
            try modelContext.delete(model: Milestone.self)
            try modelContext.delete(model: EmergencyLog.self)
            try modelContext.delete(model: LetterEntry.self)
            NotificationService.shared.cancelAll()
            HapticService.notification(.success)
        } catch {
            print("Failed to delete data: \(error)")
        }
    }
}

private struct SettingsRow: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        HStack {
            Label(label, systemImage: icon)
                .foregroundStyle(Color.theme.textPrimary)

            Spacer()

            Text(value)
                .font(.subheadline)
                .foregroundStyle(color)
        }
    }
}

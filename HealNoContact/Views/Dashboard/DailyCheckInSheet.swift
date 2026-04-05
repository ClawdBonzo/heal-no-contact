import SwiftUI
import SwiftData

struct DailyCheckInSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var profiles: [UserProfile]
    @State private var selectedMood: JournalEntry.MoodType = .neutral
    @State private var intensity: Double = 5
    @State private var note = ""
    @State private var didContact = false
    @State private var showConfirmReset = false

    private var profile: UserProfile? { profiles.first }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    // Mood selector
                    VStack(spacing: 12) {
                        Text("How are you feeling?")
                            .font(.headline)
                            .foregroundStyle(Color.theme.textPrimary)

                        LazyVGrid(
                            columns: Array(
                                repeating: GridItem(.flexible(), spacing: 8),
                                count: 4
                            ),
                            spacing: 12
                        ) {
                            ForEach(JournalEntry.MoodType.allCases) { mood in
                                MoodButton(
                                    mood: mood,
                                    isSelected: selectedMood == mood,
                                    action: {
                                        selectedMood = mood
                                        HapticService.selection()
                                    }
                                )
                            }
                        }
                    }

                    // Intensity slider
                    VStack(spacing: 8) {
                        HStack {
                            Text("Intensity")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(Color.theme.textSecondary)
                            Spacer()
                            Text("\(Int(intensity))/10")
                                .font(.subheadline.monospacedDigit())
                                .foregroundStyle(Color.theme.textTertiary)
                        }

                        Slider(value: $intensity, in: 1...10, step: 1)
                            .tint(Color.theme.healPurple)
                    }

                    // Note
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Quick note (optional)")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Color.theme.textSecondary)

                        TextField("How's your day going?", text: $note, axis: .vertical)
                            .lineLimit(3...5)
                            .textFieldStyle(HealTextFieldStyle())
                    }

                    // Did you make contact?
                    VStack(spacing: 12) {
                        Text("Did you contact your ex today?")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Color.theme.textSecondary)

                        HStack(spacing: 12) {
                            ContactChoiceButton(
                                title: "No, stayed strong!",
                                icon: "hand.thumbsup.fill",
                                isSelected: !didContact,
                                color: Color.theme.healTeal,
                                action: { didContact = false }
                            )

                            ContactChoiceButton(
                                title: "Yes, I slipped",
                                icon: "arrow.uturn.backward",
                                isSelected: didContact,
                                color: Color.theme.healPink,
                                action: { didContact = true }
                            )
                        }
                    }

                    // Save button
                    Button {
                        saveCheckIn()
                    } label: {
                        Text("Save Check-In")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.theme.gradientPrimary)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }
                .padding(24)
            }
            .background(Color.theme.deepBackground)
            .navigationTitle("Daily Check-In")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color.theme.textSecondary)
                }
            }
            .alert("Reset your streak?", isPresented: $showConfirmReset) {
                Button("Yes, reset", role: .destructive) {
                    profile?.resetStreak()
                    finishSave()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Honesty takes courage. Your streak will reset, but your growth won't.")
            }
        }
    }

    private func saveCheckIn() {
        let mood = MoodEntry(
            mood: selectedMood,
            intensity: Int(intensity),
            note: note
        )
        modelContext.insert(mood)
        profile?.lastCheckInDate = .now

        if didContact {
            showConfirmReset = true
        } else {
            finishSave()
        }
    }

    private func finishSave() {
        HapticService.notification(.success)
        dismiss()
    }
}

private struct MoodButton: View {
    let mood: JournalEntry.MoodType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Text(mood.emoji)
                    .font(.title2)

                Text(mood.rawValue)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(
                        isSelected ? Color.theme.textPrimary : Color.theme.textTertiary
                    )
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        isSelected
                        ? Color.theme.healPurple.opacity(0.2)
                        : Color.theme.cardBackground
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                isSelected
                                ? Color.theme.healPurple.opacity(0.5)
                                : Color.clear,
                                lineWidth: 1
                            )
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

private struct ContactChoiceButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: {
            action()
            HapticService.selection()
        }) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(isSelected ? color : Color.theme.textTertiary)

                Text(title)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(
                        isSelected ? Color.theme.textPrimary : Color.theme.textTertiary
                    )
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(
                        isSelected
                        ? color.opacity(0.15)
                        : Color.theme.cardBackground
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(
                                isSelected ? color.opacity(0.4) : Color.clear,
                                lineWidth: 1
                            )
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

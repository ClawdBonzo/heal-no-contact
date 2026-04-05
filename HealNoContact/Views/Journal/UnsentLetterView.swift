import SwiftUI
import SwiftData

struct UnsentLetterView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var profiles: [UserProfile]
    @State private var letterBody = ""
    @State private var selectedMood: JournalEntry.MoodType = .sad
    @State private var showSaved = false

    private var recipientName: String {
        profiles.first?.exName.isEmpty == false ? profiles.first!.exName : "them"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "envelope.open.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(Color.theme.healPurple)

                        Text("Unsent Letter")
                            .font(.title2.weight(.bold))
                            .foregroundStyle(Color.theme.textPrimary)

                        Text("Write everything you want to say.\nThis letter will never be sent — it's for you.")
                            .font(.subheadline)
                            .foregroundStyle(Color.theme.textSecondary)
                            .multilineTextAlignment(.center)
                    }

                    // Letter
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Dear \(recipientName),")
                            .font(.subheadline.italic())
                            .foregroundStyle(Color.theme.textSecondary)

                        ZStack(alignment: .topLeading) {
                            if letterBody.isEmpty {
                                Text("Say what you need to say...")
                                    .foregroundStyle(Color.theme.textTertiary)
                                    .padding(.top, 8)
                            }

                            TextEditor(text: $letterBody)
                                .scrollContentBackground(.hidden)
                                .foregroundStyle(Color.theme.textPrimary)
                                .frame(minHeight: 250)
                        }
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.theme.cardBackground)
                    )

                    // Save button
                    Button {
                        saveLetter()
                    } label: {
                        Label("Save & Seal", systemImage: "lock.fill")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.theme.gradientPrimary)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(letterBody.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                    Text("Your letter is stored privately on this device and never transmitted anywhere.")
                        .font(.caption)
                        .foregroundStyle(Color.theme.textTertiary)
                        .multilineTextAlignment(.center)
                }
                .padding(20)
            }
            .background(Color.theme.deepBackground)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color.theme.textSecondary)
                }
            }
            .overlay {
                if showSaved {
                    SavedConfirmationView()
                        .transition(.scale.combined(with: .opacity))
                }
            }
        }
    }

    private func saveLetter() {
        let letter = LetterEntry(
            recipient: recipientName,
            body: letterBody,
            mood: selectedMood
        )
        modelContext.insert(letter)

        // Also save as a journal entry
        let journalEntry = JournalEntry(
            title: "Unsent Letter to \(recipientName)",
            body: letterBody,
            mood: selectedMood,
            tags: ["unsent-letter"]
        )
        modelContext.insert(journalEntry)

        HapticService.notification(.success)

        withAnimation(.spring(response: 0.3)) {
            showSaved = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            dismiss()
        }
    }
}

private struct SavedConfirmationView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "lock.fill")
                .font(.system(size: 44))
                .foregroundStyle(Color.theme.healPurple)
                .symbolEffect(.bounce)

            Text("Letter Sealed")
                .font(.title3.weight(.bold))
                .foregroundStyle(Color.theme.textPrimary)

            Text("Your words are safe.")
                .font(.subheadline)
                .foregroundStyle(Color.theme.textSecondary)
        }
        .padding(40)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThinMaterial)
        )
    }
}

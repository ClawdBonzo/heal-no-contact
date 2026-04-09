import SwiftUI
import SwiftData

struct JournalEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var profiles: [UserProfile]
    var existingEntry: JournalEntry?

    @State private var title = ""
    @State private var body_ = ""
    @State private var selectedMood: JournalEntry.MoodType = .neutral
    @State private var isFavorite = false
    @State private var gamificationService: GameificationService?
    @State private var showSaveFlash = false

    private var isEditing: Bool { existingEntry != nil }
    private var profile: UserProfile? { profiles.first }

    private let prompts = [
        "What's on your mind right now?",
        "What triggered you today and how did you handle it?",
        "Write about something you're grateful for.",
        "What would you say to yourself 6 months from now?",
        "Describe a small win from today.",
        "What's one thing you learned about yourself recently?",
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                ScrollView {
                    VStack(spacing: 24) {
                    // Mood selector
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Mood")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Color.theme.textSecondary)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(JournalEntry.MoodType.allCases) { mood in
                                    Button {
                                        selectedMood = mood
                                        HapticService.selection()
                                    } label: {
                                        VStack(spacing: 4) {
                                            Text(mood.emoji)
                                                .font(.title3)
                                            Text(mood.rawValue)
                                                .font(.system(size: 9))
                                                .foregroundStyle(
                                                    selectedMood == mood
                                                    ? Color.theme.textPrimary
                                                    : Color.theme.textTertiary
                                                )
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 10)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(
                                                    selectedMood == mood
                                                    ? Color.theme.healPurple.opacity(0.2)
                                                    : Color.theme.cardBackground
                                                )
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }

                    // Title
                    TextField("Title (optional)", text: $title)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(Color.theme.textPrimary)

                    // Writing prompt
                    if body_.isEmpty && !isEditing {
                        Button {
                            body_ = prompts.randomElement() ?? ""
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "lightbulb.fill")
                                    .foregroundStyle(Color.theme.healGold)
                                Text("Tap for a writing prompt")
                                    .foregroundStyle(Color.theme.textSecondary)
                            }
                            .font(.subheadline)
                        }
                    }

                    // Body
                    ZStack(alignment: .topLeading) {
                        if body_.isEmpty {
                            Text("Start writing...")
                                .foregroundStyle(Color.theme.textTertiary)
                                .padding(.top, 8)
                        }

                        TextEditor(text: $body_)
                            .scrollContentBackground(.hidden)
                            .foregroundStyle(Color.theme.textPrimary)
                            .frame(minHeight: 200)
                    }
                }
                    .padding(20)
                }
                .background(Color.theme.deepBackground)

                // Golden save flash overlay
                if showSaveFlash {
                    Color(red: 0.95, green: 0.75, blue: 0.30).opacity(0.18)
                        .ignoresSafeArea()
                        .allowsHitTesting(false)
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(Color(red: 0.95, green: 0.75, blue: 0.30))
                        .shadow(color: Color(red: 0.95, green: 0.75, blue: 0.30).opacity(0.6), radius: 20)
                        .transition(.scale.combined(with: .opacity))
                }
            } // end ZStack
            .navigationTitle(isEditing ? "Edit Entry" : "New Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color.theme.textSecondary)
                }

                ToolbarItem(placement: .primaryAction) {
                    Button {
                        saveEntry()
                    } label: {
                        Text("Save")
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.theme.healPurple)
                    }
                    .disabled(body_.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }

                ToolbarItem(placement: .secondaryAction) {
                    Button {
                        isFavorite.toggle()
                    } label: {
                        Image(systemName: isFavorite ? "heart.fill" : "heart")
                            .foregroundStyle(
                                isFavorite ? Color.theme.healPink : Color.theme.textSecondary
                            )
                    }
                }
            }
            .onAppear {
                if let entry = existingEntry {
                    title = entry.title
                    body_ = entry.body
                    selectedMood = entry.mood
                    isFavorite = entry.isFavorite
                }
            }
        }
    }

    private func saveEntry() {
        if let entry = existingEntry {
            entry.title = title
            entry.body = body_
            entry.mood = selectedMood
            entry.isFavorite = isFavorite
            entry.updatedAt = .now
        } else {
            let entry = JournalEntry(
                title: title,
                body: body_,
                mood: selectedMood,
                isFavorite: isFavorite
            )
            modelContext.insert(entry)

            // Award XP for new journal entry
            if gamificationService == nil, let userId = profile?.id {
                let service = GameificationService(modelContext: modelContext)
                service.initializeGamification(for: userId)
                gamificationService = service
            }
            gamificationService?.addXP(15, reason: "Journal Entry")
            gamificationService?.progressQuest(questId: UUID()) // Progress journal quest
        }

        HapticService.notification(.success)
        // Brief golden flash before dismiss
        withAnimation(.easeOut(duration: 0.2)) { showSaveFlash = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { dismiss() }
    }
}

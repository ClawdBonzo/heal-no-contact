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
    @Environment(GameificationService.self) private var game
    @State private var showSaveFlash = false
    @State private var showDiscardDialog = false
    @FocusState private var bodyFocused: Bool

    private var isEditing: Bool { existingEntry != nil }
    private var profile: UserProfile? { profiles.first }

    /// True when closing now would throw away something the user typed.
    private var hasUnsavedChanges: Bool {
        if let entry = existingEntry {
            return title != entry.title || body_ != entry.body
                || selectedMood != entry.mood || isFavorite != entry.isFavorite
        }
        return !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || !body_.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private let prompts = [
        String(localized: "What's on your mind right now?"),
        String(localized: "What triggered you today and how did you handle it?"),
        String(localized: "Write about something you're grateful for."),
        String(localized: "What would you say to yourself 6 months from now?"),
        String(localized: "Describe a small win from today."),
        String(localized: "What's one thing you learned about yourself recently?"),
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
                                            Text(mood.localizedName)
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
                            .focused($bodyFocused)
                    }
                }
                    .padding(20)
                }
                .scrollDismissesKeyboard(.interactively)
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
            // A half-written entry must never vanish on an accidental swipe-down.
            .interactiveDismissDisabled(hasUnsavedChanges)
            .confirmationDialog("Discard this entry?", isPresented: $showDiscardDialog, titleVisibility: .visible) {
                Button("Discard", role: .destructive) { dismiss() }
                Button("Keep Editing", role: .cancel) {}
            } message: {
                Text("Your writing hasn't been saved.")
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        if hasUnsavedChanges { showDiscardDialog = true } else { dismiss() }
                    }
                    .foregroundStyle(Color.theme.textSecondary)
                }

                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { bodyFocused = false }
                        .fontWeight(.semibold)
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

            // Award XP for new journal entry (quests progress on their own)
            game.addXP(15, reason: String(localized: "Journal entry"))
            game.progressQuests(ofKind: .journal)
            let count = (try? modelContext.fetchCount(FetchDescriptor<JournalEntry>())) ?? 0
            game.checkMilestoneBadges(streakDays: profile?.currentStreakDays ?? 0,
                                      journalEntryCount: count + 1,
                                      moodCheckInCount: 0)
        }

        HapticService.notification(.success)
        // Brief golden flash before dismiss
        withAnimation(.easeOut(duration: 0.2)) { showSaveFlash = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { dismiss() }
    }
}

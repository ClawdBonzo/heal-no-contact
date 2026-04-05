import SwiftUI
import SwiftData

struct JournalListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \JournalEntry.createdAt, order: .reverse) private var entries: [JournalEntry]
    @State private var showEditor = false
    @State private var showLetterWriter = false
    @State private var selectedEntry: JournalEntry?
    @State private var searchText = ""
    @State private var filterMood: JournalEntry.MoodType?

    private var filteredEntries: [JournalEntry] {
        entries.filter { entry in
            let matchesSearch = searchText.isEmpty ||
                entry.title.localizedCaseInsensitiveContains(searchText) ||
                entry.body.localizedCaseInsensitiveContains(searchText)
            let matchesMood = filterMood == nil || entry.mood == filterMood
            return matchesSearch && matchesMood
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.theme.deepBackground.ignoresSafeArea()

                if entries.isEmpty {
                    EmptyJournalView(
                        onWrite: { showEditor = true },
                        onLetter: { showLetterWriter = true }
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            // Mood filter chips
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    FilterChip(
                                        label: "All",
                                        isSelected: filterMood == nil,
                                        action: { filterMood = nil }
                                    )
                                    ForEach(JournalEntry.MoodType.allCases) { mood in
                                        FilterChip(
                                            label: "\(mood.emoji) \(mood.rawValue)",
                                            isSelected: filterMood == mood,
                                            action: { filterMood = mood }
                                        )
                                    }
                                }
                                .padding(.horizontal, 20)
                            }

                            ForEach(filteredEntries) { entry in
                                JournalRowView(entry: entry)
                                    .onTapGesture {
                                        selectedEntry = entry
                                        showEditor = true
                                    }
                                    .contextMenu {
                                        Button {
                                            entry.isFavorite.toggle()
                                        } label: {
                                            Label(
                                                entry.isFavorite ? "Unfavorite" : "Favorite",
                                                systemImage: entry.isFavorite
                                                    ? "heart.slash" : "heart"
                                            )
                                        }

                                        Button(role: .destructive) {
                                            modelContext.delete(entry)
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                            }
                        }
                        .padding(.bottom, 100)
                    }
                    .searchable(text: $searchText, prompt: "Search entries...")
                }
            }
            .navigationTitle("Journal")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button {
                            selectedEntry = nil
                            showEditor = true
                        } label: {
                            Label("New Entry", systemImage: "square.and.pencil")
                        }

                        Button {
                            showLetterWriter = true
                        } label: {
                            Label("Unsent Letter", systemImage: "envelope.fill")
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(Color.theme.healPurple)
                    }
                }
            }
            .sheet(isPresented: $showEditor) {
                JournalEditorView(existingEntry: selectedEntry)
            }
            .sheet(isPresented: $showLetterWriter) {
                UnsentLetterView()
            }
        }
    }
}

private struct JournalRowView: View {
    let entry: JournalEntry

    var body: some View {
        HStack(spacing: 14) {
            Text(entry.mood.emoji)
                .font(.title2)
                .frame(width: 44, height: 44)
                .background(
                    Color.theme.moodColor(entry.mood).opacity(0.15)
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(entry.title.isEmpty ? "Untitled" : entry.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.theme.textPrimary)
                        .lineLimit(1)

                    if entry.isFavorite {
                        Image(systemName: "heart.fill")
                            .font(.caption2)
                            .foregroundStyle(Color.theme.healPink)
                    }
                }

                Text(entry.body)
                    .font(.caption)
                    .foregroundStyle(Color.theme.textSecondary)
                    .lineLimit(2)
            }

            Spacer()

            Text(entry.createdAt.relativeFormatted)
                .font(.caption2)
                .foregroundStyle(Color.theme.textTertiary)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.theme.cardBackground)
        )
        .padding(.horizontal, 20)
    }
}

private struct FilterChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: {
            action()
            HapticService.selection()
        }) {
            Text(label)
                .font(.caption.weight(.medium))
                .foregroundStyle(
                    isSelected ? .white : Color.theme.textSecondary
                )
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    isSelected
                    ? AnyShapeStyle(Color.theme.healPurple)
                    : AnyShapeStyle(Color.theme.cardBackground)
                )
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

private struct EmptyJournalView: View {
    let onWrite: () -> Void
    let onLetter: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "book.closed.fill")
                .font(.system(size: 56))
                .foregroundStyle(Color.theme.healPurple.opacity(0.5))

            VStack(spacing: 8) {
                Text("Your journal is empty")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Color.theme.textPrimary)

                Text("Writing helps process emotions and track your healing. Start with whatever's on your mind.")
                    .font(.subheadline)
                    .foregroundStyle(Color.theme.textSecondary)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 12) {
                Button(action: onWrite) {
                    Label("Write an Entry", systemImage: "square.and.pencil")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.theme.gradientPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                Button(action: onLetter) {
                    Label("Write an Unsent Letter", systemImage: "envelope")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color.theme.healPurple)
                }
            }
        }
        .padding(40)
    }
}

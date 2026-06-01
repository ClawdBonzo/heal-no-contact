import SwiftUI
import SwiftData
import UIKit

struct SettingsView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @Query(sort: \JournalEntry.createdAt, order: .reverse) private var journals: [JournalEntry]
    @State private var showResetAlert = false
    @State private var showDeleteAlert = false
    @State private var pdfURL: URL?
    @State private var showPDFShare = false

    private var profile: UserProfile? { profiles.first }

    var body: some View {
        NavigationStack {
            List {
                // Premium section
                if !appState.isPremium {
                    Section {
                        Button {
                            appState.showPaywall = true
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

                // Premium tools
                Section("Tools") {
                    Button {
                        exportPDF()
                    } label: {
                        HStack {
                            Label("Export Journal as PDF", systemImage: "doc.richtext.fill")
                                .foregroundStyle(Color.theme.textPrimary)
                            Spacer()
                            if !appState.isPremium {
                                Image(systemName: "lock.fill")
                                    .font(.caption)
                                    .foregroundStyle(Color.theme.healGold)
                            }
                        }
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
            .sheet(isPresented: $showPDFShare) {
                if let pdfURL {
                    JournalPDFShareSheet(items: [pdfURL])
                }
            }
        }
    }

    private func exportPDF() {
        guard appState.isPremium else {
            appState.showPaywall = true
            return
        }
        if let url = JournalPDF.make(profile: profile, journals: journals) {
            pdfURL = url
            showPDFShare = true
            HapticService.notification(.success)
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

// MARK: - Premium: Journal PDF export

private enum JournalPDF {
    static func make(profile: UserProfile?, journals: [JournalEntry]) -> URL? {
        let df = DateFormatter()
        df.dateStyle = .long

        func esc(_ s: String) -> String {
            s.replacingOccurrences(of: "&", with: "&amp;")
             .replacingOccurrences(of: "<", with: "&lt;")
             .replacingOccurrences(of: ">", with: "&gt;")
             .replacingOccurrences(of: "\n", with: "<br/>")
        }

        var summary = ""
        if let p = profile {
            summary = """
            <table class='sum'>
            <tr><td>No-contact since</td><td>\(esc(p.noContactStartDate.monthDay))</td></tr>
            <tr><td>Current streak</td><td>\(p.currentStreakDays) days</td></tr>
            <tr><td>Best streak</td><td>\(max(p.streakBestDays, p.currentStreakDays)) days</td></tr>
            <tr><td>Goal</td><td>\(p.noContactGoalDays) days</td></tr>
            </table>
            """
        }

        var entries = ""
        if journals.isEmpty {
            entries = "<p class='empty'>No journal entries yet.</p>"
        } else {
            for j in journals {
                let title = j.title.isEmpty ? "Untitled" : j.title
                entries += "<div class='entry'><div class='ed'>\(df.string(from: j.createdAt))</div>"
                entries += "<div class='et'>\(esc(title))</div><div class='eb'>\(esc(j.body))</div></div>"
            }
        }

        let html = """
        <html><head><meta charset='utf-8'><style>
        body{font-family:-apple-system,Helvetica,Arial;color:#1c1c1e;margin:0;}
        h1{font-size:26px;margin:0 0 4px;}
        .sub{color:#8e8e93;margin:0 0 18px;font-size:12px;}
        .sum{border-collapse:collapse;margin:0 0 22px;font-size:13px;}
        .sum td{padding:4px 14px 4px 0;}
        .sum td:first-child{color:#8e8e93;}
        h2{font-size:18px;border-bottom:1px solid #e5e5ea;padding-bottom:6px;margin:18px 0 12px;}
        .entry{margin:0 0 16px;}
        .ed{color:#8e8e93;font-size:11px;}
        .et{font-weight:600;font-size:14px;margin:2px 0;}
        .eb{font-size:12px;color:#3a3a3c;line-height:1.45;}
        .empty{color:#8e8e93;}
        </style></head><body>
        <h1>Heal — My Journey</h1>
        <p class='sub'>Exported \(df.string(from: .now))</p>
        \(summary)
        <h2>Journal Entries</h2>
        \(entries)
        </body></html>
        """

        let formatter = UIMarkupTextPrintFormatter(markupText: html)
        let renderer = UIPrintPageRenderer()
        renderer.addPrintFormatter(formatter, startingAtPageAt: 0)

        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792) // US Letter @72dpi
        let printable = pageRect.insetBy(dx: 40, dy: 48)
        renderer.setValue(pageRect, forKey: "paperRect")
        renderer.setValue(printable, forKey: "printableRect")

        let pageCount = max(renderer.numberOfPages, 1)
        let data = NSMutableData()
        UIGraphicsBeginPDFContextToData(data, pageRect, nil)
        renderer.prepare(forDrawingPages: NSRange(location: 0, length: pageCount))
        for i in 0..<pageCount {
            UIGraphicsBeginPDFPage()
            renderer.drawPage(at: i, in: UIGraphicsGetPDFContextBounds())
        }
        UIGraphicsEndPDFContext()

        let url = FileManager.default.temporaryDirectory.appendingPathComponent("Heal-Journal.pdf")
        do {
            try data.write(to: url)
            return url
        } catch {
            return nil
        }
    }
}

struct JournalPDFShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}

import SwiftUI

/// App-wide celebration layer: a "+N XP" toast, a badge-unlock toast, and the level-up
/// modal — shown wherever the XP was earned (check-in sheet, journal, SOS, dashboard).
struct GamificationOverlay: ViewModifier {
    @Environment(GameificationService.self) private var game
    @State private var toast: Toast?
    @State private var toastTask: Task<Void, Never>?
    @State private var levelUp: LevelUpAward?

    private struct Toast: Equatable {
        let icon: String
        let title: String
        let subtitle: String?
        let tint: Color
    }

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .top) {
                if let toast {
                    ToastView(icon: toast.icon, title: toast.title, subtitle: toast.subtitle, tint: toast.tint)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .padding(.top, 8)
                        .onTapGesture { dismissToast() }
                }
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: toast)
            .onChange(of: game.recentXPGain) { _, gain in
                guard let gain else { return }
                show(Toast(icon: "sparkles",
                           title: String(localized: "+\(gain.amount) XP"),
                           subtitle: gain.reason,
                           tint: Color.theme.healGold))
            }
            .onChange(of: game.recentBadge?.id) { _, _ in
                guard let badge = game.recentBadge else { return }
                show(Toast(icon: badge.icon,
                           title: String(localized: "Badge unlocked: \(badge.title)"),
                           subtitle: badge.details,
                           tint: Color.theme.healTeal), seconds: 3.5)
                game.recentBadge = nil
            }
            .onChange(of: game.levelUpAward) { _, award in
                if let award { levelUp = award }
            }
            .fullScreenCover(item: $levelUp) { award in
                LevelUpModalView(
                    oldLevel: award.oldLevel,
                    newLevel: award.newLevel,
                    levelName: game.userGamification?.levelName ?? ""
                ) {
                    levelUp = nil
                    game.levelUpAward = nil
                }
                .presentationBackground(.clear)
            }
    }

    private func show(_ t: Toast, seconds: Double = 2.2) {
        toastTask?.cancel()
        toast = t
        toastTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(seconds))
            if !Task.isCancelled { dismissToast() }
        }
    }

    private func dismissToast() {
        toast = nil
        game.recentXPGain = nil
    }
}

extension LevelUpAward: Identifiable {
    var id: String { "\(oldLevel)-\(newLevel)" }
}

extension View {
    func gamificationOverlay() -> some View { modifier(GamificationOverlay()) }
}

private struct ToastView: View {
    let icon: String
    let title: String
    let subtitle: String?
    let tint: Color

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(tint)
                .frame(width: 30, height: 30)
                .background(tint.opacity(0.15), in: Circle())
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.theme.textPrimary)
                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(Color.theme.textSecondary)
                        .lineLimit(1)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            Capsule()
                .fill(Color.theme.cardBackground)
                .overlay(Capsule().stroke(tint.opacity(0.35), lineWidth: 1))
                .shadow(color: .black.opacity(0.35), radius: 14, y: 6)
        )
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isStaticText)
    }
}

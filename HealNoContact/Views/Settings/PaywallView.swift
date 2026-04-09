import SwiftUI
import RevenueCat

// MARK: - Plan Model

enum HealPlanOption: String, CaseIterable, Identifiable {
    case weekly   = "com.clawdbonzo.healnocontact.weekly"
    case monthly  = "com.clawdbonzo.healnocontact.monthly"
    case yearly   = "com.clawdbonzo.healnocontact.yearly"
    case lifetime = "com.clawdbonzo.healnocontact.lifetime"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .weekly:   return "Weekly"
        case .monthly:  return "Monthly"
        case .yearly:   return "Yearly"
        case .lifetime: return "Lifetime"
        }
    }

    var fallbackPrice: String {
        switch self {
        case .weekly:   return "$4.99"
        case .monthly:  return "$9.99"
        case .yearly:   return "$49.99"
        case .lifetime: return "$79.99"
        }
    }

    var fallbackPerWeek: String {
        switch self {
        case .weekly:   return "$4.99/wk"
        case .monthly:  return "$2.50/wk"
        case .yearly:   return "$0.96/wk"
        case .lifetime: return "one-time"
        }
    }

    /// Plans that include a 3-day free trial
    var hasTrial: Bool {
        switch self {
        case .monthly, .yearly: return true
        case .weekly, .lifetime: return false
        }
    }

    var isBestValue: Bool { self == .monthly }

    var savingsLabel: String? {
        self == .yearly ? "Save 58%" : nil
    }

    var packageType: PackageType {
        switch self {
        case .weekly:   return .weekly
        case .monthly:  return .monthly
        case .yearly:   return .annual
        case .lifetime: return .lifetime
        }
    }
}

// MARK: - PaywallView

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var storeService = RevenueCatService.shared
    @State private var selectedPlan: HealPlanOption = .monthly
    @State private var isPurchasing = false
    @State private var showError = false
    @State private var errorMessage = ""

    // Staggered reveal
    @State private var showHeader = false
    @State private var showFeatures = false
    @State private var showPlans = false
    @State private var showCTA = false
    @State private var glowPulse = false

    var body: some View {
        ZStack {
            Color.theme.deepBackground.ignoresSafeArea()

            // Ambient glow blobs
            Circle()
                .fill(Color.theme.healPurple.opacity(0.09))
                .frame(width: 300)
                .blur(radius: 70)
                .offset(x: -90, y: -180)
                .scaleEffect(glowPulse ? 1.15 : 1.0)
                .animation(.easeInOut(duration: 4).repeatForever(autoreverses: true), value: glowPulse)

            Circle()
                .fill(Color.theme.healGold.opacity(0.06))
                .frame(width: 220)
                .blur(radius: 55)
                .offset(x: 110, y: 60)
                .scaleEffect(glowPulse ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 3.5).repeatForever(autoreverses: true), value: glowPulse)

            VStack(spacing: 0) {
                // ── Close button ──────────────────────────────────────────────
                HStack {
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(Color.theme.textTertiary)
                            .padding(10)
                            .background(Color(white: 0.14))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 2)

                // ── Compact header ────────────────────────────────────────────
                VStack(spacing: 5) {
                    Text("Heal Premium")
                        .font(.system(size: 32, weight: .black, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.theme.healGold, Color(red: 0.95, green: 0.55, blue: 0.85)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )

                    Text("Unlock everything. Support your healing.")
                        .font(.subheadline)
                        .foregroundStyle(Color.theme.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .opacity(showHeader ? 1 : 0)
                .offset(y: showHeader ? 0 : 16)
                .padding(.top, 8)
                .padding(.bottom, 16)

                // ── Features ──────────────────────────────────────────────────
                VStack(spacing: 9) {
                    HealFeatureRow(icon: "brain.head.profile.fill", text: "Advanced mood insights & pattern detection")
                    HealFeatureRow(icon: "widget.small.badge.plus",  text: "Home screen widgets & streak tracker")
                    HealFeatureRow(icon: "bell.badge.fill",          text: "AI-timed smart reminders")
                    HealFeatureRow(icon: "chart.xyaxis.line",        text: "Export journal & progress as PDF")
                }
                .padding(.horizontal, 22)
                .opacity(showFeatures ? 1 : 0)
                .offset(y: showFeatures ? 0 : 12)

                // ── Plan cards ────────────────────────────────────────────────
                VStack(spacing: 8) {
                    ForEach(HealPlanOption.allCases) { plan in
                        HealPlanCard(
                            plan: plan,
                            isSelected: selectedPlan == plan,
                            livePrice: livePrice(for: plan),
                            livePerWeek: livePerWeek(for: plan),
                            liveSavings: liveSavings(for: plan)
                        ) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedPlan = plan
                            }
                        }
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 14)
                .opacity(showPlans ? 1 : 0)
                .offset(y: showPlans ? 0 : 12)

                Spacer(minLength: 0)

                // ── CTA + legal ───────────────────────────────────────────────
                VStack(spacing: 10) {
                    Button {
                        Task { await purchase() }
                    } label: {
                        Group {
                            if isPurchasing {
                                ProgressView().tint(.white)
                            } else {
                                HStack(spacing: 8) {
                                    Text(ctaLabel)
                                        .font(.headline)
                                    Image(systemName: "arrow.right")
                                        .font(.subheadline.weight(.semibold))
                                }
                            }
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 17)
                        .background(
                            LinearGradient(
                                colors: [Color.theme.healPurple, Color.theme.healBlue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: Color.theme.healPurple.opacity(0.4), radius: 12, y: 4)
                    }
                    .disabled(isPurchasing)

                    HStack(spacing: 10) {
                        Button("Restore") {
                            Task {
                                do {
                                    try await storeService.restorePurchases()
                                    if storeService.isPremium { dismiss() }
                                } catch {
                                    errorMessage = error.localizedDescription
                                    showError = true
                                }
                            }
                        }
                        .font(.caption2)
                        .foregroundStyle(Color.theme.textTertiary)

                        Text("·").foregroundStyle(Color.theme.textTertiary).font(.caption2)

                        Link("Terms", destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
                            .font(.caption2).foregroundStyle(Color.theme.textTertiary)

                        Text("·").foregroundStyle(Color.theme.textTertiary).font(.caption2)

                        Link("Privacy", destination: URL(string: "https://www.apple.com/privacy/")!)
                            .font(.caption2).foregroundStyle(Color.theme.textTertiary)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 28)
                .opacity(showCTA ? 1 : 0)
                .offset(y: showCTA ? 0 : 8)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.05)) { showHeader = true }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.18)) { showFeatures = true }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.32)) { showPlans = true }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.46)) { showCTA = true }
            glowPulse = true
            if storeService.availablePackages.isEmpty {
                Task { await storeService.fetchOfferings() }
            }
        }
        .alert("Purchase Error", isPresented: $showError) {
            Button("OK") {}
        } message: {
            Text(errorMessage)
        }
    }

    // MARK: - Helpers

    private var ctaLabel: String {
        switch selectedPlan {
        case .monthly, .yearly: return "Start 3-Day Free Trial"
        case .weekly:           return "Get Weekly Access"
        case .lifetime:         return "Purchase Lifetime"
        }
    }

    private func package(for plan: HealPlanOption) -> Package? {
        storeService.availablePackages.first {
            $0.storeProduct.productIdentifier == plan.rawValue
        } ?? storeService.availablePackages.first {
            $0.packageType == plan.packageType
        }
    }

    private func livePrice(for plan: HealPlanOption) -> String {
        package(for: plan)?.localizedPriceString ?? plan.fallbackPrice
    }

    private func livePerWeek(for plan: HealPlanOption) -> String {
        guard let pkg = package(for: plan),
              let period = pkg.storeProduct.subscriptionPeriod else {
            return plan.fallbackPerWeek
        }
        let price = pkg.storeProduct.price as Decimal
        let weeks: Decimal
        switch period.unit {
        case .week:  weeks = Decimal(period.value)
        case .month: weeks = Decimal(period.value) * 4
        case .year:  weeks = Decimal(period.value) * 52
        default:     return plan.fallbackPerWeek
        }
        guard weeks > 0 else { return plan.fallbackPerWeek }
        let perWeek = NSDecimalNumber(decimal: price / weeks).doubleValue
        return "$\(String(format: "%.2f", perWeek))/wk"
    }

    /// Dynamically computes yearly savings vs monthly when live prices available.
    private func liveSavings(for plan: HealPlanOption) -> String? {
        guard plan == .yearly else { return nil }
        if let monthlyPkg = package(for: .monthly),
           let yearlyPkg = package(for: .yearly) {
            let monthlyAnnual = NSDecimalNumber(decimal: monthlyPkg.storeProduct.price as Decimal).doubleValue * 12
            let yearlyPrice   = NSDecimalNumber(decimal: yearlyPkg.storeProduct.price as Decimal).doubleValue
            guard monthlyAnnual > 0 else { return "Save 58%" }
            let pct = Int(((monthlyAnnual - yearlyPrice) / monthlyAnnual) * 100)
            return "Save \(pct)%"
        }
        return "Save 58%"
    }

    private func purchase() async {
        guard let pkg = package(for: selectedPlan) else {
            errorMessage = "This package is not available. Please try again later."
            showError = true
            return
        }
        isPurchasing = true
        defer { isPurchasing = false }
        do {
            let success = try await storeService.purchase(pkg)
            if success {
                HapticService.milestone()
                dismiss()
            }
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

// MARK: - HealFeatureRow

private struct HealFeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundStyle(Color.theme.healGold)
                .frame(width: 28, height: 28)
                .background(Color.theme.healGold.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            Text(text)
                .font(.subheadline)
                .foregroundStyle(Color.theme.textSecondary)

            Spacer()

            Image(systemName: "checkmark")
                .font(.caption2.weight(.bold))
                .foregroundStyle(Color.theme.healTeal)
        }
    }
}

// MARK: - HealPlanCard

private struct HealPlanCard: View {
    let plan: HealPlanOption
    let isSelected: Bool
    let livePrice: String
    let livePerWeek: String
    let liveSavings: String?
    let action: () -> Void

    private var borderColor: Color {
        if isSelected       { return Color.theme.healPurple }
        if plan.isBestValue { return Color.theme.healGold.opacity(0.55) }
        return Color(white: 0.20)
    }

    private var borderWidth: CGFloat {
        isSelected ? 2 : (plan.isBestValue ? 1.5 : 1)
    }

    private var cardBg: Color {
        if isSelected       { return Color.theme.healPurple.opacity(0.13) }
        if plan.isBestValue { return Color.theme.healGold.opacity(0.07) }
        return Color(white: 0.10)
    }

    var body: some View {
        Button(action: {
            action()
            HapticService.selection()
        }) {
            HStack(alignment: .center, spacing: 10) {
                // Left column
                VStack(alignment: .leading, spacing: 5) {
                    // Name row + badges
                    HStack(spacing: 6) {
                        Text(plan.displayName)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.theme.textPrimary)

                        if plan.isBestValue {
                            Text("BEST VALUE")
                                .font(.system(size: 8, weight: .black))
                                .foregroundStyle(Color.theme.deepBackground)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(Color.theme.healGold)
                                .clipShape(Capsule())
                        }

                        if let savings = liveSavings {
                            Text(savings)
                                .font(.system(size: 8, weight: .bold))
                                .foregroundStyle(Color.theme.healTeal)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(Color.theme.healTeal.opacity(0.15))
                                .clipShape(Capsule())
                        }
                    }

                    // Trial or per-week label
                    if plan.hasTrial {
                        HStack(spacing: 4) {
                            Image(systemName: "gift.fill")
                                .font(.system(size: 9))
                                .foregroundStyle(Color.theme.healGold)
                            Text("3-day free trial")
                                .font(.caption)
                                .foregroundStyle(Color.theme.healGold)
                        }
                    } else {
                        Text(livePerWeek)
                            .font(.caption)
                            .foregroundStyle(Color.theme.textTertiary)
                    }
                }

                Spacer()

                // Right column: price + per-week (when trial shown on left)
                VStack(alignment: .trailing, spacing: 2) {
                    Text(livePrice)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(isSelected ? Color.theme.healPurple : Color.theme.textPrimary)

                    if plan.hasTrial {
                        Text(livePerWeek)
                            .font(.caption2)
                            .foregroundStyle(Color.theme.textTertiary)
                    }
                }

                // Selection circle
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.body)
                    .foregroundStyle(isSelected ? Color.theme.healPurple : Color(white: 0.30))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(cardBg)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
        }
        .buttonStyle(.plain)
    }
}

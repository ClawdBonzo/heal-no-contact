import SwiftUI
import UserNotifications
import SwiftData
import RevenueCat

// MARK: - Plan Model

enum HealPlanOption: String, CaseIterable, Identifiable {
    case weekly   = "com.healnocontact.premium.weekly"
    case monthly  = "com.healnocontact.premium.monthly"
    case yearly   = "com.healnocontact.premium.yearly"
    case lifetime = "com.healnocontact.premium.lifetime"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .weekly:   return String(localized: "Weekly")
        case .monthly:  return String(localized: "Monthly")
        case .yearly:   return String(localized: "Yearly")
        case .lifetime: return String(localized: "Lifetime")
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

    /// Shown only while live store prices haven't loaded (USD estimates).
    var fallbackPerWeek: String {
        switch self {
        case .weekly:   return String(localized: "$4.99/wk")
        case .monthly:  return String(localized: "$2.30/wk")
        case .yearly:   return String(localized: "$0.96/wk")
        case .lifetime: return String(localized: "one-time")
        }
    }

    var isBestValue: Bool { self == .yearly }

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
    @Query private var profiles: [UserProfile]
    @State private var storeService = RevenueCatService.shared
    @State private var selectedPlan: HealPlanOption = .yearly
    @State private var isPurchasing = false
    @State private var isRestoring = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var restoreMessage: String?
    /// productIdentifier → still eligible for the intro offer (free trial). Missing = unknown/ineligible.
    @State private var trialEligibility: [String: Bool] = [:]
    /// iOS-level permission. The app's own `notificationsEnabled` flag stays true when the
    /// user later switches Heal off in iOS Settings, so the timeline must not rely on it alone.
    @State private var osNotificationsAllowed = false

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

            // Scrolls only when the content doesn't fit — iPhone SE and larger Dynamic Type.
            // On 6.1" and up, header, features and all four plans fit above the pinned block.
            GeometryReader { geo in
                ScrollView {
                    VStack(spacing: 0) {
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
                        .padding(.bottom, 12)

                        // ── Features ──────────────────────────────────────────────────
                        VStack(spacing: 7) {
                            HealFeatureRow(icon: "brain.head.profile.fill", text: String(localized: "Advanced insights & mood pattern detection"))
                            HealFeatureRow(icon: "doc.richtext.fill",        text: String(localized: "Export your journal & progress as a PDF"))
                            HealFeatureRow(icon: "bell.badge.fill",          text: String(localized: "Daily encouragement reminders"))
                            HealFeatureRow(icon: "heart.fill",               text: String(localized: "Support an independent developer"))
                        }
                        .padding(.horizontal, 22)
                        .opacity(showFeatures ? 1 : 0)
                        .offset(y: showFeatures ? 0 : 12)

                        // ── Plan cards ────────────────────────────────────────────────
                        VStack(spacing: 7) {
                            ForEach(HealPlanOption.allCases) { plan in
                                HealPlanCard(
                                    plan: plan,
                                    isSelected: selectedPlan == plan,
                                    livePrice: livePrice(for: plan),
                                    livePerWeek: livePerWeek(for: plan),
                                    liveSavings: liveSavings(for: plan),
                                    trialDays: eligibleTrialDays(for: plan)
                                ) {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        selectedPlan = plan
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 18)
                        .padding(.top, 12)
                        .opacity(showPlans ? 1 : 0)
                        .offset(y: showPlans ? 0 : 12)

                        Spacer(minLength: 0)

                    }
                    .padding(.top, 14)      // the overlaid close button sits beside the centred title, not above it
                    .padding(.bottom, 20)   // lets the last plan card scroll clear of the fade (review #2)
                    .frame(minHeight: geo.size.height, alignment: .top)
                }
                .scrollBounceBehavior(.basedOnSize)
            }
        }
        // Pinned: the purchase button and the auto-renew disclosure (Guideline 3.1.2) must be
        // visible on every device. Before 1.5 the paywall was one fixed-height stack, so any
        // extra content pushed them (and the close button) off screen on smaller phones.
        .safeAreaInset(edge: .bottom, spacing: 0) {
            // ── CTA + legal ───────────────────────────────────────────────
            VStack(spacing: 10) {
                // Trial timeline — pinned with the button it explains. Inside the scroll
                // area it sat below the fold on every phone, i.e. nobody would see it.
                // Every trial that has ever cancelled turned auto-renew off on the day it
                // started (Days Before Canceling 0): people cancel pre-emptively to avoid
                // being charged. Showing when the reminder comes and when the trial ends is
                // the standard answer to that fear.
                if let days = eligibleTrialDays(for: selectedPlan), days >= 2 {
                    TrialTimeline(days: days, remindersOn: (profiles.first?.notificationsEnabled ?? false) && osNotificationsAllowed)
                        .padding(.horizontal, 2)
                        .padding(.bottom, 2)
                        .transition(.opacity)
                }

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

                if let afterTrial = afterTrialLine {
                    Text(afterTrial)
                        .font(.caption)
                        .foregroundStyle(Color.theme.textSecondary)
                        .multilineTextAlignment(.center)
                }

                HStack(spacing: 10) {
                    Button {
                        Task { await restore() }
                    } label: {
                        if isRestoring {
                            ProgressView().controlSize(.mini).tint(Color.theme.textTertiary)
                        } else {
                            Text("Restore")
                        }
                    }
                    .disabled(isRestoring || isPurchasing)
                    .font(.caption2)
                    .foregroundStyle(Color.theme.textTertiary)

                    Text("·").foregroundStyle(Color.theme.textTertiary).font(.caption2)

                    Link("Terms", destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
                        .font(.caption2).foregroundStyle(Color.theme.textTertiary)

                    Text("·").foregroundStyle(Color.theme.textTertiary).font(.caption2)

                    Link("Privacy", destination: URL(string: "https://gwlabs.app/privacy")!)
                        .font(.caption2).foregroundStyle(Color.theme.textTertiary)
                }

                Text(disclosureText)
                    .font(.system(size: 9))
                    .foregroundStyle(Color.theme.textTertiary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 2)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 8)
            .opacity(showCTA ? 1 : 0)
            .offset(y: showCTA ? 0 : 8)
            .padding(.top, 10)
            // Without a cap the pinned block grows until the scroll area above it vanishes and
            // only the default plan can be bought (largest accessibility size on iPhone SE).
            .dynamicTypeSize(...DynamicTypeSize.accessibility2)
            .background(Color.theme.deepBackground)
            // Soft edge where scrolled plan cards pass under the pinned block.
            .background(alignment: .top) {
                LinearGradient(colors: [Color.theme.deepBackground.opacity(0), Color.theme.deepBackground],
                               startPoint: .top, endPoint: .bottom)
                    .frame(height: 20)
                    .offset(y: -20)
                    .allowsHitTesting(false)
            }
        }
        .overlay(alignment: .topTrailing) {
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
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.05)) { showHeader = true }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.18)) { showFeatures = true }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.32)) { showPlans = true }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.46)) { showCTA = true }
            glowPulse = true
        }
        .task {
            let status = await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
            osNotificationsAllowed = [.authorized, .provisional, .ephemeral].contains(status)
            #if DEBUG
            // Screenshot harness: show the state most users see (they allow notifications in
            // onboarding); a fresh simulator has never been asked.
            if DemoConfig.shared.demoTrialDays != nil { osNotificationsAllowed = true }
            #endif
            if storeService.availablePackages.isEmpty {
                await storeService.fetchOfferings()
            }
            await refreshTrialEligibility()
        }
        .onChange(of: storeService.availablePackages.count) { _, _ in
            Task { await refreshTrialEligibility() }
        }
        .alert("Purchase Error", isPresented: $showError) {
            Button("OK") {}
        } message: {
            Text(errorMessage)
        }
        .alert("Restore Purchases", isPresented: Binding(
            get: { restoreMessage != nil },
            set: { if !$0 { restoreMessage = nil } }
        )) {
            Button("OK") { restoreMessage = nil }
        } message: {
            Text(restoreMessage ?? "")
        }
    }

    // MARK: - Helpers

    /// True when at least one visible plan is currently offering the user a free trial.
    private var anyTrialShown: Bool {
        HealPlanOption.allCases.contains { eligibleTrialDays(for: $0) != nil }
    }

    private var ctaLabel: String {
        if let days = eligibleTrialDays(for: selectedPlan) {
            return String(localized: "Start \(days)-Day Free Trial")
        }
        switch selectedPlan {
        case .weekly:   return String(localized: "Get Weekly Access")
        case .monthly:  return String(localized: "Get Monthly Access")
        case .yearly:   return String(localized: "Get Yearly Access")
        case .lifetime: return String(localized: "Purchase Lifetime")
        }
    }

    #if DEBUG
    /// Capture-only storefront price (DemoConfig.demoPrices), formatted like StoreKit would.
    private func demoPrice(_ plan: HealPlanOption, perWeek: Bool = false) -> String? {
        guard let prices = DemoConfig.shared.demoPrices, let p = prices[plan],
              let code = DemoConfig.shared.demoCurrency else { return nil }
        let weeks: Decimal = switch plan { case .weekly: 1; case .monthly: 52 / 12; case .yearly: 52; case .lifetime: 1 }
        return (perWeek ? p / weeks : p).formatted(.currency(code: code))
    }
    #endif

    /// "Then $49.99/year" — the price the trial converts to, for the selected plan.
    private var afterTrialLine: String? {
        guard eligibleTrialDays(for: selectedPlan) != nil else { return nil }
        var price = package(for: selectedPlan)?.localizedPriceString
        #if DEBUG
        if price == nil { price = demoPrice(selectedPlan) }
        #endif
        guard let price else { return nil }
        switch selectedPlan {
        case .weekly:  return String(localized: "Then \(price)/week. Cancel anytime.")
        case .monthly: return String(localized: "Then \(price)/month. Cancel anytime.")
        case .yearly:  return String(localized: "Then \(price)/year. Cancel anytime.")
        case .lifetime: return nil
        }
    }

    private var disclosureText: String {
        var text = String(localized: "Subscriptions auto-renew at the price and period shown above unless cancelled at least 24 hours before the end of the current period. Payment is charged to your Apple Account; manage or cancel anytime in Settings. Lifetime is a one-time purchase.")
        if anyTrialShown {
            text += " " + String(localized: "Free trials convert to a paid subscription when the trial ends unless cancelled.")
        }
        return text
    }

    private func package(for plan: HealPlanOption) -> Package? {
        storeService.availablePackages.first {
            $0.storeProduct.productIdentifier == plan.rawValue
        } ?? storeService.availablePackages.first {
            $0.packageType == plan.packageType
        }
    }

    private func livePrice(for plan: HealPlanOption) -> String {
        #if DEBUG
        if package(for: plan) == nil, let demo = demoPrice(plan) { return demo }
        #endif
        return package(for: plan)?.localizedPriceString ?? plan.fallbackPrice
    }

    /// Per-week price in the storefront's own currency (RevenueCat formats with the product's locale).
    private func livePerWeek(for plan: HealPlanOption) -> String {
        #if DEBUG
        if package(for: plan) == nil, plan != .lifetime, let demo = demoPrice(plan, perWeek: true) {
            return String(localized: "\(demo)/wk")
        }
        #endif
        guard let pkg = package(for: plan) else { return plan.fallbackPerWeek }
        if plan == .lifetime { return String(localized: "one-time") }
        guard let perWeek = pkg.storeProduct.localizedPricePerWeek else { return plan.fallbackPerWeek }
        return String(localized: "\(perWeek)/wk")
    }

    /// Length in days of the free trial the user is *actually* eligible for on this plan, else nil.
    /// Reads the live introductory offer (not a hardcoded assumption) and RevenueCat's eligibility check,
    /// so a returning user who already used the trial is never told "Start Free Trial".
    private func eligibleTrialDays(for plan: HealPlanOption) -> Int? {
        #if DEBUG
        if let demo = DemoConfig.shared.demoTrialDays { return plan == .lifetime ? nil : demo }
        #endif
        guard let pkg = package(for: plan),
              let intro = pkg.storeProduct.introductoryDiscount,
              intro.paymentMode == .freeTrial,
              trialEligibility[pkg.storeProduct.productIdentifier] == true else { return nil }
        let period = intro.subscriptionPeriod
        switch period.unit {
        case .day:   return period.value
        case .week:  return period.value * 7
        case .month: return period.value * 30
        case .year:  return period.value * 365
        @unknown default: return nil
        }
    }

    private func refreshTrialEligibility() async {
        let ids = storeService.availablePackages
            .filter { $0.storeProduct.introductoryDiscount?.paymentMode == .freeTrial }
            .map(\.storeProduct.productIdentifier)
        guard !ids.isEmpty else { return }
        let eligibility = await storeService.trialEligibility(for: ids)
        // Animated: eligibility often lands after the reveal, and the timeline, CTA label and
        // after-trial line would otherwise pop in.
        withAnimation(.easeOut(duration: 0.25)) { trialEligibility = eligibility }
    }

    private func restore() async {
        isRestoring = true
        defer { isRestoring = false }
        do {
            try await storeService.restorePurchases()
            if storeService.isPremium {
                activatePremiumReminders()
                HapticService.milestone()
                dismiss()
            } else {
                restoreMessage = String(localized: "No previous purchases were found for this Apple Account.")
            }
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    /// Premium includes daily encouragement reminders — turn them on the moment the entitlement lands.
    private func activatePremiumReminders() {
        let enabled = profiles.first?.notificationsEnabled ?? false
        NotificationService.shared.syncPremiumReminders(notificationsEnabled: enabled)
        // Schedule the trial-ending reminder now, not on the next foreground: a user who
        // starts a trial and doesn't reopen the app would otherwise never get the reminder
        // the timeline above promises.
        NotificationService.shared.refreshTrialEndingReminder(profile: profiles.first)
    }

    /// Dynamically computes yearly savings vs monthly when live prices available.
    private func liveSavings(for plan: HealPlanOption) -> String? {
        guard plan == .yearly else { return nil }
        if let monthlyPkg = package(for: .monthly),
           let yearlyPkg = package(for: .yearly) {
            let monthlyAnnual = NSDecimalNumber(decimal: monthlyPkg.storeProduct.price as Decimal).doubleValue * 12
            let yearlyPrice   = NSDecimalNumber(decimal: yearlyPkg.storeProduct.price as Decimal).doubleValue
            guard monthlyAnnual > 0 else { return String(localized: "Save 58%") }
            let pct = Int(((monthlyAnnual - yearlyPrice) / monthlyAnnual) * 100)
            return String(localized: "Save \(pct)%")
        }
        #if DEBUG
        if let p = DemoConfig.shared.demoPrices, let m = p[.monthly], let y = p[.yearly], m > 0 {
            // Same Double arithmetic as the live path above (NSDecimalNumber.intValue returns 0
            // for these long-mantissa Decimals).
            let monthlyAnnual = NSDecimalNumber(decimal: m).doubleValue * 12
            let pct = Int(((monthlyAnnual - NSDecimalNumber(decimal: y).doubleValue) / monthlyAnnual) * 100)
            return String(localized: "Save \(pct)%")
        }
        #endif
        return String(localized: "Save 58%")
    }

    private func purchase() async {
        guard let pkg = package(for: selectedPlan) else {
            errorMessage = String(localized: "This plan isn't available right now. Please check your connection and try again.")
            showError = true
            return
        }
        isPurchasing = true
        defer { isPurchasing = false }
        do {
            let success = try await storeService.purchase(pkg)
            if success {
                activatePremiumReminders()
                HapticService.milestone()
                dismiss()
            }
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

// MARK: - TrialTimeline

/// Today → reminder → trial ends. The reminder step is only claimed when notifications
/// are on; otherwise it says "Cancel anytime" rather than promise something that won't fire.
private struct TrialTimeline: View {
    let days: Int
    let remindersOn: Bool

    private var steps: [(icon: String, title: String, caption: String, tint: Color)] {
        [("lock.open.fill", String(localized: "Today"), String(localized: "Full access"), Color.theme.healGold),
         (remindersOn ? "bell.fill" : "xmark.circle.fill", String(localized: "Day \(days - 1)"),
          remindersOn ? String(localized: "Reminder") : String(localized: "Cancel anytime"), Color.theme.healTeal),
         ("calendar", String(localized: "Day \(days)"), String(localized: "Trial ends"), Color.theme.healPurple)]
    }

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            ForEach(steps.indices, id: \.self) { i in
                step(steps[i])
            }
        }
        // One line from the first icon's centre to the last's: each column is a third of the
        // width, so the icon centres sit at 1/6 and 5/6 — the line spans the middle 2/3.
        .background(alignment: .top) {
            GeometryReader { g in
                Rectangle()
                    .fill(Color.theme.textTertiary.opacity(0.35))
                    .frame(width: g.size.width * 2 / 3, height: 1)
                    .position(x: g.size.width / 2, y: 10)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(String(localized: "How your free trial works") + ": "
            + steps.map { "\($0.title), \($0.caption)" }.joined(separator: "; "))
    }

    private func step(_ s: (icon: String, title: String, caption: String, tint: Color)) -> some View {
        VStack(spacing: 3) {
            Image(systemName: s.icon)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(s.tint)
                .frame(width: 20, height: 20)
                // Opaque disc under the tint so the connector line doesn't show through.
                .background(Circle().fill(s.tint.opacity(0.15)).background(Circle().fill(Color.theme.deepBackground)))
            Text(s.title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(Color.theme.textPrimary)
            Text(s.caption)
                .font(.caption2)
                .foregroundStyle(Color.theme.textSecondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - HealFeatureRow

private struct HealFeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundStyle(Color.theme.healGold)
                .frame(width: 24, height: 24)
                .background(Color.theme.healGold.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8))


            Text(text)
                .font(.subheadline)
                .foregroundStyle(Color.theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 8)

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
    /// Free-trial length the user is eligible for on this plan (nil = no trial to advertise).
    let trialDays: Int?
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
                    if let trialDays {
                        HStack(spacing: 4) {
                            Image(systemName: "gift.fill")
                                .font(.system(size: 9))
                                .foregroundStyle(Color.theme.healGold)
                            Text("\(trialDays)-day free trial")
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

                    if trialDays != nil {
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
            .padding(.vertical, 11)
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

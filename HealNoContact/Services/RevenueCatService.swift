import Foundation
import RevenueCat
import Observation

@Observable
@MainActor
final class RevenueCatService: NSObject {
    static let shared = RevenueCatService()

    // RevenueCat SDK key. Debug builds use the test key; Release builds MUST use a production
    // `appl_…` key. Replace the Release placeholder below with the Public app SDK key from
    // RevenueCat Dashboard → Apps → [Your App] → API Keys before archiving for the App Store.
    // Runtime guard (below in configure) will crash Release builds that still have the placeholder.
    private static var apiKey: String {
        #if DEBUG
        return "test_AFpuFmRxwiYCSJV0rgzxFqKjZDa"
        #else
        return "appl_CUdvixEmGuhoIAjaPziSxjXgSAE"
        #endif
    }

    // Entitlement identifier configured in RevenueCat dashboard
    static let premiumEntitlement = "pro"

    // Product identifiers — must match App Store Connect
    static let premiumWeekly   = "com.healnocontact.premium.weekly"
    static let premiumMonthly  = "com.healnocontact.premium.monthly"
    static let premiumYearly   = "com.healnocontact.premium.yearly"
    static let premiumLifetime = "com.healnocontact.premium.lifetime"

    private(set) var customerInfo: CustomerInfo?
    private(set) var offerings: Offerings?
    private(set) var isLoading = false

    var isPremium: Bool {
        customerInfo?.entitlements[Self.premiumEntitlement]?.isActive == true
    }

    /// True while the user is inside a free trial (entitlement active, period type intro/trial).
    var isInTrial: Bool {
        guard let e = customerInfo?.entitlements[Self.premiumEntitlement], e.isActive else { return false }
        return e.periodType == .trial || e.periodType == .intro
    }

    /// When the current trial/subscription lapses, if known.
    var currentExpiration: Date? {
        customerInfo?.entitlements[Self.premiumEntitlement]?.expirationDate
    }

    var currentOffering: Offering? {
        offerings?.current
    }

    var availablePackages: [Package] {
        currentOffering?.availablePackages ?? []
    }

    private override init() {
        super.init()
    }

    /// Call once at app launch from HealNoContactApp
    func configure() {
        #if !DEBUG
        precondition(
            Self.apiKey.hasPrefix("appl_"),
            "RevenueCat: Release build requires a production 'appl_…' key. Replace the placeholder in RevenueCatService.swift."
        )
        #endif
        Purchases.logLevel = .warn
        Purchases.configure(withAPIKey: Self.apiKey)
        Purchases.shared.delegate = self

        Task {
            await fetchCustomerInfo()
            await fetchOfferings()
        }
    }

    func fetchOfferings() async {
        isLoading = true
        do {
            offerings = try await Purchases.shared.offerings()
        } catch {
            Log.purchases.error("Failed to fetch offerings: \(error.localizedDescription)")
        }
        isLoading = false
    }

    func fetchCustomerInfo() async {
        do {
            customerInfo = try await Purchases.shared.customerInfo()
        } catch {
            Log.purchases.error("Failed to fetch customer info: \(error.localizedDescription)")
        }
    }

    func purchase(_ package: Package) async throws -> Bool {
        let result = try await Purchases.shared.purchase(package: package)
        customerInfo = result.customerInfo

        // Returns true if user now has premium access
        return !result.userCancelled && isPremium
    }

    func restorePurchases() async throws {
        customerInfo = try await Purchases.shared.restorePurchases()
    }

    /// Whether this Apple ID is still eligible for each product's introductory offer (free trial).
    /// A user who already consumed the subscription group's trial gets `false` and must not be
    /// shown "Start Free Trial" — StoreKit would charge them immediately.
    func trialEligibility(for productIdentifiers: [String]) async -> [String: Bool] {
        guard !productIdentifiers.isEmpty else { return [:] }
        let result = await Purchases.shared.checkTrialOrIntroDiscountEligibility(productIdentifiers: productIdentifiers)
        return result.mapValues { $0.status == .eligible }
    }
}

// MARK: - PurchasesDelegate

extension RevenueCatService: PurchasesDelegate {
    nonisolated func purchases(
        _ purchases: Purchases,
        receivedUpdated customerInfo: CustomerInfo
    ) {
        Task { @MainActor in
            self.customerInfo = customerInfo
        }
    }
}

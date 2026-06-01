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
            print("[RevenueCat] Failed to fetch offerings: \(error.localizedDescription)")
        }
        isLoading = false
    }

    func fetchCustomerInfo() async {
        do {
            customerInfo = try await Purchases.shared.customerInfo()
        } catch {
            print("[RevenueCat] Failed to fetch customer info: \(error.localizedDescription)")
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

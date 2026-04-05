import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var storeService = StoreKitService.shared
    @State private var selectedProduct: Product?
    @State private var isPurchasing = false
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 52))
                            .foregroundStyle(Color.theme.healGold)
                            .symbolEffect(.bounce, options: .repeating.speed(0.3))

                        Text("Heal Premium")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.theme.textPrimary)

                        Text("Unlock everything. Support independent development.")
                            .font(.subheadline)
                            .foregroundStyle(Color.theme.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)

                    // Features
                    VStack(spacing: 14) {
                        PremiumFeatureRow(icon: "brain.head.profile.fill", title: "Advanced Insights", description: "Deep mood analytics & pattern detection")
                        PremiumFeatureRow(icon: "widget.small.badge.plus", title: "Home Screen Widgets", description: "Streak counter & daily mantra widgets")
                        PremiumFeatureRow(icon: "paintpalette.fill", title: "Custom Themes", description: "Personalize your healing space")
                        PremiumFeatureRow(icon: "bell.badge.fill", title: "Smart Reminders", description: "AI-timed notifications based on your patterns")
                        PremiumFeatureRow(icon: "chart.xyaxis.line", title: "Export Data", description: "Export your journal & progress as PDF")
                        PremiumFeatureRow(icon: "heart.fill", title: "Support Development", description: "Help us keep building for people who need it")
                    }
                    .padding(.horizontal, 24)

                    // Product options
                    if storeService.isLoading {
                        ProgressView()
                            .tint(Color.theme.healPurple)
                            .padding()
                    } else if storeService.products.isEmpty {
                        // Fallback display when products haven't loaded
                        VStack(spacing: 12) {
                            PricingCard(
                                title: "Monthly",
                                price: "$4.99/mo",
                                subtitle: "Cancel anytime",
                                isPopular: false,
                                isSelected: false,
                                action: {}
                            )
                            PricingCard(
                                title: "Yearly",
                                price: "$29.99/yr",
                                subtitle: "Save 50%",
                                isPopular: true,
                                isSelected: false,
                                action: {}
                            )
                            PricingCard(
                                title: "Lifetime",
                                price: "$49.99",
                                subtitle: "One-time purchase",
                                isPopular: false,
                                isSelected: false,
                                action: {}
                            )
                        }
                        .padding(.horizontal, 24)
                    } else {
                        VStack(spacing: 12) {
                            ForEach(storeService.products) { product in
                                PricingCard(
                                    title: product.displayName,
                                    price: product.displayPrice,
                                    subtitle: product.description,
                                    isPopular: product.id == StoreKitService.premiumYearly,
                                    isSelected: selectedProduct?.id == product.id,
                                    action: { selectedProduct = product }
                                )
                            }
                        }
                        .padding(.horizontal, 24)
                    }

                    // Purchase button
                    Button {
                        Task { await purchase() }
                    } label: {
                        Group {
                            if isPurchasing {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Continue")
                                    .font(.headline)
                            }
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            selectedProduct != nil
                            ? AnyShapeStyle(Color.theme.gradientPrimary)
                            : AnyShapeStyle(Color.theme.textTertiary)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .disabled(selectedProduct == nil || isPurchasing)
                    .padding(.horizontal, 32)

                    // Restore
                    Button {
                        Task { await storeService.restorePurchases() }
                    } label: {
                        Text("Restore Purchases")
                            .font(.subheadline)
                            .foregroundStyle(Color.theme.textSecondary)
                    }

                    // Legal
                    Text("Payment is charged to your Apple ID account. Subscriptions auto-renew unless cancelled at least 24 hours before the end of the current period.")
                        .font(.caption2)
                        .foregroundStyle(Color.theme.textTertiary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)

                    Spacer().frame(height: 20)
                }
            }
            .background(Color.theme.deepBackground)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Color.theme.textTertiary)
                    }
                }
            }
            .alert("Purchase Error", isPresented: $showError) {
                Button("OK") {}
            } message: {
                Text(errorMessage)
            }
        }
    }

    private func purchase() async {
        guard let product = selectedProduct else { return }
        isPurchasing = true
        defer { isPurchasing = false }

        do {
            if let _ = try await storeService.purchase(product) {
                HapticService.milestone()
                dismiss()
            }
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

// MARK: - Sub-components

private struct PremiumFeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(Color.theme.healGold)
                .frame(width: 36, height: 36)
                .background(Color.theme.healGold.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.theme.textPrimary)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(Color.theme.textSecondary)
            }

            Spacer()

            Image(systemName: "checkmark")
                .font(.caption.weight(.bold))
                .foregroundStyle(Color.theme.healGold)
        }
    }
}

private struct PricingCard: View {
    let title: String
    let price: String
    let subtitle: String
    let isPopular: Bool
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: {
            action()
            HapticService.selection()
        }) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.theme.textPrimary)

                        if isPopular {
                            Text("BEST VALUE")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.theme.healGold)
                                .clipShape(Capsule())
                        }
                    }

                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(Color.theme.textTertiary)
                }

                Spacer()

                Text(price)
                    .font(.headline)
                    .foregroundStyle(Color.theme.textPrimary)
            }
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.theme.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(
                                isSelected
                                ? Color.theme.healPurple
                                : isPopular
                                    ? Color.theme.healGold.opacity(0.3)
                                    : Color.clear,
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

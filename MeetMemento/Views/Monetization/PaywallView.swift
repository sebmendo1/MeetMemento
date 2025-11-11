//
//  PaywallView.swift
//  MeetMemento
//
//  Full-screen paywall for premium subscription
//

import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(\.theme) private var theme
    @Environment(\.typography) private var type
    @Environment(\.dismiss) private var dismiss

    @StateObject private var subscriptionService = SubscriptionService.shared
    @EnvironmentObject var subscriptionManager: SubscriptionManager

    let isDismissible: Bool
    let onPurchaseComplete: (() -> Void)?

    @State private var selectedPeriod: SubscriptionPeriod = .annual // Default to best value
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isLoadingProducts = false

    init(isDismissible: Bool = true, onPurchaseComplete: (() -> Void)? = nil) {
        self.isDismissible = isDismissible
        self.onPurchaseComplete = onPurchaseComplete
    }

    var body: some View {
        ZStack {
            // Background - matching design (#EFEFEF)
            BaseColors.offWhite.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 32) {
                    // Header
                    headerSection

                    // Features
                    featuresSection

                    // Pricing Cards
                    pricingSection

                    // CTA Buttons
                    ctaSection

                    // Footer
                    footerSection
                }
                .padding(.horizontal, 24)
                .padding(.top, isDismissible ? 60 : 80)
                .padding(.bottom, 40)
            }

            // Close button (only if dismissible)
            if isDismissible {
                VStack {
                    HStack {
                        Spacer()
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 30))
                                .foregroundStyle(.gray.opacity(0.6))
                        }
                        .padding(.top, 16)
                        .padding(.trailing, 16)
                    }
                    Spacer()
                }
            }

            // Success overlay
            if subscriptionService.purchaseState == .success {
                successOverlay
            }
        }
        .alert("Purchase Failed", isPresented: $showError) {
            Button("OK", role: .cancel) {
                subscriptionService.resetPurchaseState()
            }
        } message: {
            Text(errorMessage)
        }
        .onChange(of: subscriptionService.purchaseState) { oldValue, newValue in
            handlePurchaseStateChange(newValue)
        }
        .task {
            // Ensure products are loaded when paywall appears
            if subscriptionService.monthlyProduct == nil || subscriptionService.annualProduct == nil {
                isLoadingProducts = true
                await subscriptionService.loadProducts()
                isLoadingProducts = false

                // Show the real StoreKit error if available
                if let error = subscriptionService.productLoadError {
                    errorMessage = "Failed to load subscriptions: \(error)\n\nℹ️ If testing in Simulator, ensure StoreKit Configuration is linked in Xcode scheme (Product → Scheme → Edit Scheme → Options)."
                    showError = true
                } else if subscriptionService.monthlyProduct == nil && subscriptionService.annualProduct == nil {
                    errorMessage = "No subscription products available. Please try again later or contact support if the issue persists."
                    showError = true
                }
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 0) {
            // Headline - matching design "Upgrade for unlimited journals"
            Text("Upgrade for unlimited journals")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(PrimaryScale.primary600)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
    }

    // MARK: - Features Section

    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Section header
            Text("Memento+ allows you to")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(PrimaryScale.primary600)
                .padding(.bottom, 24)

            // Feature list
            VStack(spacing: 0) {
                ForEach(Array(SubscriptionFeature.allCases.enumerated()), id: \.element.rawValue) { index, feature in
                    FeatureRow(
                        feature: feature,
                        showDivider: index < SubscriptionFeature.allCases.count - 1
                    )
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Pricing Section

    private var pricingSection: some View {
        Group {
            if isLoadingProducts {
                // Show loading indicator while products are being fetched
                HStack {
                    Spacer()
                    ProgressView()
                        .tint(PrimaryScale.primary600)
                    Spacer()
                }
                .frame(height: 120)
            } else {
                HStack(spacing: 12) {
                    // Monthly Card
                    if let monthlyProduct = subscriptionService.monthlyProduct {
                        PricingCard(
                            product: monthlyProduct,
                            period: .monthly,
                            isSelected: selectedPeriod == .monthly,
                            isRecommended: false
                        ) {
                            selectedPeriod = .monthly
                        }
                    }

                    // Annual Card
                    if let annualProduct = subscriptionService.annualProduct {
                        PricingCard(
                            product: annualProduct,
                            period: .annual,
                            isSelected: selectedPeriod == .annual,
                            isRecommended: false
                        ) {
                            selectedPeriod = .annual
                        }
                    }
                }
                .padding(.vertical, 8)
            }
        }
    }

    // MARK: - CTA Section

    private var ctaSection: some View {
        VStack(spacing: 16) {
            // Upgrade Plan Button
            Button {
                Task {
                    await handlePurchase()
                }
            } label: {
                HStack {
                    if subscriptionService.purchaseState.isProcessing {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Upgrade plan")
                            .font(.system(size: 18, weight: .semibold))
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(PrimaryScale.primary600)
                .foregroundStyle(.white)
                .cornerRadius(16)
            }
            .disabled(subscriptionService.purchaseState.isProcessing ||
                     (selectedPeriod == .monthly && subscriptionService.monthlyProduct == nil) ||
                     (selectedPeriod == .annual && subscriptionService.annualProduct == nil))
            .accessibilityLabel("Upgrade to Memento Plus")
            .accessibilityHint("Subscribe to \(selectedPeriod == .monthly ? "monthly" : "annual") plan for unlimited journal entries")
        }
    }

    // MARK: - Footer Section

    private var footerSection: some View {
        VStack(spacing: 12) {
            // Restore Purchases Button
            Button {
                Task {
                    await handleRestore()
                }
            } label: {
                Text("Restore Purchases")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(GrayScale.gray600)
            }
            .disabled(subscriptionService.purchaseState.isProcessing)
            .accessibilityLabel("Restore Purchases")
            .accessibilityHint("If you previously purchased a subscription, tap to restore it")

            // Legal links
            HStack(spacing: 16) {
                Button("Terms of Service") {
                    if let url = URL(string: "https://sebmendo1.github.io/MeetMemento/terms.html") {
                        UIApplication.shared.open(url)
                    }
                }
                .font(.system(size: 12))
                .foregroundStyle(GrayScale.gray500)

                Text("•")
                    .foregroundStyle(GrayScale.gray400)

                Button("Privacy Policy") {
                    if let url = URL(string: "https://sebmendo1.github.io/MeetMemento/privacy.html") {
                        UIApplication.shared.open(url)
                    }
                }
                .font(.system(size: 12))
                .foregroundStyle(GrayScale.gray500)
            }
        }
        .padding(.top, 16)
    }

    // MARK: - Success Overlay

    private var successOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.green)

                Text("Welcome to Premium!")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)

                Text("You now have unlimited access to all features")
                    .font(.system(size: 17))
                    .foregroundStyle(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            .padding(40)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(white: 0.15))
            )
            .padding(40)
        }
        .onAppear {
            // Auto-dismiss after showing success
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                onPurchaseComplete?()
                dismiss()
            }
        }
    }

    // MARK: - Actions

    private func handlePurchase() async {
        let product: Product?

        switch selectedPeriod {
        case .monthly:
            product = subscriptionService.monthlyProduct
        case .annual:
            product = subscriptionService.annualProduct
        }

        guard let product = product else {
            errorMessage = "Product not available. Please try again later."
            showError = true
            return
        }

        await subscriptionService.purchase(product)
    }

    private func handleRestore() async {
        await subscriptionService.restorePurchases()
    }

    private func handlePurchaseStateChange(_ state: PurchaseState) {
        switch state {
        case .failed(let message):
            errorMessage = message
            showError = true

        case .success:
            // Refresh subscription status
            Task {
                await subscriptionManager.refreshAfterPurchase()
            }

        case .restored:
            // Refresh and dismiss
            Task {
                await subscriptionManager.refreshAfterPurchase()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    onPurchaseComplete?()
                    dismiss()
                }
            }

        case .cancelled:
            // User cancelled - just reset state
            subscriptionService.resetPurchaseState()

        default:
            break
        }
    }
}

// MARK: - Preview

#Preview("Dismissible Paywall") {
    PaywallView(isDismissible: true)
        .environmentObject(SubscriptionManager())
        .useTheme()
        .useTypography()
}

#Preview("Non-Dismissible Paywall") {
    PaywallView(isDismissible: false)
        .environmentObject(SubscriptionManager())
        .useTheme()
        .useTypography()
}

// Note: Previews won't show pricing cards because StoreKit products
// aren't available in SwiftUI previews. To see the cards:
// 1. Run the app in Simulator with StoreKit configuration enabled
// 2. Or check the PricingCard.swift preview which has mock cards

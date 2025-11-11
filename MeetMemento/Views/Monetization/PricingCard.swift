//
//  PricingCard.swift
//  MeetMemento
//
//  Pricing card component for subscription selection
//

import SwiftUI
import StoreKit

struct PricingCard: View {
    @Environment(\.theme) private var theme

    let product: Product
    let period: SubscriptionPeriod
    let isSelected: Bool
    let isRecommended: Bool
    let onSelect: () -> Void

    var body: some View {
        Button {
            onSelect()
        } label: {
            VStack(spacing: 8) {
                // Period name
                Text(period.displayName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(GrayScale.gray800)

                // Price
                Text(product.displayPrice)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(GrayScale.gray900)

                // Frequency text
                Text(period == .monthly ? "per month" : "$3.33 per month")
                    .font(.system(size: 14))
                    .foregroundStyle(GrayScale.gray600)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(BaseColors.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(
                                isSelected ? PrimaryScale.primary600 : GrayScale.gray300,
                                lineWidth: isSelected ? 3 : 1
                            )
                    )
            )
            .overlay(alignment: .topTrailing) {
                // Checkmark badge - only show when selected
                if isSelected {
                    ZStack {
                        Circle()
                            .fill(PrimaryScale.primary600)
                            .frame(width: 44, height: 44)

                        Image(systemName: "checkmark")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    .offset(x: 8, y: -8)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(period.displayName) subscription, \(product.displayPrice) \(period == .monthly ? "per month" : "per year, equivalent to $3.33 per month")")
        .accessibilityHint(isSelected ? "Currently selected" : "Double tap to select this plan")
        .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : .isButton)
    }
}

// Helper for corner radius on specific corners
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - Preview

// Mock Product for previews (since we can't load real StoreKit products in previews)
private struct MockProduct {
    let id: String
    let displayPrice: String

    static let monthly = MockProduct(
        id: "12345678",
        displayPrice: "$4.99"
    )

    static let annual = MockProduct(
        id: "123456789",
        displayPrice: "$39.99"
    )
}

// Wrapper to convert mock to StoreKit Product interface
private struct MockStoreKitProduct {
    let mock: MockProduct

    var id: String { mock.id }
    var displayPrice: String { mock.displayPrice }
}

#Preview("Monthly - Unselected") {
    VStack(spacing: 20) {
        // Monthly card unselected
        PricingCardPreview(
            period: .monthly,
            price: "$4.99",
            isSelected: false,
            isRecommended: false
        )
    }
    .padding()
    .background(BaseColors.offWhite)
    .useTheme()
}

#Preview("Annual - Selected") {
    VStack(spacing: 20) {
        // Annual card selected
        PricingCardPreview(
            period: .annual,
            price: "$39.99",
            isSelected: true,
            isRecommended: false
        )
    }
    .padding()
    .background(BaseColors.offWhite)
    .useTheme()
}

#Preview("Side by Side") {
    VStack(spacing: 32) {
        Text("Pricing Cards Preview")
            .font(.system(size: 24, weight: .bold))
            .foregroundStyle(PrimaryScale.primary600)

        HStack(spacing: 12) {
            // Monthly
            PricingCardPreview(
                period: .monthly,
                price: "$4.99",
                isSelected: false,
                isRecommended: false
            )

            // Annual (selected)
            PricingCardPreview(
                period: .annual,
                price: "$39.99",
                isSelected: true,
                isRecommended: false
            )
        }
    }
    .padding(24)
    .background(BaseColors.offWhite)
    .useTheme()
}

// Preview-only component that doesn't require StoreKit Product
private struct PricingCardPreview: View {
    let period: SubscriptionPeriod
    let price: String
    let isSelected: Bool
    let isRecommended: Bool

    var body: some View {
        Button {
            // Preview only - no action
        } label: {
            VStack(spacing: 8) {
                // Period name
                Text(period.displayName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(GrayScale.gray800)

                // Price
                Text(price)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(GrayScale.gray900)

                // Frequency text
                Text(period == .monthly ? "per month" : "$3.33 per month")
                    .font(.system(size: 14))
                    .foregroundStyle(GrayScale.gray600)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(BaseColors.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(
                                isSelected ? PrimaryScale.primary600 : GrayScale.gray300,
                                lineWidth: isSelected ? 3 : 1
                            )
                    )
            )
            .overlay(alignment: .topTrailing) {
                // Checkmark badge - only show when selected
                if isSelected {
                    ZStack {
                        Circle()
                            .fill(PrimaryScale.primary600)
                            .frame(width: 44, height: 44)

                        Image(systemName: "checkmark")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    .offset(x: 8, y: -8)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

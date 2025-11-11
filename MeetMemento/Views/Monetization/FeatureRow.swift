//
//  FeatureRow.swift
//  MeetMemento
//
//  Feature row component for displaying premium features
//

import SwiftUI

struct FeatureRow: View {
    @Environment(\.theme) private var theme

    let feature: SubscriptionFeature
    let showDivider: Bool

    init(feature: SubscriptionFeature, showDivider: Bool = true) {
        self.feature = feature
        self.showDivider = showDivider
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                // Feature text
                Text(feature.title)
                    .font(.system(size: 17))
                    .foregroundStyle(GrayScale.gray700)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Checkmark
                Image(systemName: "checkmark")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(GrayScale.gray800)
            }
            .padding(.vertical, 16)

            // Divider
            if showDivider {
                Divider()
                    .background(GrayScale.gray300)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 12) {
        ForEach(SubscriptionFeature.allCases, id: \.rawValue) { feature in
            FeatureRow(feature: feature)
        }
    }
    .padding()
    .useTheme()
}

//
//  ThemesIdentifiedView.swift
//  MeetMemento
//
//  Onboarding view for selecting identified themes from user's journal entry
//

import SwiftUI

public struct ThemesIdentifiedView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.theme) private var theme
    @Environment(\.typography) private var type

    // Theme selection state
    @State private var themes: [String] = [
        "Work related stress",
        "Keeping an image",
        "Closing doors",
        "Reaching acceptance",
        "Choosing better",
        "Living your own life"
    ]
    @State private var selectedThemes: Set<String> = []
    @State private var isProcessing: Bool = false

    // Callback for when user completes this step
    public var onComplete: (([String]) -> Void)?

    public init(themes: [String]? = nil, onComplete: (([String]) -> Void)? = nil) {
        if let themes = themes {
            self._themes = State(initialValue: themes)
        }
        self.onComplete = onComplete
    }

    public var body: some View {
        ZStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    
                    // Header section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Here are some of the themes we've identified")
                            .font(type.h3)
                            .headerGradient()
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.top, 16)

                        Text("Choose the ones you'd like to explore so we can personalize your experience.")
                            .font(type.bodySmall)
                            .foregroundStyle(theme.mutedForeground)
                            .lineSpacing(4)
                    }
                    .padding(.horizontal, 24)

                    // Theme tags
                    VStack(spacing: 12) {
                        ForEach(themes, id: \.self) { theme in
                            OnboardingThemeTag(
                                theme,
                                isSelected: Binding(
                                    get: { selectedThemes.contains(theme) },
                                    set: { isSelected in
                                        if isSelected {
                                            selectedThemes.insert(theme)
                                        } else {
                                            selectedThemes.remove(theme)
                                        }
                                    }
                                )
                            )
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.horizontal, 16)

                    Spacer(minLength: 120)
                }
            }
            .background(theme.background.ignoresSafeArea())

            // FAB positioned at bottom-right
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    IconButton(systemImage: "chevron.right", size: 64) {
                        completeStep()
                    }
                    .padding(.trailing, 24)
                    .padding(.bottom, 32)
                    .opacity(canProceed ? 1.0 : 0.5)
                    .disabled(!canProceed)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(theme.foreground)
                }
            }
        }
    }

    // MARK: - Computed Properties

    private var canProceed: Bool {
        !isProcessing && !selectedThemes.isEmpty
    }

    // MARK: - Actions

    private func completeStep() {
        guard canProceed else { return }

        isProcessing = true

        // Haptic feedback
        UIImpactFeedbackGenerator(style: .light).impactOccurred()

        // Call completion handler with selected themes
        onComplete?(Array(selectedThemes))

        // Small delay for better UX
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isProcessing = false
        }
    }
}

// MARK: - Progress Indicator Component

private struct OnboardingProgressIndicator: View {
    let currentStep: Int
    let totalSteps: Int

    @Environment(\.theme) private var theme

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<totalSteps, id: \.self) { index in
                Capsule()
                    .fill(index < currentStep ? theme.primary : theme.primary.opacity(0.2))
                    .frame(width: 40, height: 8)
            }
        }
    }
}

#Preview("Light") {
    NavigationStack {
        ThemesIdentifiedView { selectedThemes in
            print("Selected themes: \(selectedThemes)")
        }
        .useTheme()
        .useTypography()
    }
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    NavigationStack {
        ThemesIdentifiedView { selectedThemes in
            print("Selected themes: \(selectedThemes)")
        }
        .useTheme()
        .useTypography()
    }
    .preferredColorScheme(.dark)
}

#Preview("Custom Themes") {
    NavigationStack {
        ThemesIdentifiedView(
            themes: [
                "Morning routine",
                "Career growth",
                "Relationships",
                "Self-care"
            ]
        ) { selectedThemes in
            print("Selected: \(selectedThemes)")
        }
        .useTheme()
        .useTypography()
    }
}

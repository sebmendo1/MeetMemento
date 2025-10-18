//
//  LearnAboutYourselfView.swift
//  MeetMemento
//
//  Onboarding view for collecting initial journal entry about user goals
//

import SwiftUI

public struct LearnAboutYourselfView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.theme) private var theme
    @Environment(\.typography) private var type
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var onboardingViewModel: OnboardingViewModel

    @State private var entryText: String = ""
    @State private var isProcessing: Bool = false
    @State private var showErrorAlert: Bool = false
    @FocusState private var isTextEditorFocused: Bool

    // Callback for when user completes this step
    public var onComplete: ((String) -> Void)?

    public init(onComplete: ((String) -> Void)? = nil) {
        self.onComplete = onComplete
    }

    public var body: some View {
        ZStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Spacer(minLength: 16)

                    // Header
                    VStack(alignment: .leading, spacing: 12) {
                        Text("What would you like to learn about yourself?")
                            .font(type.h3)
                            .headerGradient()
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)

                    // Journal entry section
                    VStack(alignment: .leading, spacing: 16) {
                        // Text editor - clean JournalPageView style
                        ZStack(alignment: .topLeading) {
                            if entryText.isEmpty {
                                Text("Example: I want to understand my emotional patterns when I'm stressed, or learn more about what motivates me at work...")
                                    .font(.system(size: 17))
                                    .lineSpacing(5)
                                    .foregroundStyle(theme.mutedForeground.opacity(0.5))
                                    .allowsHitTesting(false)
                            }

                            TextEditor(text: $entryText)
                                .font(.system(size: 17))
                                .lineSpacing(5)
                                .foregroundStyle(theme.foreground)
                                .focused($isTextEditorFocused)
                                .scrollContentBackground(.hidden)
                                .frame(minHeight: 300)
                        }
                    }
                    .padding(.horizontal, 16)

                    Spacer(minLength: 120)
                }
                .padding(.top, 8)
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
                    .padding(.trailing, 16)
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
        .onAppear {
            // Auto-focus the text editor for immediate input
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isTextEditorFocused = true
            }
        }
        .onChange(of: onboardingViewModel.errorMessage) { oldValue, newValue in
            if let error = newValue, isProcessing {
                // Reset processing state and show error
                isProcessing = false
                showErrorAlert = true
            }
        }
        .alert("Error", isPresented: $showErrorAlert) {
            Button("OK") {
                // Clear the error message
                onboardingViewModel.errorMessage = nil
            }
        } message: {
            Text(onboardingViewModel.errorMessage ?? "An error occurred. Please try again.")
        }
    }

    // MARK: - Computed Properties

    private var canProceed: Bool {
        !isProcessing && entryText.trimmingCharacters(in: .whitespacesAndNewlines).count >= 20
    }

    // MARK: - Actions

    private func completeStep() {
        guard canProceed else { return }

        isProcessing = true
        let trimmedText = entryText.trimmingCharacters(in: .whitespacesAndNewlines)

        // Haptic feedback
        UIImpactFeedbackGenerator(style: .light).impactOccurred()

        // Call completion handler with user's input
        // Keep isProcessing = true until navigation occurs
        onComplete?(trimmedText)
    }
}

#Preview("Light") {
    NavigationStack {
        LearnAboutYourselfView()
            .useTheme()
            .useTypography()
            .environmentObject(AuthViewModel())
            .environmentObject(OnboardingViewModel())
    }
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    NavigationStack {
        LearnAboutYourselfView()
            .useTheme()
            .useTypography()
            .environmentObject(AuthViewModel())
            .environmentObject(OnboardingViewModel())
    }
    .preferredColorScheme(.dark)
}

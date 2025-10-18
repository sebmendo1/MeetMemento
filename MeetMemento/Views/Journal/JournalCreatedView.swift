//
//  JournalCreatedView.swift
//  MeetMemento
//
//  Success screen shown after journal creation
//

import SwiftUI

public struct JournalCreatedView: View {
    @Environment(\.theme) private var theme
    @Environment(\.typography) private var type
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // Animation states
    @State private var showCircle = false
    @State private var showCheckmark = false
    @State private var showHeading = false
    @State private var showSubtitle = false
    @State private var showTipCard = false
    @State private var showCloseButton = false
    @State private var checkmarkRotation: Double = -10
    @State private var circleScale: CGFloat = 0.8
    @State private var breathingScale: CGFloat = 1.0

    public var onDismiss: (() -> Void)?

    public init(onDismiss: (() -> Void)? = nil) {
        self.onDismiss = onDismiss
    }

    public var body: some View {
        ZStack {
            // Background
            theme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                // Close button (top right)
                HStack {
                    Spacer()
                    Button(action: {
                        // Haptic feedback on dismiss
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                        onDismiss?()
                    }) {
                        ZStack {
                            Circle()
                                .fill(theme.card)
                                .frame(width: 40, height: 40)
                                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)

                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(theme.foreground)
                        }
                    }
                    .padding(.top, 16)
                    .padding(.trailing, 20)
                    .opacity(showCloseButton ? 1 : 0)
                    .scaleEffect(showCloseButton ? 1 : 0.8)
                }

                Spacer()

                // Success state content
                VStack(spacing: 24) {
                    // Success checkmark in circular background
                    ZStack {
                        // Circular background with bounce animation
                        if showCircle {
                            Circle()
                                .fill(PrimaryScale.primary50)
                                .frame(width: 96, height: 96)
                                .scaleEffect(circleScale * breathingScale)
                        }

                        // Checkmark with scale + rotation animation
                        if showCheckmark {
                            Image(systemName: "checkmark")
                                .font(.system(size: 40, weight: .bold))
                                .foregroundStyle(theme.primary)
                                .rotationEffect(.degrees(checkmarkRotation))
                                .transition(.scale.combined(with: .opacity))
                        }
                    }

                    // Success heading with slide up animation
                    if showHeading {
                        Text("Journal created")
                            .font(type.h2)
                            .foregroundStyle(theme.primary)
                            .padding(.top, 8)
                            .transition(.asymmetric(
                                insertion: .move(edge: .bottom).combined(with: .opacity),
                                removal: .opacity
                            ))
                    }

                    // Success subtitle with slide up animation
                    if showSubtitle {
                        Text("Keep answering to follow-ups and you'll get\nmore detailed insights about yourself.")
                            .font(type.body)
                            .foregroundStyle(theme.mutedForeground)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                            .padding(.top, 8)
                            .transition(.asymmetric(
                                insertion: .move(edge: .bottom).combined(with: .opacity),
                                removal: .opacity
                            ))
                    }
                }

                Spacer()

                // Tip of the day section (bottom) with slide up animation
                if showTipCard {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Tip of the day")
                            .font(type.h4)
                            .foregroundStyle(theme.primary)

                        Text("Let all your thoughts go as you journal, and you'll discover your true self.")
                            .font(type.body)
                            .foregroundStyle(theme.foreground)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(20)
                    .background(theme.card)
                    .cornerRadius(theme.radius.xl)
                    .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 2)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity),
                        removal: .opacity
                    ))
                }
            }
        }
        .onAppear {
            startAnimationSequence()
        }
    }

    // MARK: - Animation Choreography

    private func startAnimationSequence() {
        if reduceMotion {
            // Show everything immediately for reduced motion
            showCircle = true
            showCheckmark = true
            showHeading = true
            showSubtitle = true
            showTipCard = true
            showCloseButton = true
            circleScale = 1.0
            checkmarkRotation = 0
        } else {
            // Choreographed entrance animation sequence

            // 1. Circle bounces in (0.0s)
            showCircle = true
            withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
                circleScale = 1.0
            }

            // Start gentle breathing animation on circle
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                withAnimation(
                    .easeInOut(duration: 2.0)
                    .repeatForever(autoreverses: true)
                ) {
                    breathingScale = 1.05
                }
            }

            // 2. Checkmark pops in with rotation (0.3s)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                showCheckmark = true
                withAnimation(.spring(response: 0.5, dampingFraction: 0.65)) {
                    checkmarkRotation = 0
                }

                // Success haptic feedback
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
            }

            // 3. Heading slides up (0.6s)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.75)) {
                    showHeading = true
                }
            }

            // 4. Subtitle slides up (0.85s)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.85) {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.75)) {
                    showSubtitle = true
                }
            }

            // 5. Close button fades in (1.0s)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                withAnimation(.easeOut(duration: 0.4)) {
                    showCloseButton = true
                }
            }

            // 6. Tip card slides up from bottom (1.2s)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                withAnimation(.spring(response: 0.7, dampingFraction: 0.75)) {
                    showTipCard = true
                }

                // Subtle haptic feedback for tip card
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
            }
        }
    }
}

// MARK: - Previews

#Preview("Light") {
    JournalCreatedView {
        print("Dismissed")
    }
    .useTheme()
    .useTypography()
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    JournalCreatedView {
        print("Dismissed")
    }
    .useTheme()
    .useTypography()
    .preferredColorScheme(.dark)
}

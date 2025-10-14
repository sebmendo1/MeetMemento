//
//  SignInView.swift
//  MeetMemento
//
//  DEPRECATED: This view uses password authentication which has been removed.
//  Use SignInBottomSheet with OTP authentication instead.
//

import SwiftUI

public struct SignInView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.theme) private var theme
    @Environment(\.typography) private var type
    @EnvironmentObject var authViewModel: AuthViewModel

    @State private var status: String = ""

    public var onSignInSuccess: (() -> Void)?

    public init(onSignInSuccess: (() -> Void)? = nil) {
        self.onSignInSuccess = onSignInSuccess
    }
    
    public var body: some View {
        VStack(spacing: 24) {
            Spacer()

            VStack(spacing: 16) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 56))
                    .foregroundStyle(theme.mutedForeground)

                Text("View Deprecated")
                    .font(type.h2)
                    .foregroundStyle(theme.foreground)

                Text("This view has been deprecated. Password authentication has been removed. Please use SignInBottomSheet with OTP authentication instead.")
                    .font(type.body)
                    .foregroundStyle(theme.mutedForeground)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                if !status.isEmpty {
                    Text(status)
                        .font(type.bodySmall)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
            }

            Spacer()

            Button {
                dismiss()
            } label: {
                Text("Go Back")
                    .font(type.button)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(theme.primary)
                    .clipShape(RoundedRectangle(cornerRadius: theme.radius.lg))
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 32)
        }
        .background(theme.background.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview("Light") {
    NavigationStack {
        SignInView()
            .useTheme()
            .useTypography()
            .environmentObject(AuthViewModel())
    }
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    NavigationStack {
        SignInView()
            .useTheme()
            .useTypography()
            .environmentObject(AuthViewModel())
    }
    .preferredColorScheme(.dark)
}

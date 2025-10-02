//
//  AuthStatusViewModel.swift
//  MeetMemento
//
//  Minimal VM that listens to auth changes and exposes a status string / isSignedIn.
//

import Foundation
import SwiftUI

@MainActor
final class AuthStatusViewModel: ObservableObject {
    @Published var statusText: String = ""
    @Published var isSignedIn: Bool = false

    init() {
        AuthService.shared.observeAuthChanges { [weak self] event in
            guard let self else { return }
            switch event.uppercased() {
            case "SIGNED_IN":
                self.statusText = "Signed in"
                self.isSignedIn = true
            case "SIGNED_OUT":
                self.statusText = "Signed out"
                self.isSignedIn = false
            case "TOKEN_REFRESHED":
                self.statusText = "Session refreshed"
            case "USER_UPDATED":
                self.statusText = "User updated"
            default:
                self.statusText = event
            }
        }
    }
}

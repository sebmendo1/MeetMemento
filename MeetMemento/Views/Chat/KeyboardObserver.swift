//
//  KeyboardObserver.swift
//  MeetMemento
//
//  Created by Sebastian Mendo on 10/26/25.
//

import SwiftUI
import Combine

/// ViewModifier that observes keyboard show/hide notifications and updates a binding with the keyboard height
struct KeyboardObserver: ViewModifier {
    @Binding var keyboardHeight: CGFloat

    func body(content: Content) -> some View {
        content
            .onReceive(Publishers.keyboardHeight) { height in
                keyboardHeight = height
            }
    }
}

extension View {
    /// Observe keyboard height changes and bind to a CGFloat state variable
    func observeKeyboardHeight(_ keyboardHeight: Binding<CGFloat>) -> some View {
        modifier(KeyboardObserver(keyboardHeight: keyboardHeight))
    }
}

extension Publishers {
    /// Publisher that emits keyboard height when keyboard appears/disappears
    static var keyboardHeight: AnyPublisher<CGFloat, Never> {
        let willShow = NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
            .compactMap { notification -> CGFloat? in
                guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else {
                    return nil
                }
                return keyboardFrame.height
            }

        let willHide = NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
            .map { _ in CGFloat(0) }

        return Publishers.Merge(willShow, willHide)
            .eraseToAnyPublisher()
    }
}

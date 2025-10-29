//
//  BottomNavigation.swift
//  MeetMemento
//
//  Created by Sebastian Mendo on 12/15/24.
//

import SwiftUI

// MARK: - Bottom Navigation Component
/// A fixed bottom navigation component with FAB button
/// - Positioned at the bottom right with proper padding
/// - Handles journal entry creation and AI chat navigation
public struct BottomNavigation: View {

    // MARK: - Properties
    public let onJournalCreate: () -> Void
    public let onChatTapped: () -> Void

    @Environment(\.theme) private var theme
    @State private var isMenuExpanded: Bool = false

    // MARK: - Layout Constants
    private let horizontalPadding: CGFloat = 16
    private let bottomPadding: CGFloat = 32

    // MARK: - Initializer
    public init(
        onJournalCreate: @escaping () -> Void,
        onChatTapped: @escaping () -> Void
    ) {
        self.onJournalCreate = onJournalCreate
        self.onChatTapped = onChatTapped
    }

    // MARK: - Body
    public var body: some View {
        ZStack {
            // Background blur overlay when menu is expanded
            if isMenuExpanded {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .onTapGesture {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            isMenuExpanded = false
                        }
                    }
            }

            VStack {
                Spacer()

                HStack {
                    Spacer()

                    // Dynamic FAB with expandable menu
                    DynamicIconButton(
                        isExpanded: $isMenuExpanded,
                        onNewEntry: {
                            onJournalCreate()
                        },
                        onTalkWithJournal: {
                            onChatTapped()
                        }
                    )
                    .padding(.trailing, horizontalPadding)
                }
                .padding(.bottom, bottomPadding)
            }
        }
        .allowsHitTesting(true)
    }
}

// MARK: - Previews
#Preview("Bottom Navigation • Light") {
    ZStack {
        // Sample background content
        VStack(spacing: 20) {
            Text("Journal Entry 1")
                .padding()
                .background(Color.white)
                .cornerRadius(8)

            Text("Journal Entry 2")
                .padding()
                .background(Color.white)
                .cornerRadius(8)

            Text("Journal Entry 3")
                .padding()
                .background(Color.white)
                .cornerRadius(8)
        }

        BottomNavigation(
            onJournalCreate: {
                print("Create journal entry tapped")
            },
            onChatTapped: {
                print("Chat tapped")
            }
        )
    }
    .background(Color(hex: "#efefef"))
    .useTheme()
    .useTypography()
    .preferredColorScheme(.light)
}

#Preview("Bottom Navigation • Dark") {
    ZStack {
        // Sample background content
        VStack(spacing: 20) {
            Text("Journal Entry 1")
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(8)

            Text("Journal Entry 2")
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(8)

            Text("Journal Entry 3")
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(8)
        }

        BottomNavigation(
            onJournalCreate: {
                print("Create journal entry tapped")
            },
            onChatTapped: {
                print("Chat tapped")
            }
        )
    }
    .background(Color.black)
    .useTheme()
    .useTypography()
    .preferredColorScheme(.dark)
}

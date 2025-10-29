//
//  DynamicIconButton.swift
//  MeetMemento
//
//  Created by Sebastian Mendo on 10/24/25.
//

import SwiftUI

public struct DynamicIconButton: View {
    @Environment(\.theme) private var theme
    @Environment(\.typography) private var typography
    @Binding var isExpanded: Bool
    @State private var rotation: Double = 0

    var size: CGFloat = 64
    var onNewEntry: () -> Void
    var onTalkWithJournal: () -> Void

    public init(
        isExpanded: Binding<Bool>,
        size: CGFloat = 64,
        onNewEntry: @escaping () -> Void,
        onTalkWithJournal: @escaping () -> Void
    ) {
        self._isExpanded = isExpanded
        self.size = size
        self.onNewEntry = onNewEntry
        self.onTalkWithJournal = onTalkWithJournal
    }

    public var body: some View {
        VStack(alignment: .trailing, spacing: 16) {
            // Menu Options
            if isExpanded {
                VStack(alignment: .trailing, spacing: 12) {
                    MenuOption(
                        title: "New entry",
                        icon: "square.and.pencil",
                        size: size * 0.75,
                        action: {
                            handleOptionTap(onNewEntry)
                        }
                    )
                    .transition(.scale.combined(with: .opacity))

                    MenuOption(
                        title: "Talk with your journal",
                        icon: "sparkles",
                        size: size * 0.75,
                        action: {
                            handleOptionTap(onTalkWithJournal)
                        }
                    )
                    .transition(.scale.combined(with: .opacity))
                }
            }

            // Main Button
            Button(action: handleMainTap) {
                Image(systemName: isExpanded ? "xmark" : "plus")
                    .resizable()
                    .scaledToFit()
                    .frame(width: size * 0.45, height: size * 0.45)
                    .foregroundStyle(Color.white)
                    .padding(size * 0.25)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [theme.fabGradientStart, theme.fabGradientEnd]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(Circle())
                    .shadow(color: theme.primary.opacity(0.3), radius: 6, x: 0, y: 4)
                    .rotationEffect(.degrees(rotation))
            }
            .buttonStyle(.plain)
            .frame(width: size, height: size)
        }
    }

    private func handleMainTap() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            rotation += 180
            isExpanded.toggle()
        }
    }

    private func handleOptionTap(_ action: @escaping () -> Void) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            rotation += 180
            isExpanded = false
        }
        // Delay action slightly to allow animation to complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            action()
        }
    }
}

// MARK: - Menu Option

struct MenuOption: View {
    @Environment(\.theme) private var theme
    @Environment(\.typography) private var typography

    let title: String
    let icon: String
    let size: CGFloat
    let action: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            // Label
            Text(title)
                .font(typography.body)
                .foregroundStyle(.black)
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)

            // Icon Button
            Button(action: action) {
                Image(systemName: icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: size * 0.45, height: size * 0.45)
                    .foregroundStyle(Color.white)
                    .padding(size * 0.25)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [theme.fabGradientStart, theme.fabGradientEnd]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(Circle())
                    .shadow(color: theme.primary.opacity(0.3), radius: 6, x: 0, y: 4)
            }
            .buttonStyle(.plain)
            .frame(width: size, height: size)
            .padding(.trailing, 6)
        }
    }
}

#Preview("Interactive") {
    @Previewable @State var isExpanded = false

    ZStack(alignment: .bottomTrailing) {
        Color(hex: "#f5f5f5")
            .ignoresSafeArea()

        // Background blur overlay when menu is expanded
        if isExpanded {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .transition(.opacity)
        }

        VStack {
            Spacer()
            HStack {
                Text("Tap the + button to see options")
                    .font(.caption)
                    .foregroundColor(.gray)
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 200)
        }

        DynamicIconButton(
            isExpanded: $isExpanded,
            onNewEntry: {
                print("New entry tapped")
            },
            onTalkWithJournal: {
                print("Talk with journal tapped")
            }
        )
        .padding(.trailing, 24)
        .padding(.bottom, 40)
    }
    .useTheme()
    .useTypography()
}

#Preview("Expanded State") {
    @Previewable @State var isExpanded = true

    ZStack(alignment: .bottomTrailing) {
        Color(hex: "#f5f5f5")
            .ignoresSafeArea()

        // Background blur overlay
        Color.black.opacity(0.4)
            .ignoresSafeArea()

        VStack(alignment: .trailing, spacing: 16) {
            MenuOption(
                title: "New entry",
                icon: "square.and.pencil",
                size: 48,
                action: {}
            )

            MenuOption(
                title: "Talk with your journal",
                icon: "sparkles",
                size: 48,
                action: {}
            )

            IconButton(systemImage: "xmark", size: 64) {}
        }
        .padding(.trailing, 24)
        .padding(.bottom, 40)
    }
    .useTheme()
    .useTypography()
}

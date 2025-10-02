//
//  IconButton.swift
//  MeetMemento
//
//  Created by Sebastian Mendo on 9/30/25.
//

import SwiftUI

public struct IconButton: View {
    @Environment(\.theme) private var theme
    let systemImage: String
    var size: CGFloat = 64
    var action: () -> Void

    public init(systemImage: String, size: CGFloat = 64, action: @escaping () -> Void) {
        self.systemImage = systemImage
        self.size = size
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .frame(width: size, height: size)
                .foregroundStyle(theme.primary)
                .background(theme.primary)
                .clipShape(RoundedRectangle(cornerRadius: size.rounded(), style: .continuous))
        }.buttonStyle(.plain)
    }
}

#Preview("Light") {
    HStack(spacing: 16) {
        IconButton(systemImage: "mic.fill") {}
        IconButton(systemImage: "plus") {}
    }
    .padding()
    .useTheme()
    .previewLayout(.sizeThatFits)
}

#Preview("Dark") {
    HStack(spacing: 16) {
        IconButton(systemImage: "mic.fill") {}
        IconButton(systemImage: "plus") {}
    }
    .padding()
    .useTheme()
    .preferredColorScheme(.dark)
    .previewLayout(.sizeThatFits)
}

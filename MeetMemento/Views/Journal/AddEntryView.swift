import SwiftUI

public struct AddEntryView: View {
    @Environment(\.theme) private var theme
    @Environment(\.dismiss) private var dismiss

    @State private var text: String = ""
    @State private var isSaving = false
    @FocusState private var textFocused: Bool

    let onSave: (_ text: String) -> Void
    let onCancel: () -> Void

    public init(onSave: @escaping (_ text: String) -> Void,
                onCancel: @escaping () -> Void) {
        self.onSave = onSave
        self.onCancel = onCancel
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(theme.inputBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(theme.border, lineWidth: 1)
                        )

                    TextEditor(text: $text)
                        .padding(12)
                        .frame(minHeight: 180)
                        .background(.clear)
                        .focused($textFocused)
                        .onAppear { DispatchQueue.main.async { textFocused = true } }

                    if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text("What's on your mind?")
                            .foregroundStyle(theme.mutedForeground)
                            .padding(.top, 18)
                            .padding(.leading, 18)
                            .allowsHitTesting(false)
                    }
                }
                .padding(.horizontal, 16)

                Spacer(minLength: 0)
            }
            .background(theme.background.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { onCancel(); dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        save()
                    } label: {
                        if isSaving {
                            ProgressView().tint(theme.primaryForeground)
                        } else {
                            Text("Save").fontWeight(.medium)
                        }
                    }
                    .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSaving)
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { textFocused = false }
                }
            }
            .navigationTitle("New Entry")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func save() {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        isSaving = true
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        onSave(trimmed)
    }
}

#Preview("AddEntry • Light") {
    AddEntryView { text in
        print("SAVE -> \(text)")
    } onCancel: {
        print("CANCEL")
    }
    .useTheme()
    .useTypography()
}

#Preview("AddEntry • Dark") {
    AddEntryView { text in
        print("SAVE -> \(text)")
    } onCancel: {}
    .useTheme()
    .useTypography()
    .preferredColorScheme(.dark)
}

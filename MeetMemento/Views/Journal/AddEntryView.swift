//
//  AddEntryView.swift
//  MeetMemento
//
//  Notion-style full-page journal entry editor with title and body fields.
//

import SwiftUI

// MARK: - Entry State

public enum EntryState: Hashable {
    case create           // Regular journal entry
    case edit(Entry)      // Editing existing entry
}

public struct AddEntryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) private var theme
    @Environment(\.typography) private var type
    
    @State private var title: String
    @State private var text: String
    @State private var isSaving = false

    @FocusState private var focusedField: Field?

    enum Field: Hashable {
        case title
        case body
    }

    let state: EntryState
    let onSave: (_ title: String, _ text: String) -> Void

    public init(
        state: EntryState,
        onSave: @escaping (_ title: String, _ text: String) -> Void
    ) {
        self.state = state
        self.onSave = onSave

        // Initialize title and text based on state
        switch state {
        case .create:
            _title = State(initialValue: "")
            _text = State(initialValue: "")
        case .edit(let entry):
            _title = State(initialValue: entry.title)
            _text = State(initialValue: entry.text)
        }
    }

    // MARK: - Computed Properties

    private var editingEntry: Entry? {
        if case .edit(let entry) = state { return entry }
        return nil
    }
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Notion-style title field
                titleField
                    .padding(.top, 24)
                
                // Spacious body editor
                bodyField
                    .padding(.top, 16)
                
                Spacer(minLength: 100)
            }
            .padding(.horizontal, 20)
        }
        .background(BaseColors.white.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                saveButton
            }
        }
        .onAppear {
            setupInitialFocus()
        }
    }
    
    // MARK: - Subviews

    private var titleField: some View {
        TextField("", text: $title, axis: .vertical)
            .font(type.h3)
            .foregroundStyle(theme.foreground)
            .focused($focusedField, equals: .title)
            .textInputAutocapitalization(.words)
            .submitLabel(.next)
            .onSubmit {
                focusedField = .body
            }
            .placeholder(when: title.isEmpty) {
                Text("Add a title...")
                    .font(type.h3)
                    .foregroundStyle(theme.mutedForeground.opacity(0.4))
            }
    }
    
    private var bodyField: some View {
        ZStack(alignment: .topLeading) {
            if text.isEmpty {
                Text("Write your thoughts...")
                    .font(.system(size: 17))
                    .lineSpacing(3.4)
                    .foregroundStyle(theme.mutedForeground.opacity(0.5))
                    .padding(.top, 8)
                    .allowsHitTesting(false)
            }

            TextEditor(text: $text)
                .font(.system(size: 17))
                .lineSpacing(3.4) // 1.2x line height for readability
                .foregroundStyle(theme.foreground)
                .focused($focusedField, equals: .body)
                .scrollContentBackground(.hidden)
                .frame(minHeight: 300)
        }
    }
    
    private var saveButton: some View {
        Button {
            save()
        } label: {
            if isSaving {
                ProgressView()
                    .tint(theme.primary)
            } else {
                Text("Save")
                    .fontWeight(.medium)
            }
        }
        .disabled(isSaving || text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }
    
    // MARK: - Actions

    private func setupInitialFocus() {
        // Focus immediately for instant writing experience
        // Focus title if empty, otherwise focus body
        focusedField = title.isEmpty ? .title : .body
    }

    private func save() {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedText.isEmpty else { return }

        isSaving = true
        UIImpactFeedbackGenerator(style: .light).impactOccurred()

        onSave(trimmedTitle, trimmedText)

        isSaving = false
    }
}

// MARK: - Previews

#Preview("Create Entry") {
    NavigationStack {
        AddEntryView(state: .create) { _, _ in }
    }
    .useTheme()
    .useTypography()
}

#Preview("Edit Entry") {
    NavigationStack {
        AddEntryView(state: .edit(Entry.sampleEntries[0])) { _, _ in }
    }
    .useTheme()
    .useTypography()
}

#Preview("Create Entry • Dark") {
    NavigationStack {
        AddEntryView(state: .create) { _, _ in }
    }
    .useTheme()
    .useTypography()
    .preferredColorScheme(.dark)
}

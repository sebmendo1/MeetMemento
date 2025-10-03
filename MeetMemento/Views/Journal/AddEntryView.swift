//
//  AddEntryView.swift
//  MeetMemento
//
//  Notion-style full-page journal entry editor with title and body fields.
//

import SwiftUI

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
    
    let entry: Entry? // nil for create, populated for edit
    let onSave: (_ title: String, _ text: String) -> Void
    
    public init(
        entry: Entry? = nil,
        onSave: @escaping (_ title: String, _ text: String) -> Void
    ) {
        self.entry = entry
        self.onSave = onSave
        _title = State(initialValue: entry?.title ?? "")
        _text = State(initialValue: entry?.text ?? "")
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
        .background(theme.background.ignoresSafeArea())
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
            .font(.system(size: 32, weight: .bold))
            .foregroundStyle(theme.foreground)
            .focused($focusedField, equals: .title)
            .textInputAutocapitalization(.words)
            .submitLabel(.next)
            .onSubmit {
                focusedField = .body
            }
            .placeholder(when: title.isEmpty) {
                Text("Add a title...")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(theme.mutedForeground.opacity(0.4))
            }
    }
    
    private var bodyField: some View {
        ZStack(alignment: .topLeading) {
            if text.isEmpty {
                Text("Write your thoughts...")
                    .font(.system(size: 17))
                    .foregroundStyle(theme.mutedForeground.opacity(0.5))
                    .padding(.top, 8)
                    .allowsHitTesting(false)
            }
            
            TextEditor(text: $text)
                .font(.system(size: 17))
                .lineSpacing(6) // 1.5x line height for readability
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
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            focusedField = title.isEmpty ? .title : .body
        }
    }
    
    private func save() {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedText.isEmpty else { return }
        
        isSaving = true
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        
        // Save with a slight delay for UX smoothness
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onSave(trimmedTitle, trimmedText)
            isSaving = false
        }
    }
}

// MARK: - Previews

#Preview("Create Entry") {
    NavigationStack {
        AddEntryView(entry: nil) { title, text in
            print("Created: \(title) - \(text)")
        }
    }
    .useTheme()
    .useTypography()
}

#Preview("Edit Entry") {
    NavigationStack {
        AddEntryView(entry: Entry.sampleEntries[0]) { title, text in
            print("Updated: \(title) - \(text)")
        }
    }
    .useTheme()
    .useTypography()
}

#Preview("Create Entry • Dark") {
    NavigationStack {
        AddEntryView(entry: nil) { title, text in
            print("Created: \(title) - \(text)")
        }
    }
    .useTheme()
    .useTypography()
    .preferredColorScheme(.dark)
}

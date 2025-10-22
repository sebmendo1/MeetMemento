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
    case followUp(questionText: String, questionId: UUID?)  // Answering follow-up question
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
    let onSave: (_ title: String, _ text: String, _ questionId: UUID?) -> Void

    public init(
        state: EntryState,
        onSave: @escaping (_ title: String, _ text: String, _ questionId: UUID?) -> Void
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
        case .followUp(let questionText, _):
            _title = State(initialValue: questionText)
            _text = State(initialValue: "")
        }
    }

    // MARK: - Computed Properties

    private var isFollowUpEntry: Bool {
        if case .followUp = state { return true }
        return false
    }

    private var followUpQuestionText: String? {
        if case .followUp(let text, _) = state { return text }
        return nil
    }

    private var editingEntry: Entry? {
        if case .edit(let entry) = state { return entry }
        return nil
    }

    private var questionId: UUID? {
        if case .followUp(_, let id) = state { return id }
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
        .background(theme.background.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                saveButton
            }
        }
        .onAppear {
            print("🟢🟢🟢 ADDENTRYVIEW APPEARED! 🟢🟢🟢")
            print("   State: \(state)")
            if case .followUp(let q, let id) = state {
                print("   Question: \(q)")
                print("   QuestionId: \(id?.uuidString ?? "NIL")")
            }
            setupInitialFocus()
        }
    }
    
    // MARK: - Subviews

    private var titleField: some View {
        Group {
            if isFollowUpEntry {
                // NON-EDITABLE follow-up question in Recoleta font
                Text(title)
                    .font(.custom("Recoleta-Black", size: 28))
                    .foregroundStyle(PrimaryScale.primary600)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 8)
            } else {
                // EDITABLE title field for regular entries
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
            print("🟡🟡🟡 SAVE BUTTON TAPPED! 🟡🟡🟡")
            print("   Text length: \(text.count)")
            print("   Trimmed length: \(text.trimmingCharacters(in: .whitespacesAndNewlines).count)")
            print("   Button disabled: \(isSaving || text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)")
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
        if isFollowUpEntry {
            // For follow-ups, always focus body (question is non-editable)
            focusedField = .body
        } else {
            // For regular entries, focus title if empty
            focusedField = title.isEmpty ? .title : .body
        }
    }

    private func save() {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedText.isEmpty else { return }

        isSaving = true
        UIImpactFeedbackGenerator(style: .light).impactOccurred()

        // Debug logging
        print("💾 SAVE BUTTON PRESSED")
        print("   - State: \(state)")
        print("   - QuestionId: \(questionId?.uuidString ?? "nil")")
        print("   - Title: \(trimmedTitle)")

        // Pass questionId to save callback
        onSave(trimmedTitle, trimmedText, questionId)

        print("✅ SAVE CALLBACK COMPLETED")
        isSaving = false
    }
}

// MARK: - Previews

#Preview("Create Entry") {
    NavigationStack {
        AddEntryView(state: .create) { title, text, questionId in
            print("Created: \(title) - \(text)")
        }
    }
    .useTheme()
    .useTypography()
}

#Preview("Edit Entry") {
    NavigationStack {
        AddEntryView(state: .edit(Entry.sampleEntries[0])) { title, text, questionId in
            print("Updated: \(title) - \(text)")
        }
    }
    .useTheme()
    .useTypography()
}

#Preview("Follow-Up Question") {
    NavigationStack {
        AddEntryView(state: .followUp(
            questionText: "What strategies help you manage stress effectively?",
            questionId: UUID()
        )) { title, text, questionId in
            print("Answered follow-up: \(questionId?.uuidString ?? "nil")")
        }
    }
    .useTheme()
    .useTypography()
}

#Preview("Create Entry • Dark") {
    NavigationStack {
        AddEntryView(state: .create) { title, text, questionId in
            print("Created: \(title) - \(text)")
        }
    }
    .useTheme()
    .useTypography()
    .preferredColorScheme(.dark)
}

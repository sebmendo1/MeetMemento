//
//  AddEntryView.swift
//  MeetMemento
//
//  Notion-style full-page journal entry editor with title and body fields.
//

import SwiftUI
import Speech

public struct AddEntryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) private var theme
    @Environment(\.typography) private var type

    @State private var title: String
    @State private var text: String
    @State private var isSaving = false

    @State private var speechService = SpeechRecognitionService()
    @State private var showPermissionAlert = false

    @FocusState private var focusedField: Field?
    
    enum Field: Hashable {
        case title
        case body
    }
    
    let entry: Entry? // nil for create, populated for edit
    let followUpQuestion: String? // For follow-up entries
    let onSave: (_ title: String, _ text: String) -> Void
    
    public init(
        entry: Entry? = nil,
        followUpQuestion: String? = nil,
        onSave: @escaping (_ title: String, _ text: String) -> Void
    ) {
        self.entry = entry
        self.followUpQuestion = followUpQuestion
        self.onSave = onSave
        _title = State(initialValue: entry?.title ?? followUpQuestion ?? "")
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
            ToolbarItem(placement: .topBarLeading) {
                voiceButton
            }
            ToolbarItem(placement: .topBarTrailing) {
                saveButton
            }
        }
        .safeAreaInset(edge: .bottom) {
            if speechService.isRecording {
                recordingBanner
            }
        }
        .alert("Microphone Permission Required", isPresented: $showPermissionAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Open Settings") {
                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsUrl)
                }
            }
        } message: {
            Text("Please enable microphone and speech recognition access in Settings to use voice-to-text.")
        }
        .onAppear {
            setupInitialFocus()
        }
    }
    
    // MARK: - Subviews
    
    private var titleField: some View {
        TextField("", text: $title, axis: .vertical)
            .font(.system(size: 32, weight: .bold))
            .foregroundStyle(isFollowUpEntry ? PrimaryScale.primary600 : theme.foreground)
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
    
    /// Determines if this is a follow-up entry based on the follow-up question
    private var isFollowUpEntry: Bool {
        followUpQuestion != nil
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

    private var voiceButton: some View {
        Button {
            handleVoiceButtonTap()
        } label: {
            Image(systemName: speechService.isRecording ? "mic.fill" : "mic")
                .foregroundStyle(speechService.isRecording ? .red : theme.foreground)
                .symbolEffect(.pulse, options: .repeating, isActive: speechService.isRecording)
        }
    }

    private var recordingBanner: some View {
        HStack(spacing: 12) {
            // Pulsing red dot
            Circle()
                .fill(.red)
                .frame(width: 8, height: 8)
                .opacity(speechService.isRecording ? 1 : 0.3)
                .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: speechService.isRecording)

            Text("Recording...")
                .font(.subheadline)
                .foregroundStyle(theme.foreground)

            Spacer()

            // Live transcription preview (if available)
            if !speechService.transcription.isEmpty {
                Text(speechService.transcription)
                    .font(.caption)
                    .foregroundStyle(theme.mutedForeground)
                    .lineLimit(1)
                    .frame(maxWidth: 150, alignment: .trailing)
            }

            // Stop button
            Button {
                stopRecordingAndAppendText()
            } label: {
                Text("Done")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(PrimaryScale.primary600)
                    .cornerRadius(8)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
        .cornerRadius(12)
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    // MARK: - Actions
    
    private func setupInitialFocus() {
        // Focus immediately for instant writing experience
        focusedField = title.isEmpty ? .title : .body
    }
    
    private func save() {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedText.isEmpty else { return }

        isSaving = true
        UIImpactFeedbackGenerator(style: .light).impactOccurred()

        // Save immediately for instant feedback
        onSave(trimmedTitle, trimmedText)
        isSaving = false
    }

    private func handleVoiceButtonTap() {
        if speechService.isRecording {
            // Stop recording
            stopRecordingAndAppendText()
        } else {
            // Start recording
            Task {
                await startRecording()
            }
        }
    }

    private func startRecording() async {
        // Request authorization if needed
        if speechService.authorizationStatus != .authorized {
            let authorized = await speechService.requestAuthorization()
            if !authorized {
                showPermissionAlert = true
                return
            }
        }

        // Start recording
        do {
            try speechService.startRecording()
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        } catch {
            print("Failed to start recording: \(error)")
            showPermissionAlert = true
        }
    }

    private func stopRecordingAndAppendText() {
        // Stop recording
        speechService.stopRecording()

        // Append transcribed text to the text field
        if !speechService.transcription.isEmpty {
            // Add spacing if text already exists
            if !text.isEmpty && !text.hasSuffix("\n\n") {
                text += "\n\n"
            }

            // Append the transcription
            text += speechService.transcription

            // Reset transcription
            speechService.resetTranscription()

            // Haptic feedback
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
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

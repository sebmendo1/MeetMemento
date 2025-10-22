//
//  SpeechRecognitionService.swift
//  MeetMemento
//
//  Handles real-time speech-to-text transcription using Apple's Speech framework.
//

import Speech
import AVFoundation
import SwiftUI

@Observable
class SpeechRecognitionService {
    // MARK: - Properties

    /// Current transcribed text from speech recognition
    var transcription: String = ""

    /// Whether the service is currently recording
    var isRecording: Bool = false

    /// Current authorization status
    var authorizationStatus: SFSpeechRecognizerAuthorizationStatus = .notDetermined

    /// Error message if something goes wrong
    var errorMessage: String?

    // Private properties
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()

    // MARK: - Initialization

    init() {
        // Initialize with user's locale for better recognition
        self.speechRecognizer = SFSpeechRecognizer(locale: Locale.current)
        self.authorizationStatus = SFSpeechRecognizer.authorizationStatus()
    }

    // MARK: - Authorization

    /// Request authorization for speech recognition and microphone access
    func requestAuthorization() async -> Bool {
        // Request speech recognition authorization
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                DispatchQueue.main.async {
                    self.authorizationStatus = status
                    continuation.resume(returning: status == .authorized)
                }
            }
        }
    }

    // MARK: - Recording

    /// Start recording and transcribing speech
    func startRecording() throws {
        // Cancel any ongoing task
        recognitionTask?.cancel()
        recognitionTask = nil

        // Configure audio session
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

        // Create recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()

        guard let recognitionRequest = recognitionRequest else {
            throw RecognitionError.unableToCreateRequest
        }

        // Configure request for on-device recognition (privacy-focused)
        recognitionRequest.requiresOnDeviceRecognition = false // Set to true for offline mode
        recognitionRequest.shouldReportPartialResults = true

        // Add context for better journaling recognition
        recognitionRequest.contextualStrings = [
            "journal", "today", "yesterday", "grateful", "reflection",
            "meditation", "mindfulness", "therapy", "emotion", "feeling"
        ]

        // Get input node
        let inputNode = audioEngine.inputNode

        // Start recognition task
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }

            if let result = result {
                // Update transcription with latest result
                DispatchQueue.main.async {
                    self.transcription = result.bestTranscription.formattedString
                }
            }

            if let error = error {
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                    self.stopRecording()
                }
            }
        }

        // Configure audio tap
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }

        // Start audio engine
        audioEngine.prepare()
        try audioEngine.start()

        // Update state
        isRecording = true
        transcription = ""
        errorMessage = nil
    }

    /// Stop recording and finalize transcription
    func stopRecording() {
        // Stop audio engine
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)

        // End recognition request
        recognitionRequest?.endAudio()
        recognitionRequest = nil

        // Cancel task
        recognitionTask?.cancel()
        recognitionTask = nil

        // Update state
        isRecording = false
    }

    /// Reset the transcription text
    func resetTranscription() {
        transcription = ""
        errorMessage = nil
    }

    // MARK: - Error Types

    enum RecognitionError: LocalizedError {
        case unableToCreateRequest
        case recognizerUnavailable

        var errorDescription: String? {
            switch self {
            case .unableToCreateRequest:
                return "Unable to create speech recognition request"
            case .recognizerUnavailable:
                return "Speech recognizer is unavailable"
            }
        }
    }
}

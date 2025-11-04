//
//  SpeechService.swift
//  MeetMemento
//
//  Handles speech-to-text functionality using Apple's Speech framework.
//  Provides real-time voice transcription for journal entries.
//

import Foundation
import Speech
import AVFoundation

@MainActor
class SpeechService: ObservableObject {
    static let shared = SpeechService()

    // MARK: - Published Properties

    /// Whether currently recording audio
    @Published var isRecording = false

    /// Whether processing/transcribing audio
    @Published var isProcessing = false

    /// Current recording duration in seconds
    @Published var currentDuration: TimeInterval = 0

    /// Transcribed text result
    @Published var transcribedText = ""

    /// Error message if something fails
    @Published var errorMessage: String?

    // MARK: - Private Properties

    private var audioEngine: AVAudioEngine?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recordingStartTime: Date?
    private var durationTimer: Timer?

    // Maximum recording duration (1 minute - Apple's limit for real-time recognition)
    private let maxRecordingDuration: TimeInterval = 60

    private init() {}

    // MARK: - Public Methods

    /// Requests microphone and speech recognition permissions
    /// - Returns: true if both permissions are granted
    func requestPermissions() async -> Bool {
        // Check microphone permission
        let micStatus = await requestMicrophonePermission()
        guard micStatus else {
            errorMessage = "Microphone permission denied"
            AppLogger.log("❌ Microphone permission denied", category: AppLogger.general, type: .error)
            return false
        }

        // Check speech recognition permission
        let speechStatus = await requestSpeechPermission()
        guard speechStatus else {
            errorMessage = "Speech recognition permission denied"
            AppLogger.log("❌ Speech recognition permission denied", category: AppLogger.general, type: .error)
            return false
        }

        return true
    }

    /// Starts recording and real-time transcription
    func startRecording() async throws {
        // Stop any existing recording first
        await stopRecording()

        // Request permissions if needed
        guard await requestPermissions() else {
            throw SpeechError.permissionDenied
        }

        // Check if speech recognition is available
        guard speechRecognizer?.isAvailable == true else {
            throw SpeechError.recognitionUnavailable
        }

        // Configure audio session
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

        // Create and configure recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        recognitionRequest?.shouldReportPartialResults = true
        recognitionRequest?.requiresOnDeviceRecognition = false // Use server for better accuracy

        guard let recognitionRequest = recognitionRequest else {
            throw SpeechError.audioEngineError
        }

        // Setup audio engine
        audioEngine = AVAudioEngine()
        guard let audioEngine = audioEngine else {
            throw SpeechError.audioEngineError
        }

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }

        audioEngine.prepare()
        try audioEngine.start()

        // Start recognition task
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }

            Task { @MainActor in
                if let result = result {
                    self.transcribedText = result.bestTranscription.formattedString
                }

                if error != nil {
                    self.errorMessage = error?.localizedDescription ?? "Recognition failed"
                    AppLogger.log("❌ Speech recognition error: \(error?.localizedDescription ?? "unknown")", category: AppLogger.general, type: .error)
                    await self.stopRecording()
                }

                if result?.isFinal == true {
                    await self.stopRecording()
                }
            }
        }

        isRecording = true
        recordingStartTime = Date()
        startDurationTimer()

        AppLogger.log("🎤 Started recording", category: AppLogger.general)
    }

    /// Stops recording and finalizes transcription
    func stopRecording() async {
        // Stop audio engine
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)

        // End recognition request
        recognitionRequest?.endAudio()
        recognitionRequest = nil

        // Cancel recognition task
        recognitionTask?.cancel()
        recognitionTask = nil

        // Stop duration timer
        durationTimer?.invalidate()
        durationTimer = nil

        // Update state
        isRecording = false
        isProcessing = true

        // Wait a moment for final transcription
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds

        isProcessing = false
        currentDuration = 0

        AppLogger.log("🎤 Stopped recording. Transcribed: \(transcribedText.prefix(50))...", category: AppLogger.general)
    }

    /// Cancels recording without saving transcription
    func cancelRecording() async {
        transcribedText = ""
        await stopRecording()
        AppLogger.log("🎤 Cancelled recording", category: AppLogger.general)
    }

    // MARK: - Private Methods

    private func requestMicrophonePermission() async -> Bool {
        await withCheckedContinuation { continuation in
            AVAudioApplication.requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }

    private func requestSpeechPermission() async -> Bool {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
    }

    private func startDurationTimer() {
        durationTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self else { return }

            Task { @MainActor in
                guard let startTime = self.recordingStartTime else { return }
                self.currentDuration = Date().timeIntervalSince(startTime)

                // Auto-stop at 60 seconds (Apple's limit)
                if self.currentDuration >= self.maxRecordingDuration {
                    AppLogger.log("⏱️ Reached 60-second limit, auto-stopping", category: AppLogger.general)
                    await self.stopRecording()
                }
            }
        }
    }

    // MARK: - Error Types

    enum SpeechError: LocalizedError {
        case permissionDenied
        case recognitionUnavailable
        case audioEngineError
        case recognitionFailed

        var errorDescription: String? {
            switch self {
            case .permissionDenied:
                return "Microphone or speech recognition permission denied. Please enable in Settings."
            case .recognitionUnavailable:
                return "Speech recognition is not available. Please check your internet connection."
            case .audioEngineError:
                return "Failed to start audio recording. Please try again."
            case .recognitionFailed:
                return "Speech recognition failed. Please try again."
            }
        }
    }
}

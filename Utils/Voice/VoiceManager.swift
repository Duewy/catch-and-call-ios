//
//  VoiceManager.swift
//  CatchAndCall_VCC
//
//  Speech recognition worker.
//  DOES NOT own AVAudioSession, AVAudioEngine, or mic taps.
//  Consumes audio buffers and produces transcripts.
//

import Foundation
import Combine
import Speech
import AVFoundation

@MainActor
final class VoiceManager: ObservableObject {

    // MARK: - Published State (UI / Debug)

    @Published var isListening: Bool = false
    @Published var lastRecognizedText: String? = nil
    @Published var errorMessage: String? = nil
    @Published var liveTranscription: String = ""

    // MARK: - Speech Components

    private let speechRecognizer = SFSpeechRecognizer()   // system locale
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?

    private let endTriggerWord = "over"
    private var didReceiveFinalResult = false

    // MARK: - Permissions (still valid here)

    func requestPermissions() async {
        print("🔐 requesting speech + mic permissions")

        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                print("🗣️ speech auth status:", status.rawValue)

                AVAudioSession.sharedInstance().requestRecordPermission { granted in
                    print("🎤 mic permission granted:", granted)
                    continuation.resume()
                }
            }
        }
    }

    // MARK: - Recognition Control (called by Coordinator)

    /// Begin recognition. Coordinator must already have:
    /// - configured audio session
    /// - started audio engine
    /// - installed mic tap
    func startRecognition(onResult: @escaping (String) -> Void) {

        stopRecognition()

        guard let recognizer = speechRecognizer, recognizer.isAvailable else {
            errorMessage = "Speech recognizer not available"
            print("❌ recognizer not available")
            return
        }

        didReceiveFinalResult = false
        errorMessage = nil
        lastRecognizedText = nil
        liveTranscription = ""

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        self.recognitionRequest = request

        isListening = true

        recognitionTask = recognizer.recognitionTask(with: request) {
            [weak self] result, error in
            guard let self else { return }

            if let error {
                print("❌ speech recognition error:", error.localizedDescription)
                self.errorMessage = error.localizedDescription
                self.stopRecognition()
                return
            }

            guard let result else { return }

            let text = result.bestTranscription.formattedString
                .lowercased()
                .trimmingCharacters(in: .whitespacesAndNewlines)

            self.liveTranscription = text
            print("🟡 partial:", text)

            // Detect explicit end trigger
            if text.hasSuffix(" \(self.endTriggerWord)") || text == self.endTriggerWord {

                let cleaned = text
                    .replacingOccurrences(of: " \(self.endTriggerWord)", with: "")
                    .replacingOccurrences(of: self.endTriggerWord, with: "")
                    .trimmingCharacters(in: .whitespaces)

                print("🟢 final (over detected):", cleaned)

                self.didReceiveFinalResult = true
                self.lastRecognizedText = cleaned
                onResult(cleaned)
                self.stopRecognition()
            }
        }
    }

    // MARK: - Audio Buffer Input (called by Coordinator)

    /// Feed mic audio buffers into speech recognition.
    func appendAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        recognitionRequest?.append(buffer)
    }

    // MARK: - Stop / Cleanup

    func stopRecognition() {
        guard isListening else { return }

        recognitionRequest?.endAudio()
        recognitionTask?.cancel()

        recognitionTask = nil
        recognitionRequest = nil

        isListening = false
        didReceiveFinalResult = false
    }
}

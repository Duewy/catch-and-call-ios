//
//  VoiceManager.swift
//  CatchAndCall_VCC
//
//  Voice Training – single-shot recognition only
//

import Foundation
import Combine
import AVFoundation
import Speech

@MainActor
final class VoiceManager: ObservableObject {

    // MARK: - Published State (UI)
    @Published var isListening: Bool = false
    @Published var lastRecognizedText: String? = nil
    @Published var errorMessage: String? = nil
    @Published var liveTranscription: String = ""
    
    // MARK: - Speech Components
    private let speechRecognizer = SFSpeechRecognizer()   // auto locale
    private let audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var didReceiveResult = false
    private var timeoutWorkItem: DispatchWorkItem?
    private let endTriggerWord = "over"     // helps give a end point for Apple STT


    // MARK: - Permissions

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

    // MARK: - Start Training Listen (Single Shot)

    func startTrainingListen(onResult: @escaping (String) -> Void) {

        stopListening()
        didReceiveResult = false
        timeoutWorkItem?.cancel()
        timeoutWorkItem = nil

        print("🎙️ startTrainingListen called")

        errorMessage = nil
        lastRecognizedText = nil

        guard let recognizer = speechRecognizer, recognizer.isAvailable else {
            errorMessage = "speech recognizer not available"
            print("❌ recognizer not available")
            return
        }

        do {
            try configureAudioSession()
        } catch {
            errorMessage = "audio session configuration failed"
            print("❌ audio session error:", error.localizedDescription)
            return
        }

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest else {
            errorMessage = "failed to create recognition request"
            print("❌ recognition request nil")
            return
        }
            // allows Apple to stream words as they are recognized.
        recognitionRequest.shouldReportPartialResults = true

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) {
            [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }

        audioEngine.prepare()

        do {
            try audioEngine.start()
            print("🔊 audio engine started")
        } catch {
            errorMessage = "audio engine failed to start"
            print("❌ audio engine start failed:", error.localizedDescription)
            return
        }

        isListening = true

        recognitionTask = recognizer.recognitionTask(with: recognitionRequest) {
            [weak self] result, error in
            guard let self else { return }

            if let error {
                print("❌ speech recognition error:", error.localizedDescription)
                self.errorMessage = error.localizedDescription
                self.finishListening()
                return
            }

            guard let result else { return }

            let text = result.bestTranscription.formattedString
                .lowercased()
                .trimmingCharacters(in: .whitespacesAndNewlines)

            // 🔴 live updates (Google-style)
            self.liveTranscription = text
            print("🟡 partial:", text)

            // 🔑 detect explicit end trigger
            if text.hasSuffix(" \(self.endTriggerWord)") || text == self.endTriggerWord {

                let cleaned = text
                    .replacingOccurrences(of: " \(self.endTriggerWord)", with: "")
                    .replacingOccurrences(of: self.endTriggerWord, with: "")
                    .trimmingCharacters(in: .whitespaces)

                print("🟢 final (over detected):", cleaned)

                self.didReceiveResult = true
                self.lastRecognizedText = cleaned
                onResult(cleaned)
                self.finishListening()
            }
        }



        // 🔒 FORCE FINALIZATION (important)
    /*    let workItem = DispatchWorkItem { [weak self] in
            guard let self else { return }
            if self.isListening && !self.didReceiveResult {
                print("⏱️ forcing speech end after timeout (no result yet)")
                self.finishListening()
            }
        }
        timeoutWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 7.0, execute: workItem)
     */
    }

    // MARK: - Stop & Cleanup

    func stopListening() {
        if audioEngine.isRunning {
            audioEngine.stop()
            print("🛑 audio engine stopped")
        }

        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()

        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil
        lastRecognizedText = nil

        isListening = false
        deactivateAudioSession()
        didReceiveResult = false
        timeoutWorkItem?.cancel()
        timeoutWorkItem = nil
    }
    
    private func finishListening() {
        print("✅ finishing speech session")

        recognitionRequest?.endAudio()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            if self.audioEngine.isRunning {
                self.audioEngine.stop()
            }
            self.audioEngine.inputNode.removeTap(onBus: 0)
            self.recognitionTask = nil
            self.recognitionRequest = nil
            self.isListening = false
            self.deactivateAudioSession()
        }
        timeoutWorkItem?.cancel()
        timeoutWorkItem = nil
    }

    // MARK: - Audio Session

    /// VoiceManager does NOT own AVAudioSession configuration.
    /// Audio session ownership lives in VoiceSessionManager.
    private func configureAudioSession() throws {
        VoiceSessionManager.shared.ensureAudioSessionActive()
        // Optional: you can still log the route for debugging.
        let session = AVAudioSession.sharedInstance()
        print("🎧 current route:", session.currentRoute)
    }



    private func deactivateAudioSession() {
        let session = AVAudioSession.sharedInstance()
        try? session.setActive(false, options: .notifyOthersOnDeactivation)
        print("🎚️ audio session deactivated")
    }
}

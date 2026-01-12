import Foundation
import Speech
import AVFoundation

/// Speech-to-text capture using AVAudioEngine + SFSpeechRecognizer.
/// IMPORTANT: This class does NOT configure AVAudioSession.
/// Audio session ownership lives in VoiceSessionManager.
final class SpeechService {

    private let recognizer: SFSpeechRecognizer? = SFSpeechRecognizer()
    private let audioEngine = AVAudioEngine()

    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?

    private var isListening = false

    /// Starts listening and streams transcription updates to `onResult`.
    /// Call `stopListening()` to end early.
    func startListening(onResult: @escaping (String) -> Void) {
        guard !isListening else {
            print("⚠️ SpeechService.startListening called while already listening — ignored")
            return
        }

        guard let recognizer else {
            print("❌ SpeechService: SFSpeechRecognizer unavailable")
            return
        }

        // Clean any previous state defensively
        cleanupEngineOnly()

        isListening = true
        print("🎤 SpeechService: starting")

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        self.request = request

        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)

        // Avoid "bus already tapped" crashes
        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
            request.append(buffer)
        }

        audioEngine.prepare()

        do {
            try audioEngine.start()
        } catch {
            print("❌ SpeechService: AudioEngine failed to start:", error)
            stopListening()
            return
        }

        task = recognizer.recognitionTask(with: request) { [weak self] result, error in
            guard let self else { return }

            if let error {
                print("❌ SpeechService: recognition error:", error)
                self.stopListening()
                return
            }

            guard let result else { return }

            let text = result.bestTranscription.formattedString
            onResult(text)

            if result.isFinal {
                print("✅ SpeechService: final result:", text)
                self.stopListening()
            }
        }
    }

    func stopListening() {
        guard isListening else { return }
        print("🛑 SpeechService: stopping")

        isListening = false

        // Stop engine + remove tap
        cleanupEngineOnly()

        // End request and cancel task
        request?.endAudio()
        request = nil

        task?.cancel()
        task = nil
    }

    private func cleanupEngineOnly() {
        if audioEngine.isRunning {
            audioEngine.stop()
        }
        audioEngine.inputNode.removeTap(onBus: 0)
        audioEngine.reset()
    }
}

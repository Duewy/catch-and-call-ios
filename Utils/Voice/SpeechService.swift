import Foundation
import Speech
import AVFoundation

final class SpeechService {

    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private let audioEngine = AVAudioEngine()

    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?

    private var isListening = false

    // MARK: - Start Listening
    func startListening(onResult: @escaping (String) -> Void) {

        guard !isListening else {
            print("⚠️ SpeechService.startListening called while already listening")
            return
        }

        print("🎤 SpeechService: starting")

        isListening = true
        request = SFSpeechAudioBufferRecognitionRequest()

        guard let request = request else {
            print("❌ Failed to create recognition request")
            isListening = false
            return
        }

        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)

        inputNode.removeTap(onBus: 0) // 🔒 safety cleanup
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
            request.append(buffer)
        }

        audioEngine.prepare()

        do {
            try audioEngine.start()
        } catch {
            print("❌ AudioEngine failed to start:", error)
            cleanup()
            return
        }

        task = recognizer?.recognitionTask(with: request) { [weak self] result, error in

            if let error = error {
                print("❌ Speech recognition error:", error)
                self?.cleanup()
                return
            }

            guard let result = result else { return }

            if result.isFinal {
                let text = result.bestTranscription.formattedString
                print("✅ Final speech result:", text)
                onResult(text)
                self?.cleanup()
            }
        }
    }

    // MARK: - Stop Listening
    func stopListening() {
        guard isListening else { return }
        print("🛑 SpeechService: stopListening called")
        cleanup()
    }

    // MARK: - Cleanup (single source of truth)
    private func cleanup() {
        if audioEngine.isRunning {
            audioEngine.stop()
        }

        audioEngine.inputNode.removeTap(onBus: 0)

        request?.endAudio()
        request = nil

        task?.cancel()
        task = nil

        isListening = false
        print("🧹 SpeechService cleaned up")
    }
}

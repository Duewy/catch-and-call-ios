final class SpeechService {

    private let recognizer = SFSpeechRecognizer()
    private let audioEngine = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?

    private var isListening = false

    func startListening(onResult: @escaping (String) -> Void) {
        // 🔒 Prevent double tap
        guard !isListening else {
            print("⚠️ startListening called while already listening — ignored")
            return
        }

        isListening = true

        request = SFSpeechAudioBufferRecognitionRequest()
        guard let request = request else { return }

        let input = audioEngine.inputNode
        let format = input.outputFormat(forBus: 0)

        input.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
            request.append(buffer)
        }

        audioEngine.prepare()
        try? audioEngine.start()

        task = recognizer?.recognitionTask(with: request) { result, _ in
            if let text = result?.bestTranscription.formattedString {
                onResult(text)
            }
        }
    }

    func stopListening() {
        guard isListening else { return }

        isListening = false

        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)

        request?.endAudio()
        request = nil

        task?.cancel()
        task = nil
    }
}

import Foundation
import AVFoundation

/// Single-owner TTS with an internal queue so we never overlap utterances.
/// This avoids "multiple voices at once" and reduces the chance of AVAudio deadlocks.
@MainActor
final class SpeechOutputService: NSObject, AVSpeechSynthesizerDelegate {

    private let synthesizer = AVSpeechSynthesizer()

    private struct Item {
        let text: String
        let completion: (() -> Void)?
    }

    private var queue: [Item] = []
    private var isSpeaking: Bool = false

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    /// Enqueue speech. If already speaking, it will play after the current utterance finishes.
    func speak(_ text: String, completion: (() -> Void)? = nil) {
        queue.append(Item(text: text, completion: completion))
        if !isSpeaking {
            speakNext()
        }
    }

    /// Stop immediately and clear any queued utterances.
    func stopAll() {
        queue.removeAll()
        isSpeaking = false
        synthesizer.stopSpeaking(at: .immediate)
    }

    private func speakNext() {
        guard !queue.isEmpty else {
            isSpeaking = false
            return
        }

        isSpeaking = true
        let item = queue.removeFirst()

        print("Speaking: \(item.text)")

        let utterance = AVSpeechUtterance(string: item.text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")

        // Store completion on the utterance via associated object isn't worth it;
        // we just keep it as the "current" completion.
        currentCompletion = item.completion

        synthesizer.speak(utterance)
    }

    private var currentCompletion: (() -> Void)?

    // MARK: - AVSpeechSynthesizerDelegate

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer,
                                       didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            let cb = self.currentCompletion
            self.currentCompletion = nil
            cb?()

            // Continue any queued items
            self.speakNext()
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer,
                                       didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in
            // Treat cancel like finish so the queue can continue (unless stopAll cleared it).
            let cb = self.currentCompletion
            self.currentCompletion = nil
            cb?()
            self.speakNext()
        }
    }
}

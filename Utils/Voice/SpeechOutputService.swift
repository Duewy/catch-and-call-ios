import Foundation
import AVFoundation

final class SpeechOutputService: NSObject, AVSpeechSynthesizerDelegate, @unchecked Sendable {

    private let synthesizer = AVSpeechSynthesizer()
    private var onFinish: (() -> Void)?

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    /// Speak text (always hops to MainActor)
    func speak(_ text: String, completion: (() -> Void)? = nil) {
        Task { @MainActor in
            self.onFinish = completion
            print("Speaking: \(text)")
            let utterance = AVSpeechUtterance(string: text)
            utterance.voice = AVSpeechSynthesisVoice(language: "en-US")

            self.synthesizer.speak(utterance)
        }
    }

    /// Obj-C delegate callback (nonisolated by definition)
    nonisolated func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer,
        didFinish utterance: AVSpeechUtterance
    ) {
        Task { @MainActor in
            let cb = self.onFinish
            self.onFinish = nil
            cb?()
        }
    }
}

//
//  VoiceSessionManager.swift
//  CatchAndCall
//
//  Created by Dwayne Brame on 2026-01-07.
//

import Foundation
import Combine 
import AVFoundation
import MediaPlayer

@MainActor
final class VoiceSessionManager: ObservableObject {

    enum State {
        case idle
        case armed
        case listening
        case confirming
    }

    @Published private(set) var state: State = .idle

    private let speech = SpeechService()
    private let speaker = SpeechOutputService()

    init() {
        configureAudioSession()
        beginReceivingRemoteCommands()
    }

    // MARK: - Public API

    func armVoiceControl() {
        guard state == .idle else { return }
        state = .armed
        speaker.speak("Voice control ready. Press play to start. Over.")
    }

    func handlePlayPause() {
        switch state {
        case .armed:
            startListening()
        case .listening:
            stopListening()
        default:
            break
        }
    }

    // MARK: - Voice Flow

    private func startListening() {
        state = .listening
        speaker.speak("Say your catch. Over.") {
            self.speech.startListening { transcript in
                self.handleTranscript(transcript)
            }
        }
    }

    private func stopListening() {
        speech.stopListening()
        state = .armed
    }

    private func handleTranscript(_ raw: String) {
        let trimmed = trimAfterOver(raw)

        // TODO: hook in your parser here
        // parseCatch(trimmed)

        state = .confirming
        speaker.speak("Is that correct? Say yes over or no over.") {
            self.speech.startListening { confirm in
                self.handleConfirmation(confirm)
            }
        }
    }

    private func handleConfirmation(_ text: String) {
        let clean = text.lowercased()

        if clean.contains("yes") {
            // TODO: save catch
            speaker.speak("Catch saved. Over and out.")
        } else {
            speaker.speak("Okay. Let's try again. Over.")
        }

        state = .armed
    }

    // MARK: - Helpers

    private func trimAfterOver(_ text: String) -> String {
        let lower = text.lowercased()
        if let range = lower.range(of: " over") {
            return String(text[..<range.lowerBound]).trimmingCharacters(in: .whitespaces)
        }
        return text
    }

    // MARK: - Audio + Remote Controls

    private func configureAudioSession() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(
            .playAndRecord,
            mode: .voiceChat,
            options: [.allowBluetooth, .allowBluetoothA2DP]
        )
        try? session.setActive(true)
    }

    private func beginReceivingRemoteCommands() {
        let center = MPRemoteCommandCenter.shared()

        center.playCommand.isEnabled = true
        center.pauseCommand.isEnabled = true

        center.playCommand.addTarget { [weak self] _ in
            self?.handlePlayPause()
            return .success
        }

        center.pauseCommand.addTarget { [weak self] _ in
            self?.handlePlayPause()
            return .success
        }
    }
}


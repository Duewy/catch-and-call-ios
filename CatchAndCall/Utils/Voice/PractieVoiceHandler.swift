//
//  PracticeVoiceHandler.swift
//  CatchAndCall
//
//  Stub handler for practice voice sessions.
//  Real logic will be added later.
//

import Foundation

@MainActor
final class PracticeVoiceHandler {

    private unowned let coordinator: VoiceSessionCoordinator
    private let voiceManager: VoiceManager
    private let tts: SpeechOutputService

    init(
        coordinator: VoiceSessionCoordinator,
        voiceManager: VoiceManager,
        tts: SpeechOutputService
    ) {
        self.coordinator = coordinator
        self.voiceManager = voiceManager
        self.tts = tts
    }

    func start() {
        print("🧪 PracticeVoiceHandler.start() (stub)")
        coordinator.transition(to: .listening)
    }

    func shutdown() {
        print("🧪 PracticeVoiceHandler.shutdown() (stub)")
    }
}

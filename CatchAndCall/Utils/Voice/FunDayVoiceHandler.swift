//
//  FunDayVoiceHandler.swift
//  CatchAndCall
//
//  Stub handler for Fun Day voice sessions.
//  Real logic will be added later.
//

import Foundation

@MainActor
final class FunDayVoiceHandler {

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
        print("🎣 FunDayVoiceHandler.start() (stub)")
        coordinator.transition(to: .listening)
    }

    func shutdown() {
        print("🎣 FunDayVoiceHandler.shutdown() (stub)")
    }
}

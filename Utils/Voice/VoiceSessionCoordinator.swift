//
//  VoiceSessionCoordinator.swift
//  CatchAndCall
//
//  Created by Dwayne Brame on 2026-01-07.
//

import Foundation
import Foundation
import SwiftUI
import Combine

@MainActor
final class VoiceSessionCoordinator: ObservableObject {

    // MARK: - Session State

    enum SessionState {
        case idle
        case prompting
        case listening
        case confirming
        case questionMode
        case finished
    }

    @Published private(set) var state: SessionState = .idle

    // Prevent overlapping sessions (Android sessionActive equivalent)
    private var sessionActive: Bool = false

    // Voice engine (already built)
    private let voiceManager: VoiceManager

    // Tournament handler (we will build next)
    private var tournamentHandler: TournamentVoiceHandler?

    // MARK: - Init

    init(voiceManager: VoiceManager) {
        self.voiceManager = voiceManager
    }

    // MARK: - Public Entry Point (Tournament VCC)

    // MARK: - DEBUG / TESTING ONLY

    func debugInjectTranscript(_ text: String) {
        print("🟨 DEBUG transcript received:", text)
        tournamentHandler?.debugInjectTranscript(text)
    }

    
    func startTournamentSession() {
        print("🟦 startTournamentSession() called")

        guard !sessionActive else {
            print("⛔️ Voice session already active — ignoring request")
            return
        }
        print("🟦 Creating TournamentVoiceHandler")
        sessionActive = true
        state = .prompting

        print("🎙️ Starting Tournament Voice Session")

        tournamentHandler = TournamentVoiceHandler(
            coordinator: self,
            voiceManager: voiceManager
        )

        tournamentHandler?.start()
    }

    // MARK: - Session Control

    func transition(to newState: SessionState) {
        print("🔁 Session state: \(state) → \(newState)")
        state = newState
    }

    func endSession(reason: String = "completed") {
        print("✅ Ending voice session — reason: \(reason)")
        state = .finished
        sessionActive = false

        tournamentHandler?.shutdown()
        tournamentHandler = nil

        // Reset back to idle after cleanup
        state = .idle
    }
}

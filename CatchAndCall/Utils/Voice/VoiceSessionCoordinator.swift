//
//  VoiceSessionCoordinator.swift
//  CatchAndCall
//
//  Runtime authority for a single active voice session.
//  Owns audio session, audio engine lifecycle, and handler selection.
//

import Foundation
import SwiftUI
import Combine
import AVFoundation

@MainActor
final class VoiceSessionCoordinator: ObservableObject {

    // MARK: - Session State (UI-facing)

    enum SessionState {
        case idle
        case prompting
        case listening
        case confirming
        case questionMode
        case finished
    }
           
    @Published private(set) var state: SessionState = .idle

    // MARK: - Internal Session Control

    private var sessionActive: Bool = false
    private var mode: VoiceSessionMode?

    // MARK: - Shared Infrastructure (single owners)

    private let tts = SpeechOutputService()
    private let voiceManager: VoiceManager
    private let audioEngine = AVAudioEngine()

    // MARK: - Handlers (only ONE is active at a time)

    private var practiceHandler: PracticeVoiceHandler?
    private var fundayHandler: FunDayVoiceHandler?
    private var tournamentHandler: TournamentVoiceHandler?
    
    // MARK: - Expose Recognition State to Views

    var isListening: Bool { voiceManager.isListening }

    var liveTranscription: String { voiceManager.liveTranscription}

    var lastRecognizedText: String? { voiceManager.lastRecognizedText}

    
    // MARK: - Permissions

    func requestPermissions() async {
        await voiceManager.requestPermissions()
    }

    

    // MARK: - Init

    init(voiceManager: VoiceManager) {
        self.voiceManager = voiceManager
    }

    // MARK: - Public Entry Point

    func startListening(onResult: @escaping (String) -> Void) {
        transition(to: .listening)
        voiceManager.startRecognition(onResult: onResult)
    }

    func stopListening() {
        voiceManager.stopRecognition()
    }

    
    func startSession(mode: VoiceSessionMode) {
        guard !sessionActive else {
            print("⛔️ Voice session already active")
            return
        }

        // 1️⃣ Accept the session request
        self.mode = mode
        self.sessionActive = true
        self.state = .prompting
        print("🎙️ Voice Session Coordinator starting")
        // 2️⃣ Configure audio session FIRST
        configureAudioSession(for: mode)

        // 3️⃣ Now check Bluetooth (route is valid at this point)
        guard ensureBluetoothIfNeeded(for: mode) else {
            print("⛔️ Bluetooth input not active after session config")
            endSession(reason: "bluetooth not ready")
            return
        }

        // 4️⃣ Start audio engine
        startAudioEngine()

        // 5️⃣ Start the appropriate handler
        switch mode {
        case .practice:
            print("🎯 Starting Practice Voice Handler")
            startPracticeHandler()
        case .funday:
            print("🎉 Starting Fun Day Voice Handler")
            startFunDayHandler()
        case .tournament:
            print("🏆 Starting Tournament Voice Handler")
            startTournamentHandler()
        }
    }


    // MARK: - State Transitions (called by handlers)

    func transition(to newState: SessionState) {
        print("🔁 Session state:", state, "→", newState)
        state = newState
    }

    // MARK: - Session End (single exit path)

    func endSession(reason: String) {
        print("✅ Ending voice session — reason:", reason)

        practiceHandler?.shutdown()
        fundayHandler?.shutdown()
        tournamentHandler?.shutdown()

        practiceHandler = nil
        fundayHandler = nil
        tournamentHandler = nil

        stopAudioEngine()
        deactivateAudioSession()

        mode = nil
        sessionActive = false
        state = .idle
    }

    // MARK: - Handler Starters

    private func startPracticeHandler() {
        practiceHandler = PracticeVoiceHandler(
            coordinator: self,
            voiceManager: voiceManager,
            tts: tts
        )
        practiceHandler?.start()
    }

    private func startFunDayHandler() {
        fundayHandler = FunDayVoiceHandler(
            coordinator: self,
            voiceManager: voiceManager,
            tts: tts
        )
        fundayHandler?.start()
    }

    private func startTournamentHandler() {
        tournamentHandler = TournamentVoiceHandler(
            coordinator: self,
            voiceManager: voiceManager,
            tts: tts
        )
        print("🎉 Starting tournament voice handler, STEP 2")   
        tournamentHandler?.start()
    }

    // MARK: - Audio Lifecycle (SOLE OWNER)

    private func configureAudioSession(for mode: VoiceSessionMode) {
        let session = AVAudioSession.sharedInstance()

        do {
            switch mode {
            case .practice:
                try session.setCategory(
                    .playAndRecord,
                    mode: .spokenAudio,
                    options: [.defaultToSpeaker]
                )

            case .funday, .tournament:
                try session.setCategory(
                    .playAndRecord,
                    mode: .voiceChat,
                    options: [.allowBluetoothHFP]
                )
            }

            try session.setPreferredSampleRate(16000)
            try session.setPreferredIOBufferDuration(0.02)
            try session.setActive(true)

            print("🎧 audio route:", session.currentRoute)
        } catch {
            print("❌ Audio session configuration failed:", error.localizedDescription)
        }
    }

    private func startAudioEngine() {
        guard !audioEngine.isRunning else { return }

        let inputNode = audioEngine.inputNode
        let format = inputNode.inputFormat(forBus: 0)

        guard format.sampleRate > 0, format.channelCount > 0 else {
            print("⛔️ Invalid input format — aborting tap install")
            return
        }

        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) {
            [weak self] buffer, _ in
            self?.voiceManager.appendAudioBuffer(buffer)
        }

        print("🎤 Mic tap installed")

        do {
            audioEngine.prepare()
            try audioEngine.start()
            print("🔊 Audio engine started")
        } catch {
            print("❌ Failed to start audio engine:", error.localizedDescription)
        }
    }

    private func stopAudioEngine() {
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
            print("🛑 Audio engine stopped")
        }
    }

    private func deactivateAudioSession() {
        let session = AVAudioSession.sharedInstance()
        try? session.setActive(false, options: .notifyOthersOnDeactivation)
        print("🎚️ Audio session deactivated")
    }

    // MARK: - Bluetooth Enforcement

    private func ensureBluetoothIfNeeded(for mode: VoiceSessionMode) -> Bool {
        guard mode != .practice else { return true }

        let route = AVAudioSession.sharedInstance().currentRoute
        return route.inputs.contains { $0.portType == .bluetoothHFP }
    }

    // MARK: - DEBUG

    func debugInjectTranscript(_ text: String) {
        tournamentHandler?.debugInjectTranscript(text)
    }
}

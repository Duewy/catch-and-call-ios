//
//  VoiceControlManager.swift
//  CatchAndCall
//
//  Created by Dwayne Brame on 2026-01-08.
//

import Foundation


enum VoiceMode {
    case funDay
    case tournament
}

enum VoiceMeasurement {
    case lbsOzs
    case pounds
    case kgs
    case inches
    case centimeters
}

@MainActor
final class VoiceControlManager {
    static let shared = VoiceControlManager()

    private(set) var isArmed = false
    private(set) var voiceMode: VoiceMode?
    private(set) var measurement: VoiceMeasurement?

    func start(mode: VoiceMode, measurement: VoiceMeasurement) {
        self.voiceMode = mode
        self.measurement = measurement
        self.isArmed = true
        print("Voice control started")
        // ✅ No audio session / remote binding here
    }

    func stop() {
        isArmed = false
        voiceMode = nil
        measurement = nil

        // ✅ No audio session / remote unbinding here
    }
}

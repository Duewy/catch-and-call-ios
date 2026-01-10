//
//  SilentAudioAnchor.swift
//  CatchAndCall
//
//  Created by Dwayne Brame on 2026-01-07.
//

import Foundation
import AVFoundation

final class SilentAudioAnchor {
        //TODO: is this file required???
    static let shared = SilentAudioAnchor()
    private var player: AVAudioPlayer?

    private init() {}

    func start() {
        guard player == nil else { return }

        // 0.1s of silence embedded in code
        let silence: [UInt8] = [
            0x52,0x49,0x46,0x46,0x24,0x00,0x00,0x00,0x57,0x41,0x56,0x45,
            0x66,0x6D,0x74,0x20,0x10,0x00,0x00,0x00,0x01,0x00,0x01,0x00,
            0x40,0x1F,0x00,0x00,0x40,0x1F,0x00,0x00,0x01,0x00,0x08,0x00,
            0x64,0x61,0x74,0x61,0x00,0x00,0x00,0x00
        ]

        do {
            player = try AVAudioPlayer(data: Data(silence))
            player?.numberOfLoops = -1
            player?.volume = 0.0
            player?.play()
            print("🔈 Silent audio anchor started")
        } catch {
            print("❌ Silent audio anchor failed:", error)
        }
    }

    func stop() {
        player?.stop()
        player = nil
        print("🔇 Silent audio anchor stopped")
    }
}

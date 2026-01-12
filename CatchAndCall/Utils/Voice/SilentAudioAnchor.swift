//
//  SilentAudioAnchor.swift
//  CatchAndCall
//
//  Created by Dwayne Brame on 2026-01-07.
//

import Foundation
import AVFoundation



final class SilentAudioAnchor {
static let shared = SilentAudioAnchor()
private var player: AVAudioPlayer?

func start() {
    guard player == nil else { return }

    guard let url = Bundle.main.url(forResource: "silence_0_1s", withExtension: "m4a") else {
        print("❌ silence file not found")
        return
    }

    do {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playback, mode: .default)
        try session.setActive(true)

        player = try AVAudioPlayer(contentsOf: url)
        player?.numberOfLoops = -1   // loop forever
        player?.volume = 0.0
        player?.play()

        print("🔇 Silent audio anchor playing")
    } catch {
        print("❌ Silent audio anchor failed:", error)
    }
}

func stop() {
    player?.stop()
    player = nil
    print("🔊 Silent audio anchor stopped")
}
}

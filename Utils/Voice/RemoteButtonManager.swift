//
//  RemoteButtonManager.swift
//  CatchAndCall
//
//  Created by Dwayne Brame on 2026-01-08.
//

import Foundation
import AVFoundation
import MediaPlayer

extension Notification.Name {
    static let remotePlayPausePressed = Notification.Name("remotePlayPausePressed")
}

/// Owns the iOS “who gets the headset Play/Pause button” behavior.
/// Uses a silent audio engine so iOS routes remote commands to us reliably.
@MainActor
final class RemoteButtonManager {
    static let shared = RemoteButtonManager()

    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private var isRunning = false

    private init() {}

    func start() {
      /*  guard !isRunning else { return }
        isRunning = true
        print("RemoteButtonManager.start()")

        // Audio session is owned by VoiceSessionManager
        VoiceSessionManager.shared.ensureAudioSessionActive()

        // 1) Start silent “playback” so remote buttons route to us
        startSilentEngine()

        // 2) Advertise “Now Playing”
        MPNowPlayingInfoCenter.default().nowPlayingInfo = [
            MPMediaItemPropertyTitle: "Catch and Call",
            MPMediaItemPropertyArtist: "Tournament Mode"
        ]
        if #available(iOS 13.0, *) {
            MPNowPlayingInfoCenter.default().playbackState = .playing
        }

        // 3) Hook Play/Pause
        let cc = MPRemoteCommandCenter.shared()
        cc.playCommand.isEnabled = false
        cc.pauseCommand.isEnabled = false

        cc.togglePlayPauseCommand.isEnabled = true
        cc.togglePlayPauseCommand.removeTarget(nil)
        cc.togglePlayPauseCommand.addTarget { _ in
            NotificationCenter.default.post(name: .remotePlayPausePressed, object: nil)
            return .success
                }
       */   }


    func stop() {
        guard isRunning else { return }
        isRunning = false
        print("RemoteButtonManager.stop()")
        MPRemoteCommandCenter.shared().togglePlayPauseCommand.removeTarget(nil)

        engine.stop()
        engine.reset()

        // Audio session deactivation is handled by VoiceSessionManager
    }

    private func startSilentEngine() {
        print("RemoteButtonManager.startSilentEngine()")
        // Build a silent PCM buffer and loop it forever.
        let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1)!
        let frameCount: AVAudioFrameCount = 44_100 // 1 second of silence
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)!
        buffer.frameLength = frameCount

        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: format)

        // Ensure truly silent
        engine.mainMixerNode.outputVolume = 0.0

        do {
            try engine.start()
            player.play()

            // scheduleBuffer loop
            player.scheduleBuffer(buffer, at: nil, options: .loops, completionHandler: nil)
        } catch {
            print("❌ Silent engine start failed:", error)
        }
    }
}


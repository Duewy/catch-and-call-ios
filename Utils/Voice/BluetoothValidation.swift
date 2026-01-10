//
//  BluetoothValidation.swift
//  CatchAndCall
//
//  Created by Dwayne Brame on 2026-01-07.
//

import Foundation
import AVFoundation
import UIKit


enum BluetoothValidation {

    static func hasValidBluetoothMic(completion: @escaping (Bool) -> Void) {
        let session = AVAudioSession.sharedInstance()
            print("Checking mic permissions")
        // 1️⃣ Ensure mic permission
        switch AVAudioSession.sharedInstance().recordPermission {
        case .granted:
            checkRoute(session, completion: completion)

        case .undetermined:
            session.requestRecordPermission { granted in
                DispatchQueue.main.async {
                    if granted {
                        checkRoute(session, completion: completion)
                    } else {
                        completion(false)
                    }
                }
            }

        case .denied:
            completion(false)

        @unknown default:
            completion(false)
        }
    }

    private static func checkRoute(
        _ session: AVAudioSession,
        completion: @escaping (Bool) -> Void
    ) {
        // Audio session is already configured by the caller (VoiceManager)
        let route = session.currentRoute

        for input in route.inputs {
            if input.portType == .bluetoothHFP || input.portType == .bluetoothLE {
                completion(true)
                return
            }
        }

        completion(false)
    }

}//=== END ===

//MARK: >>>>> Create One Transport Hook  <<<<<<<
import MediaPlayer
import UIKit

enum VCRemoteTransport {

    static func bindPlayPause(start: @escaping () -> Void) {
        UIApplication.shared.beginReceivingRemoteControlEvents()
        print("🎧 Setting up remote play/pause")
        // ✅ Tell iOS "we are the now playing app"
        MPNowPlayingInfoCenter.default().nowPlayingInfo = [
            MPMediaItemPropertyTitle: "Catch & Call Voice Control",
            MPNowPlayingInfoPropertyIsLiveStream: true,
            MPNowPlayingInfoPropertyPlaybackRate: 1.0
        ]

        let center = MPRemoteCommandCenter.shared()

        // Clean slate
        center.playCommand.removeTarget(nil)
        center.pauseCommand.removeTarget(nil)
        center.togglePlayPauseCommand.removeTarget(nil)

        center.playCommand.isEnabled = true
        center.pauseCommand.isEnabled = true
        center.togglePlayPauseCommand.isEnabled = true

        center.playCommand.addTarget { _ in
            print("▶️ Remote play")
            start()
            return .success
        }

        center.pauseCommand.addTarget { _ in
            print("⏸ Remote pause")
            start()
            return .success
        }

        // 🔑 Many headsets only send TOGGLE    TODO: may need to lock down a function for single tap
        center.togglePlayPauseCommand.addTarget { _ in
            print("⏯ Remote toggle")
            start()
            return .success
        }
        print("🎛 VCRemoteTransport bound (play/pause/toggle)")
    }

    static func unbind() {
        let center = MPRemoteCommandCenter.shared()
        center.playCommand.removeTarget(nil)
        center.pauseCommand.removeTarget(nil)
        center.togglePlayPauseCommand.removeTarget(nil)

        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
        UIApplication.shared.endReceivingRemoteControlEvents()
        print("🎛 VCRemoteTransport unbound")
    }
}





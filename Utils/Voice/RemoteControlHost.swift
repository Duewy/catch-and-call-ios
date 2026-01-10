//
//  RemoteControlHost.swift
//  CatchAndCall
//
//  Created by Dwayne Brame on 2026-01-07.
//

import Foundation
import UIKit

final class RemoteControlHost: UIViewController {

    var onPlayPause: (() -> Void)?

    override var canBecomeFirstResponder: Bool { true }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        becomeFirstResponder()
        UIApplication.shared.beginReceivingRemoteControlEvents()
        print("🎮 RemoteControlHost became first responder")
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        resignFirstResponder()
        UIApplication.shared.endReceivingRemoteControlEvents()
        print("🎮 RemoteControlHost resigned first responder")
    }

    override func remoteControlReceived(with event: UIEvent?) {
        guard let event else { return }

        switch event.subtype {
        case .remoteControlPlay,
             .remoteControlPause,
             .remoteControlTogglePlayPause:
            print("🎮 RemoteControlHost Play/Pause")
            onPlayPause?()
        default:
            break
        }
    }
}

//
//  RemoteControlContainer.swift
//  CatchAndCall
//
//  Created by Dwayne Brame on 2026-01-07.
//

import Foundation
import SwiftUI

struct RemoteControlContainer: UIViewControllerRepresentable {

    let onPlayPause: () -> Void

    func makeUIViewController(context: Context) -> RemoteControlHost {
        let vc = RemoteControlHost()
        vc.onPlayPause = onPlayPause
        print("🎧makeUIViewController")
        return vc

    }

    func updateUIViewController(_ uiViewController: RemoteControlHost, context: Context) {
        uiViewController.onPlayPause = onPlayPause
        print("🎧updateUIViewController")
    }
}

//
//  VoiceEnabledCatchEntry.swift
//  CatchAndCall
//
//  Created by Dwayne Brame on 2026-01-08.
//

import Foundation
import SwiftUI

/// Enables Voice Control for any active CatchEntry page.
/// Assumes VoiceControlManager was already started from SetUpView.
struct VoiceEnabledCatchEntry: ViewModifier {

    @EnvironmentObject private var settings: SettingsStore

    let onVoiceTrigger: () -> Void

    func body(content: Content) -> some View {
        content
            // React to Play / Pause
            .onReceive(
                NotificationCenter.default.publisher(
                    for: .remotePlayPausePressed
                )
            ) { _ in
                guard settings.voiceControlEnabled else { return }
                onVoiceTrigger()
            }

            // Stop VC when leaving ANY CatchEntry page
            .onDisappear {
                VoiceControlManager.shared.stop()
            }
    }
}

extension View {
    func voiceEnabledCatchEntry(
        onVoiceTrigger: @escaping () -> Void
    ) -> some View {
        modifier(
            VoiceEnabledCatchEntry(onVoiceTrigger: onVoiceTrigger)
        )
    }
}

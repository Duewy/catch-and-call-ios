//
//  VCCHomeView.swift
//  CatchAndCall
//
//  Created by Dwayne Brame on 2026-01-02.
//

import Foundation
import SwiftUI

struct VCCHomeView: View {
    
    @StateObject private var voiceCoordinator =
           VoiceSessionCoordinator(voiceManager: VoiceManager())
    
    var body: some View {

        VStack(spacing: 20) {

            // Title
            Text("Voice Communication Controls")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.black)
                .padding(.top, 20)

            Text("Learn and practice voice commands before enabling live voice control.")
                .font(.system(size: 16))
                .foregroundColor(.black)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)

            Spacer()

            // Learn VCC
            NavigationLink {
                VCCLearnView()
            } label: {
                Text("Learn How to Use VCC")
                    .font(.system(size: 20, weight: .bold))
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 20)

            // Practice VCC
            NavigationLink {
                VCCPracticeSessionView(coordinator: voiceCoordinator)
            } label: {
                Text("Practice with VCC")
                    .font(.system(size: 20, weight: .bold))
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .background(Color.green)
                    .foregroundColor(.black)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 20)


            Spacer()

            // Footer note
            Text("Live Voice Control is enabled later from Setup once training is complete.")
                .font(.system(size: 14))
                .foregroundColor(.black)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
        }
        .background(Color.softlockSand.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            print("📺 VCCHomeView appeared")
        }
    }
}

#Preview {
    NavigationStack {
        VCCHomeView()
    }
}

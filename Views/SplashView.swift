//
//  SplashView.swift
//  CatchAndCall
//
//  Created by Dwayne Brame on 2025-11-12.
//
//  With Delay to allow app to load approperiate Advertisements


import SwiftUI

struct SplashView: View {
    @State private var go = false

    // MARK: - Edition Detection
    private var appEdition: String {
        Bundle.main.object(forInfoDictionaryKey: "APP_EDITION") as? String ?? "tracker"
    }

    private var splashImageName: String {
        switch appEdition {
        case "free":
            return "Image_Catch_And_Call_Free"
        case "tracker":
            return "Image_Catch_And_Call_Tracker"
        case "pro_vcc":
            return "Image_Catch_And_Call_Pro_VCC"
        default:
            return "Image_Catch_And_Call_Tracker"
        }
    }

    private var splashTitle: String {
        switch appEdition {
        case "free":
            return "Catch and Call\nFree Edition"
        case "tracker":
            return "Catch and Call\nTracker"
        case "pro_vcc":
            return "Catch and Call\nTracker Pro\nVoice Control"
        default:
            return "Catch and Call"
        }
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [.black.opacity(0.85), .blue.opacity(0.6)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 16) {

                Image(splashImageName)
                    .resizable()
                    .scaledToFit()
                    .padding(.horizontal, 24)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .shadow(radius: 8)

                Text(splashTitle)
                    .font(.largeTitle.weight(.heavy))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                Text("Log • Cull • Win")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.9))
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
                go = true
            }
        }
        .navigationDestination(isPresented: $go) {
            MainMenuView()
        }
    }
}

#Preview {
    SplashView()
}


//
//  MainMenuView.swift
//  CatchAndCall
//
//  Created by Dwayne Brame on 2025-11-12.
//
//

import SwiftUI

struct MainMenuView: View {
    
    // MARK: - Edition Detection
    private var appEdition: String {
        Bundle.main.object(forInfoDictionaryKey: "APP_EDITION") as? String ?? "tracker"
    }

    private var ImageName: String {
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
    
    @State private var showVCCProAlert = false

    
    var body: some View {


        ScrollView {
            VStack(spacing: 0) {
                
                // --- App Icon ---
                Image(ImageName)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 20)
                
                // --- Menu Buttons ---
                VStack(spacing: 0) {
                    menuButton(
                        title: "Set Up",
                        subtitle: "Species, GPS, tournament, preferences",
                        color: .green.opacity(0.8),
                        destination: SetUpView()
                    )
                    
                    Divider().frame(height: 4).background(Color.black)
                    
                    if #available(iOS 17.0, *) {
                        menuButton(
                            title: "Look Up / Share Data",
                            subtitle: "View or export catch history",
                            color: .blue.opacity(0.8),
                            destination: MapCatchLocationsView()
                        )
                    } else {
                        // Fallback on earlier versions
                    }
                    
                    Divider().frame(height: 4).background(Color.black)
                    
                    menuButton(
                        title: "User How To",
                        subtitle: "Informantion on setting up various components of the Catch and Call Tracker app",
                        color: .orange.opacity(0.8),
                        destination: HelpCenterView()
                    )
                    
                    Divider().frame(height: 4).background(Color.black)
                    
                        #if VCC_ENABLED
                        if appEdition == "pro_vcc" {
                            menuButton(
                                title: "Voice Communication Controls",
                                subtitle: "Voice-activated catch logging",
                                color: .yellow.opacity(0.8),
                                destination: VCCHomeView()
                            )
                        } else {
                            lockedVCCButton
                        }
                        #else
                        lockedVCCButton
                        #endif
                                                 

                    }
                }
        }
        .background(Color.halo_light_blue.ignoresSafeArea()) // background color
        .navigationTitle("Main Menu")
        
        .onAppear {
            print("📺 MainMenuView appeared")
        }
        
    }// === END - Body - ======
    
    // MARK: - Locked VCC Button (Non-VCC Editions)
    private var lockedVCCButton: some View {
        Button {
            showVCCProAlert = true
        } label: {
            VStack(spacing: 6) {
                Text("Voice Communication Controls")
                    .font(.headline)
                    .foregroundColor(.black)

                Text("Available in Tracker Pro-VC Edition")
                    .font(.subheadline)
                    .foregroundColor(.black)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.yellow.opacity(0.8))
            .multilineTextAlignment(.center)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.black, lineWidth: 2)
            )
            .cornerRadius(12)
        }
        .padding(.vertical, 10)
        .alert("Tracker Pro-VC Feature",
               isPresented: $showVCCProAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Voice Communication Controls are available in the Catch and Call Tracker Pro-VC Edition.")
        }
    }

    
    // MARK: - Menu Button Builder
    @ViewBuilder
    private func menuButton<T: View>(
        title: String,
        subtitle: String,
        color: Color,
        destination: T
    ) -> some View {
        NavigationLink {
            destination
        } label: {
            VStack(spacing: 6) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.black)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(Color.black)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(color)
            .multilineTextAlignment(.center)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.black, lineWidth: 2)
            )
            .cornerRadius(12)
        }
        .padding(.vertical, 10)
    }
    
}//==== END - MainMenuView - =======

#Preview {
    NavigationStack {
        MainMenuView()
    }
}

//
//  CatchAndCallApp.swift
//  CatchAndCall
//
//  Created by Dwayne Brame on 2025-11-12.
//
// Inital Page that the App Uses to Start everything
//  If required can use the RESET DB 
//

import SwiftUI

@main
struct CatchAndCallApp: App {
    @StateObject var settings   = SettingsStore()
    @StateObject var catchesVM  = CatchesViewModel()   // ✅ add this

    // ===== RESET THE DATABASE ==========
    /*
    init() {
        do {
            try DatabaseManager.shared.resetDatabase()
            try DatabaseManager.shared.openIfNeeded()
            print("✅ Database reset and recreated.")
        } catch {
            print("❌ Database reset failed:", error)
        }
    }
    */

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                SplashView() // start at Splash Page
            }
            .environmentObject(settings)      // SettingsStore for setup etc.
            .environmentObject(catchesVM)     // ✅ CatchesViewModel for all CatchEntry / Today views
        }
    }
}

#Preview {
    NavigationStack { SplashView() }
        .environmentObject(SettingsStore())
        .environmentObject(CatchesViewModel())   
}

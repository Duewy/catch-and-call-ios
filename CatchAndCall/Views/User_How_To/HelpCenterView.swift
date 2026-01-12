//
//  HelpCenterView.swift
//  CatchAndCall
//
//  Created by Dwayne Brame on 2025-11-19.
//
//
//  Central hub for all in-app Help / How-To topics.

import Foundation
import SwiftUI

struct HelpCenterView: View {
    var body: some View {
        ZStack {
            Color.softlockTeal.ignoresSafeArea()   // full background
            
            VStack(alignment: .leading, spacing: 12) {

                // --- Title Header ---
                Text("Help Center 📞 📝")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.softlockTeal)
                

                // --- Card-style List ---
                List {
                    Section(header: helpHeader("Logging Your Catch 🎣")) {
                        helpLink("Fun Day 🚤  – Logging Catches -",
                                 url: "https://raw.githubusercontent.com/Duewy/Catch_and_Call_Help_Files/main/Android_iOS_Fun_Day.pdf")
                                    
                        helpLink("Tournament 🏆 – Culling Catches -",
                                 url: "https://raw.githubusercontent.com/Duewy/Catch_and_Call_Help_Files/main/Android_iOS_Tournament.pdf")
                    }

                    Section(header: helpHeader("GPS📍")) {
                        helpLink("Setting Up GPS 🧭",
                                 url: "https://raw.githubusercontent.com/Duewy/Catch_and_Call_Help_Files/main/Android_iOS_Setup_GPS.pdf")
                    }
                    
                    Section(header: helpHeader("Species 🐠")) {
                        helpLink("Organizing Adding Species List 📝",
                                 url: "https://raw.githubusercontent.com/Duewy/Catch_and_Call_Help_Files/main/Android_iOS_Organize_Species_List.pdf")
                    }

                    Section(header: helpHeader("Mapping and Data Sharing 📊")) {
                        
                        helpLink("Mapping, Exporting, & Sharing \n CSV KLM files 📈",
                                 url: "https://raw.githubusercontent.com/Duewy/Catch_and_Call_Help_Files/main/iOS_Mapping_GPS.pdf")
                    }
                    Section(header: helpHeader("Privacy Policy ")) {
                        helpLink("Privacy Policy 📝",
                                 url: "https://raw.githubusercontent.com/Duewy/Catch_and_Call_Help_Files/main/Privacy_Policy.pdf")
                    }
                }
                .scrollContentBackground(.hidden)     // allows teal behind
                .background(Color.softlockTeal)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    // --- Reusable Section Header Style ---
    private func helpHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 22, weight: .bold))
            .foregroundColor(.black)
            .padding(.leading, -4)
    }

    // --- Reusable Help Link Row ---
    private func helpLink(_ title: String, url: String) -> some View {
        NavigationLink(destination:
            HelpPdfView(
                title: title,
                url: URL(string: url)!
            )
        ) {
            Text(title)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.black)
                .padding(.vertical, 6)
        }
        .listRowBackground(Color.white.opacity(0.55))
    }
}

#Preview {
    NavigationStack {
        HelpCenterView()
    }
}

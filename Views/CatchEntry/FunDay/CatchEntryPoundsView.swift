//
//  CatchEntryPoundsView.swift
//  CatchAndCall
//
//  Created by Dwayne Brame on 2025-10-31.
//

import Foundation
import SwiftUI
import UIKit
internal import _LocationEssentials

// =============================================================
// CatchEntryPoundsView.swift
// Catch entry using Pounds.hh (hundredths of pounds)
// =============================================================

struct AddCatchPoundsPopup: View {
    @Environment(\.dismiss) private var dismiss
    var speciesList: [String]
    var initialSpecies: String? = nil
    var initialWholeLb: Int? = nil
    var initialHundredths: Int? = nil
    var title: String = "Add Catch"

    @State private var selectedSpeciesIndex: Int = 0
    @State private var wholeText: String = ""
    @State private var hundText: String  = ""

    @State private var padTarget: NumberPad.Target = .pounds // left box (whole)
    let onSave: (_ species: String, _ whole: Int, _ hundredths: Int) -> Void

    private var parsedWhole: Int { Int(wholeText) ?? 0 }
    private var parsedHund:  Int { Int(hundText)  ?? 0 }

    private var canSave: Bool {
        let wOK = parsedWhole >= 0
        let hOK = (0...99).contains(parsedHund)
        return wOK && hOK && (parsedWhole * 100 + parsedHund) > 0
    }

    var body: some View {
       
        ZStack {
            Color.clipVeryGreen.ignoresSafeArea()
            
            VStack(spacing: 16) {
                HStack {
                    Text(title).font(.system(size: 24, weight: .bold))
                        .foregroundStyle(.black)
                    Spacer()
                    Button("Cancel")
                    { dismiss() }
                }
                // Species
                VStack(spacing: 6) {
                    Text("Species").font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity, alignment: .center)
                    Menu {
                        ForEach(speciesList.indices, id: \.self) { i in
                            Button {
                                selectedSpeciesIndex = i
                            } label: {
                                HStack {
                                    SpeciesIcon(species: speciesList[i], size: 30)
                                    Text(speciesList[i].lowercased())
                                        .foregroundStyle(.black)
                                    if i == selectedSpeciesIndex { Image(systemName: "checkmark") }
                                }
                            }
                        }
                    } label: {
                        HStack {
                            if !speciesList.isEmpty {
                                let safeIndex = min(selectedSpeciesIndex, speciesList.count - 1)

                                SpeciesIcon(species: speciesList[safeIndex], size: 60)
                                Text(speciesList[safeIndex].capitalized)
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundStyle(.black)
                            } else {
                                Text("No Species Selected")
                                    .foregroundStyle(.gray)
                            }

                            Spacer()
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.footnote)
                                .foregroundStyle(.black)
                        }
                        .padding(12)
                        .background(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.veryLiteGrey, lineWidth: 1))
                    }
                }

                // Inputs
                VStack(alignment: .center, spacing: 6) {
                    Text("Weight")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(.black)
                    HStack(spacing: 6) {
                        Text("Pounds")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.black)
                        Text("Hundredths (00–99)")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.black)
                    }.padding(.bottom, 4)

                    HStack(spacing: 6) {
                        Text(wholeText.isEmpty ? "0" : wholeText)
                            .font(.system(size: 30, weight: .semibold))
                            .foregroundStyle(.black)
                            .frame(width: 60, height: 40)
                            .background(padTarget == .pounds ? Color.white : Color.veryLiteGrey)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(padTarget == .pounds ? Color.clipVeryGreen : Color.veryLiteGrey, lineWidth: 2))
                            .onTapGesture { padTarget = .pounds; wholeText = "" }
                        Text("lb")
                            .font(.system(size: 30, weight: .semibold))
                            .foregroundStyle(.black)

                        Text(hundText.isEmpty ? "00" : hundText)
                            .font(.system(size: 30, weight: .semibold))
                            .foregroundStyle(.black)
                            .frame(width: 70, height: 40)
                            .background(padTarget == .ounces ? Color.white : Color.veryLiteGrey)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(padTarget == .ounces ? Color.clipVeryGreen : Color.veryLiteGrey, lineWidth: 2))
                            .onTapGesture { padTarget = .ounces; hundText = "" }
                        Text("hh")
                            .font(.system(size: 30, weight: .semibold))
                            .foregroundStyle(.black)
                    }

                    NumberPad(
                        text: padTarget == .pounds ? $wholeText : $hundText,
                        target: padTarget,
                        maxLen: padTarget == .pounds ? 3 : 2,
                        clampRange: (padTarget == .ounces) ? 0...99 : nil,
                        onDone: {}
                    )
                    .background(Color.softlockSand)
                }

                HStack {
                    Button {
                        let sp = speciesList[selectedSpeciesIndex]
                        let clamped = max(0, min(parsedHund, 99))
                        onSave(sp, parsedWhole, clamped)
                        dismiss()
                    } label: { Text("Save Catch").bold() }
                    .buttonStyle(.borderedProminent)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.black, lineWidth: 1)
                    )
                    .disabled(!canSave)
                }
            }
            .padding(16)
        }
        .onAppear {
               if let s = initialSpecies,
               let idx = speciesList.firstIndex(where: { $0.caseInsensitiveCompare(s) == .orderedSame }) {
                selectedSpeciesIndex = idx
            } else {
                selectedSpeciesIndex = min(selectedSpeciesIndex, max(0, speciesList.count - 1))
            }
            if let W = initialWholeLb { wholeText = String(W) }
            if let H = initialHundredths { hundText  = String(H) }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
}


// MARK: - Main View (Catch Entry – Pounds)
struct CatchEntryPoundsView: View {
    @EnvironmentObject var vm: CatchesViewModel
    @EnvironmentObject var settings: SettingsStore
    
    @State private var showingAddPopup = false
    @State private var editingItem: CatchItem? = nil
    @State private var confirmDelete: CatchItem? = nil

    // --- Active species list (from SpeciesUtils / UserDefaults) ---
    @State private var speciesList: [String] = []
    
    // Only show catches that actually have Pounds.hh stored
    private var poundsToday: [CatchItem] {
        vm.today.filter { ( $0.totalWeightPoundsHundredth ?? 0 ) > 0 &&
            ($0.catchType ?? "") == "Fun Day"
        }
    }


    var body: some View {
        VStack(spacing: 0) {
            if poundsToday.isEmpty {
                VStack(spacing: 12) {
                    Text("No catches yet today.")
                        .foregroundStyle(.black)
                    Button { showingAddPopup = true } label: { Label("Add a Catch", systemImage: "plus.circle.fill") }
                        .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    Section(header: Text("    Today's Catches")
                        .font(.headline)
                        .foregroundColor(.black)
                        .underline()) {
                        ForEach(poundsToday) { c in
                            CatchRowPounds(item: c)
                                .listRowBackground(Color.clear)
                                .foregroundStyle(.black)
                                .background(Color.clear)
                                .overlay(Rectangle().frame(height: 6).foregroundColor(.gray), alignment: .bottom)
                                .listRowSeparator(.hidden)
                                .swipeActions(edge: .trailing) {
                                    Button("Edit") { editingItem = c }.tint(.blue)
                                    Button(role: .destructive) {
                                        confirmDelete = c
                                    } label: { Label("Delete", systemImage: "trash") }
                                }
                                .onTapGesture { editingItem = c }
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .background(Color.clipVeryGreen)
                .alert(item: $confirmDelete) { item in
                    let totalHund = item.totalWeightPoundsHundredth ?? 0
                    let when = Date(timeIntervalSince1970: TimeInterval(item.dateTimeSec))
                    return Alert(
                        title: Text("Delete this catch?"),
                        message: Text("\(item.species.capitalized) – \(MeasureHelpers.formatPoundsHundredth(totalHund)) at \(when.formatted(date: .omitted, time: .shortened))"),
                        primaryButton: .destructive(Text("Delete")) { withAnimation { vm.deleteCatch(id: item.id) } },
                        secondaryButton: .cancel()
                    )
                }

                HStack {
                    Spacer()
                    if !poundsToday.isEmpty {
                        let totalCatches = poundsToday.count
                        let totHund = poundsToday.compactMap { $0.totalWeightPoundsHundredth }.reduce(0, +)

                        Text("Catches: \(totalCatches)").font(.subheadline).foregroundColor(.black)
                        Text("Total: \(MeasureHelpers.formatPoundsHundredth(totHund))").font(.subheadline).foregroundColor(.black)
                    }
                    Button { showingAddPopup = true } label: {
                        Label("Add a Catch", systemImage: "plus.circle.fill").font(.headline)                         }
                    .buttonStyle(.borderedProminent)
                    Spacer()
                    
                }
            }
            // === NAVIGATION BUTTONS (always visible at bottom) ===
                       HStack(spacing: 12) {
                           NavigationLink {
                               MainMenuView()
                           } label: {
                               Text("Main Page")
                                   .font(.system(size: 22, weight: .bold))
                                   .foregroundStyle(.black)
                                   .frame(height: 50)
                                   .frame(maxWidth: .infinity)
                                   .background(
                                       RoundedRectangle(cornerRadius: 10)
                                           .fill(Color.clipBrightGreen)
                                   )
                                   .overlay(
                                       RoundedRectangle(cornerRadius: 10)
                                           .stroke(Color.black, lineWidth: 1)
                                   )
                           }
                           .buttonStyle(.plain)

                           NavigationLink {
                               SetUpView()
                           } label: {
                               Text("Set Up Page")
                                   .font(.system(size: 22, weight: .bold))
                                   .foregroundStyle(.white)
                                   .frame(height: 50)
                                   .frame(maxWidth: .infinity)
                                   .background(
                                       RoundedRectangle(cornerRadius: 10)
                                           .fill(Color.blue)
                                   )
                                   .overlay(
                                       RoundedRectangle(cornerRadius: 10)
                                           .stroke(Color.black, lineWidth: 1)
                                   )
                           }
                           .buttonStyle(.plain)
                       }
                       .padding(.top, 10)
                       .padding(.horizontal, 16)
                   }
        
        .background(Color.clipVeryGreen)
        .onAppear { vm.reloadToday() }
        
        // EDIT
        .sheet(item: $editingItem) { item in
            let split: (Int, Int) = {
                if let h = item.totalWeightPoundsHundredth {
                    let a = abs(h)
                    return (a / 100, a % 100)
                } else {
                    return (0, 0)
                }
            }()

            AddCatchPoundsPopup(
                speciesList: speciesList,
                initialSpecies: item.species,
                initialWholeLb: split.0,
                initialHundredths: split.1,
                title: "Edit Catch"
            ) { species, whole, hundredths in
                vm.updateCatchPoundsHundredth(original: item, species: species, whole: whole, hundredths: hundredths)
            }
        }
        
        // -- ADD Catch Information PopUp ----
        .sheet(isPresented: $showingAddPopup) {
            AddCatchPoundsPopup(speciesList: speciesList) { species, whole, hundredths in
                // Check SetUp toggle (same idea as Lbs/Ozs page)
                if settings.gpsEnabled {
                    LocationService.shared.requestCoordinate { coordinate in
                        // If location lookup fails, just save without GPS
                        guard let coordinate = coordinate else {
                            vm.savePoundsHundredth(
                                species: species,
                                whole: whole,
                                hundredths: hundredths
                            )
                            return
                        }

                        let latE7 = Int(coordinate.latitude  * 10_000_000)
                        let lonE7 = Int(coordinate.longitude * 10_000_000)

                        vm.savePoundsHundredth(
                            species: species,
                            whole: whole,
                            hundredths: hundredths,
                            latE7: latE7,
                            lonE7: lonE7
                        )
                    }
                } else {
                    // GPS disabled in SetUp → save without lat/lon
                    vm.savePoundsHundredth(
                        species: species,
                        whole: whole,
                        hundredths: hundredths
                    )
                }
            }
        }

        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.clipVeryGreen, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.light, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack(spacing: 0) {
                    Text("Catch Entry")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundColor(.black)

                    Text("(Pounds)")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.black)
                    
                    statusBar // GPS and VCC Status
                }
                .multilineTextAlignment(.center)
            }
        }
        .onAppear {
            speciesList = SpeciesStorage.loadOrderedSpeciesList()
        }
    }
    // ---- Show GPS & VCC Status ---
    private var statusBar: some View {
        HStack(spacing: 24) {
            Text(settings.gpsEnabled ? "GPS ON" : "🚫 GPS")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(settings.gpsEnabled ? Color.red : Color.clipBlue)

            Text(settings.voiceControlEnabled ? "VCC ENABLED" : "MANUAL MODE")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(settings.voiceControlEnabled ? Color.clipOrange : Color.clipBlue)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 2)
    }

}//==== END body ==========


private struct CatchRowPounds: View {
    let item: CatchItem
    var body: some View {
        HStack(spacing: 22) {
            Spacer()
            SpeciesIcon(species: item.species, size: 85)
            VStack(alignment: .leading, spacing: 4) {
                Text(item.species.capitalized).font(.headline).foregroundStyle(.black)
                if let hLb = item.totalWeightPoundsHundredth {
                    Text(MeasureHelpers.formatPoundsHundredth(hLb)).font(.subheadline).foregroundStyle(.black)
                } else if let totOz = item.totalWeightOz {
                    let p = MeasureHelpers.lbsOz(fromTotalOz: totOz)
                    Text("\(p.lbs) lb \(p.oz) oz").font(.subheadline).foregroundStyle(.black)
                } else if let hKg = item.totalWeightHundredthKg {
                    Text(MeasureHelpers.formatKgsHundredth(hKg)).font(.subheadline).foregroundStyle(.black)
                }
                HStack(spacing: 6) {
                    let when = Date(timeIntervalSince1970: TimeInterval(item.dateTimeSec))
                    Text(when.formatted(date: .omitted, time: .shortened)).font(.caption).foregroundStyle(.black)
                   
                    let hasGPS = (item.latitudeE7 != nil && item.longitudeE7 != nil)
                    Image(hasGPS ? "map_icon_fun_day" : "map_icon_fall_back")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                        .opacity(hasGPS ? 1.0 : 0.65)
                        .accessibilityLabel(hasGPS ? Text("GPS recorded") : Text("GPS not recorded"))
                }
            }
            Spacer()
        }
    }
}


#Preview("Catch Entry (sample)") {
    NavigationStack {
        CatchEntryPoundsView()
            .environmentObject(CatchesViewModel())   // ✅ vm
            .environmentObject(SettingsStore())      // ✅ settings
    }
}



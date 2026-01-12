//
//  CatchEntryCentimetersView.swift
//  CatchAndCall
//
//  Created by Dwayne Brame on 2025-10-31.
//

import Foundation
import SwiftUI
import UIKit
internal import _LocationEssentials

// =============================================================
// CatchEntryCentimetersView.swift
// Catch entry using Centimeters.t (tenths of cm)
// =============================================================

struct AddCatchCentimetersPopup: View {
    @Environment(\.dismiss) private var dismiss
    var speciesList: [String]
    var initialSpecies: String? = nil
    var initialCm: Int? = nil
    var initialTenth: Int? = nil
    var title: String = "Add Catch"

    @State private var selectedSpeciesIndex: Int = 0
    @State private var cmText: String = ""
    @State private var tenthText: String  = ""

    @State private var padTarget: NumberPad.Target = .pounds
    let onSave: (_ species: String, _ cmWhole: Int, _ tenth: Int) -> Void

    private var parsedCm: Int { Int(cmText) ?? 0 }
    private var parsedTenth: Int { Int(tenthText) ?? 0 }

    private var canSave: Bool {
        let cOK = parsedCm >= 0
        let tOK = (0...9).contains(parsedTenth)
        return cOK && tOK && (parsedCm*10 + parsedTenth) > 0
    }

    var body: some View {
        ZStack {
            Color.softlockSand.ignoresSafeArea()
            VStack(spacing: 16) {
                HStack { Text(title)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(.black)
                     Spacer()
                    Button("Cancel") { dismiss() } .foregroundStyle(.black)}

                // --- User to Select Species -----
                VStack(spacing: 6) {
                    Text("Species")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity, alignment: .center)
                    // --- Species Selection Menu --------
                    Menu {
                        ForEach(speciesList.indices, id: \.self) { i in
                            Button { selectedSpeciesIndex = i } label: {
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
                            Image(systemName: "chevron.up.chevron.down").font(.footnote).foregroundStyle(.blue)
                        }
                        .padding(12).background(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.veryLiteGrey, lineWidth: 1))
                    }
                }

                // --- Popup User Input Values ---------
                VStack(alignment: .center, spacing: 6) {
                    Text("Length")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(.black)
                    HStack(spacing: 6) {
                        Text("Cm 0-999")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.black)
                        Text("mm (0–9)")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.black)
                    }.padding(.bottom, 4)

                    HStack(spacing: 6) {
                        Text(cmText.isEmpty ? "0" : cmText)
                            .font(.system(size: 30, weight: .semibold))
                            .foregroundStyle(.black)
                            .frame(width: 60, height: 40)
                            .background(padTarget == .pounds ? Color.white : Color.veryLiteGrey)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(padTarget == .pounds ? Color.softlockSand: Color.veryLiteGrey, lineWidth: 2))
                            .onTapGesture { padTarget = .pounds; cmText = "" }
                        Text(".")
                            .font(.system(size: 30, weight: .bold))
                            .foregroundStyle(.black)

                        Text(tenthText.isEmpty ? "0" : tenthText)
                            .font(.system(size: 30, weight: .semibold))
                            .foregroundStyle(.black)
                            .frame(width: 60, height: 40)
                            .background(padTarget == .ounces ? Color.white : Color.veryLiteGrey)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(padTarget == .ounces ? Color.softlockSand : Color.veryLiteGrey, lineWidth: 2))
                            .onTapGesture { padTarget = .ounces; tenthText = "" }
                        Text("Cm")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(.black)
                    }

                    NumberPad(
                        text: padTarget == .pounds ? $cmText : $tenthText,
                        target: padTarget,
                        maxLen: padTarget == .pounds ? 3 : 1,
                        clampRange: (padTarget == .ounces) ? 0...9 : nil,
                        onDone: {}
                    )
                    .background(Color.softlockSand)
                }

                HStack {
                    Button {
                        let sp = speciesList[selectedSpeciesIndex]
                        let clamped = max(0, min(parsedTenth, 9))
                        onSave(sp, parsedCm, clamped)
                        dismiss()
                    } label: { Text("Save Catch").bold() }
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.black, lineWidth: 2)
                        )
                    .buttonStyle(.borderedProminent)
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
            if let C = initialCm { cmText = String(C) }
            if let T = initialTenth { tenthText = String(T) }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Main View (Catch Entry – Centimeters)

struct CatchEntryCentimetersView: View {
    @EnvironmentObject var vm: CatchesViewModel
    @EnvironmentObject var settings: SettingsStore
    
    @State private var showingAddPopup = false
    @State private var editingItem: CatchItem? = nil
    @State private var confirmDelete: CatchItem? = nil

    // --- Active species list (from SpeciesUtils / UserDefaults) ---
    @State private var speciesList: [String] = []
   
    // Only catches that actually have centimeter length (Fun Day only)
    private var todayCm: [CatchItem] {
        vm.today.filter {
            ($0.totalLengthCm ?? 0) > 0 &&
            ($0.catchType ?? "") == "Fun Day"
        }
    }

    var body: some View {
        
        VStack(spacing: 0) {
            if todayCm.isEmpty {
                VStack(spacing: 12) {
                    Text("No catches yet today.")
                        .foregroundStyle(.black)
                    Button { showingAddPopup = true } label: {
                        Label("Add a Catch", systemImage: "plus.circle.fill")
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    Section(header:
                       Text("    Today's Catches")
                        .font(.headline)
                        .foregroundColor(.black)
                        .underline()
                    ) {
                        ForEach(todayCm) { c in        // 👈 use todayCm here
                            CatchRowCentimeters(item: c)
                                .listRowBackground(Color.clear)
                                .background(Color.clear)
                                .overlay(Rectangle().frame(height: 6).foregroundColor(.gray), alignment: .bottom)
                                .listRowSeparator(.hidden)
                                .swipeActions(edge: .trailing) {
                                    Button("Edit") { editingItem = c }
                                        .tint(.blue)
                                    Button(role: .destructive) {
                                        confirmDelete = c
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                                .onTapGesture { editingItem = c }
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .background(Color.softlockSand)
                
                //--- DELETE CATCH -------
                .alert(item: $confirmDelete) { item in
                    let totalT = item.totalLengthCm ?? 0
                    let when = Date(timeIntervalSince1970: TimeInterval(item.dateTimeSec))
                    return Alert(
                        title: Text("Delete this catch?"),
                        message: Text("\(item.species.capitalized) – \(MeasureHelpers.formatCentimeters(totalT)) at \(when.formatted(date: .omitted, time: .shortened))"),
                        primaryButton: .destructive(Text("Delete")) { withAnimation { vm.deleteCatch(id: item.id) } },
                        secondaryButton: .cancel()
                    )
                }
                
                HStack {
                    Spacer()
                    //---- Total Listing for Today's Catch
                    if !todayCm.isEmpty {
                        let totalCatches = todayCm.count
                        let totT = todayCm.compactMap { $0.totalLengthCm }.reduce(0, +)
                        Text("Catches: \(totalCatches)")
                            .font(.subheadline)
                            .foregroundColor(.black)
                        Text("Total: \(MeasureHelpers.formatCentimeters(totT))")
                            .font(.subheadline)
                            .foregroundColor(.black)
                    }
                    //-- ADD CATCH Button -------
                    Button { showingAddPopup = true } label: {
                        Label("Add a Catch", systemImage: "plus.circle.fill").font(.headline)
                    }.buttonStyle(.borderedProminent)
                    Spacer()
                }
            }
            
            
            // === NAVIGATION BUTTONS (MAIN & SETUP) ===
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
                                .stroke(Color.black, lineWidth: 2)
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
                                .stroke(Color.black, lineWidth: 2)
                        )
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 10)
            .padding(.horizontal, 16)
            
        }
        .background(Color.softlockSand)
        .onAppear { vm.reloadToday() }
        
        //--- EDIT CATCH ENTRY ---
        .sheet(item: $editingItem) { item in
            let split: (Int, Int) = {
                if let t = item.totalLengthCm {
                    let a = abs(t)
                    return (a / 10, a % 10)
                } else {
                    return (0, 0)
                }
            }()
            
            AddCatchCentimetersPopup(
                speciesList: speciesList,
                initialSpecies: item.species,
                initialCm: split.0,
                initialTenth: split.1,
                title: "Edit Catch"
            ) { species, wholeCm, tenth in
                vm.updateCatchCentimeters(original: item, species: species, wholeCm: wholeCm, tenth: tenth)
            }
        }
        // -- ADD a CATCH Information ----
        
        .sheet(isPresented: $showingAddPopup) {
            AddCatchCentimetersPopup(speciesList: speciesList) { species, wholeCm, tenth in
                // Check SetUp toggle (same idea as Lbs/Ozs, Kgs, Inches)
                if settings.gpsEnabled {
                    // Ask LocationService for a coordinate
                    LocationService.shared.requestCoordinate { coordinate in
                        // If location lookup fails, just save without GPS
                        guard let coordinate = coordinate else {
                            vm.saveCentimeters(
                                species: species,
                                wholeCm: wholeCm,
                                tenth: tenth
                            )
                            return
                        }
                        
                        let latE7 = Int(coordinate.latitude  * 10_000_000)
                        let lonE7 = Int(coordinate.longitude * 10_000_000)
                        
                        vm.saveCentimeters(
                            species: species,
                            wholeCm: wholeCm,
                            tenth: tenth,
                            latE7: latE7,
                            lonE7: lonE7
                        )
                    }
                } else {
                    // GPS disabled in SetUp → save without lat/lon
                    vm.saveCentimeters(
                        species: species,
                        wholeCm: wholeCm,
                        tenth: tenth
                    )
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.softlockSand, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.light, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack(spacing: 0) {
                    Text("Catch Entry")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundColor(.black)

                    Text("(Centimeters)")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.black)

                    statusBar   // GPS / VCC status
                }
                .multilineTextAlignment(.center)
            }
        }
        .onAppear {
            speciesList = SpeciesStorage.loadOrderedSpeciesList()
        }
    }//=== END ====

            
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


}
// ---- Set up of Catch Data in Rows ------
private struct CatchRowCentimeters: View {
    let item: CatchItem
    var body: some View {
        HStack(spacing: 22) {
            // -- ROWS of Today's Catches ----
            Spacer()
            //-- SPECIES Icon -----
            SpeciesIcon(species: item.species, size: 85)
            VStack(alignment: .leading, spacing: 4) {
                // -- Catch Information Species & Time ---
                Text(item.species.capitalized)
                    .font(.headline)
                    .foregroundStyle(.black)
                if let t = item.totalLengthCm {
                    Text(MeasureHelpers.formatCentimeters(t))
                        .font(.subheadline)
                        .foregroundStyle(.black)
                }

                HStack(spacing: 6) {
                    let when = Date(timeIntervalSince1970: TimeInterval(item.dateTimeSec))
                    Text(when.formatted(date: .omitted, time: .shortened)).font(.caption).foregroundStyle(.secondary).foregroundStyle(.black)
                    let hasGPS = (item.latitudeE7 != nil && item.longitudeE7 != nil)
                    Image(hasGPS ? "map_icon_fun_day" : "map_icon_fall_back")
                        .resizable().scaledToFit().frame(width: 16, height: 16)
                        .opacity(hasGPS ? 1.0 : 0.65)
                }
            }
            Spacer()
        }
    }
}

#Preview("Catch Entry (sample)") {
    NavigationStack {
        CatchEntryCentimetersView()
            .environmentObject(CatchesViewModel())   // ✅ vm
            .environmentObject(SettingsStore())      // ✅ settings
    }
}

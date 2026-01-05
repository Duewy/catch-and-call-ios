//
//  CatchEntryInchesView.swift
//  CatchAndCall
//
//  Created by Dwayne Brame on 2025-10-31.
//

import Foundation
import SwiftUI
import UIKit
internal import _LocationEssentials

// =============================================================
// CatchEntryInchesView.swift
// Catch entry using Inches + Quarter (0..3) -> quarters
// =============================================================

struct AddCatchInchesPopup: View {
    @Environment(\.dismiss) private var dismiss
    var speciesList: [String]
    var initialSpecies: String? = nil
    var initialInches: Int? = nil
    var initialQuarter: Int? = nil
    var title: String = "Add Catch"

    @State private var selectedSpeciesIndex: Int = 0
    @State private var inchesText: String = ""
    @State private var quarterText: String  = ""

    @State private var padTarget: NumberPad.Target = .pounds
    let onSave: (_ species: String, _ inches: Int, _ quarter: Int) -> Void

    private var parsedInches: Int { Int(inchesText) ?? 0 }
    private var parsedQuarter: Int { Int(quarterText) ?? 0 }

    private var canSave: Bool {
        let iOK = parsedInches >= 0
        let qOK = (0...3).contains(parsedQuarter)
        return iOK && qOK && (parsedInches*4 + parsedQuarter) > 0
    }

    var body: some View {
        ZStack {
            Color.ltBrown.ignoresSafeArea()
            VStack(spacing: 16) {
                HStack { Text(title)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.black)
                    ; Spacer();
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
                    Text("Length").font(.system(size: 22, weight: .semibold)).foregroundStyle(.black)
                    HStack(spacing: 6) {
                        Text("Inches").font(.system(size: 16, weight: .semibold)).foregroundStyle(.black)
                        Text(", 0-3/4ths").font(.system(size: 16, weight: .semibold)).foregroundStyle(.black)
                    }.padding(.bottom, 4)

                    HStack(spacing: 6) {
                        Text(inchesText.isEmpty ? "0" : inchesText)
                            .font(.system(size: 30, weight: .semibold))
                            .foregroundStyle(.black)
                            .frame(width: 60, height: 40)
                            .background(padTarget == .pounds ? Color.white : Color.veryLiteGrey)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(padTarget == .pounds ? Color.ltBrown : Color.veryLiteGrey, lineWidth: 2))
                            .onTapGesture { padTarget = .pounds; inchesText = "" }
                        Text("+").foregroundStyle(.black)

                        Text(quarterText.isEmpty ? "0" : quarterText)
                            .font(.system(size: 30, weight: .semibold))
                            .foregroundStyle(.black)
                            .frame(width: 60, height: 40)
                            .background(padTarget == .ounces ? Color.white : Color.veryLiteGrey)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(padTarget == .ounces ? Color.ltBrown : Color.veryLiteGrey, lineWidth: 2))
                            .onTapGesture { padTarget = .ounces; quarterText = "" }
                        Text("/4 Inches").foregroundStyle(.black)
                    }

                    NumberPad(
                        text: padTarget == .pounds ? $inchesText : $quarterText,
                        target: padTarget,
                        maxLen: padTarget == .pounds ? 3 : 1,
                        clampRange: (padTarget == .ounces) ? 0...3 : nil,
                        onDone: {}
                    )
                    .background(Color.ltBrown)
                }

                HStack {
                    Button {
                        let sp = speciesList[selectedSpeciesIndex]
                        let clamped = max(0, min(parsedQuarter, 3))
                        onSave(sp, parsedInches, clamped)
                        dismiss()
                    } label: { Text("Save Catch").bold() }
                    .buttonStyle(.borderedProminent)
                    .disabled(!canSave)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.black, lineWidth: 2)
                    )
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
            if let I = initialInches { inchesText = String(I) }
            if let Q = initialQuarter { quarterText = String(Q) }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Main View (Catch Entry – Inches)

struct CatchEntryInchesView: View {
    @EnvironmentObject var vm: CatchesViewModel
    @EnvironmentObject var settings: SettingsStore
    
    @State private var showingAddPopup = false
    @State private var editingItem: CatchItem? = nil
    @State private var confirmDelete: CatchItem? = nil
    
    // --- Active species list (from SpeciesUtils / UserDefaults) ---
    @State private var speciesList: [String] = []
    
    // Only show Fun Day catches that actually have Inches+Quarters stored
    private var todayInches: [CatchItem] {
        vm.today.filter {
            ($0.totalLengthQuarters ?? 0) > 0 &&
            ($0.catchType ?? "") == "Fun Day"
        }
    }
        
    var body: some View {
        
        VStack(spacing: 0) {
            if todayInches.isEmpty {
                VStack(spacing: 12) {
                    
                    Text("No catches yet today.").foregroundStyle(.black)
                    
                    Button { showingAddPopup = true } label: { Label("Add a Catch", systemImage: "plus.circle.fill") }
                        .buttonStyle(.borderedProminent)
                }.frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    Section(header: Text("    Today's Catches").font(.headline).foregroundColor(.black).underline()) {
                        ForEach(todayInches) { c in
                            CatchRowInches(item: c)
                                .listRowBackground(Color.clear).foregroundStyle(.black).background(Color.clear)
                                .overlay(Rectangle().frame(height: 6).foregroundColor(.gray), alignment: .bottom)
                                .listRowSeparator(.hidden)
                                .swipeActions(edge: .trailing) {
                                    Button("Edit") { editingItem = c }.tint(.blue)
                                    Button(role: .destructive) { confirmDelete = c } label: { Label("Delete", systemImage: "trash") }
                                }
                                .onTapGesture { editingItem = c }
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .background(Color.ltBrown)
                
                //--- DELETE CATCH -------
                .alert(item: $confirmDelete) { item in
                    let totalQ = item.totalLengthQuarters ?? 0
                    let when = Date(timeIntervalSince1970: TimeInterval(item.dateTimeSec))
                    return Alert(
                        title: Text("Delete this catch?"),
                        message: Text("\(item.species.capitalized) – \(MeasureHelpers.formatInchesQuarters(totalQ)) at \(when.formatted(date: .omitted, time: .shortened))"),
                        primaryButton: .destructive(Text("Delete")) { withAnimation { vm.deleteCatch(id: item.id) } },
                        secondaryButton: .cancel()
                    )
                }
                
                HStack {
                    Spacer()
                    if !todayInches.isEmpty {
                        let totalCatches = todayInches.count
                        let totQ = todayInches.compactMap { $0.totalLengthQuarters }.reduce(0, +)
                        Text("Catches: \(totalCatches)").font(.subheadline).foregroundColor(.black)
                        Text("Total: \(MeasureHelpers.formatInchesQuarters(totQ))").font(.subheadline).foregroundColor(.black)
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
        .background(Color.ltBrown)
        .onAppear { vm.reloadToday() }
        
        //--- EDIT CATCH ENTRY ---
        .sheet(item: $editingItem) { item in
            let split: (Int, Int) = {
                if let q = item.totalLengthQuarters {
                    let a = abs(q)
                    return (a / 4, a % 4)
                } else {
                    return (0, 0)
                }
            }()
            
            AddCatchInchesPopup(
                speciesList: speciesList,
                initialSpecies: item.species,
                initialInches: split.0,
                initialQuarter: split.1,
                title: "Edit Catch"
            ) { species, inches, quarter in
                vm.updateCatchInchesQuarters(original: item, species: species, wholeInches: inches, quarter: quarter)
            }
        }
        
        // -- ADD a CATCH Information ----
        .sheet(isPresented: $showingAddPopup) {
            AddCatchInchesPopup(speciesList: speciesList) { species, inches, quarter in
                // Check SetUp toggle (same idea as Lbs/Ozs & Kgs pages)
                if settings.gpsEnabled {
                    // Ask LocationService for a coordinate
                    LocationService.shared.requestCoordinate { coordinate in
                        // If location lookup fails, just save without GPS
                        guard let coordinate = coordinate else {
                            vm.saveInchesQuarters(
                                species: species,
                                wholeInches: inches,
                                quarter: quarter
                            )
                            return
                        }
                        
                        let latE7 = Int(coordinate.latitude  * 10_000_000)
                        let lonE7 = Int(coordinate.longitude * 10_000_000)
                        
                        vm.saveInchesQuarters(
                            species: species,
                            wholeInches: inches,
                            quarter: quarter,
                            latE7: latE7,
                            lonE7: lonE7
                        )
                    }
                } else {
                    // GPS disabled in SetUp → save without lat/lon
                    vm.saveInchesQuarters(
                        species: species,
                        wholeInches: inches,
                        quarter: quarter
                    )
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.ltBrown, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.light, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack(spacing: 0) {
                    Text("Catch Entry")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundColor(.black)

                    Text("(Inches)")
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
    }//=== END ===

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
private struct CatchRowInches: View {
    let item: CatchItem
    var body: some View {
        HStack(spacing: 22) {
            Spacer()
            SpeciesIcon(species: item.species, size: 85)
            VStack(alignment: .leading, spacing: 4) {
                Text(item.species.capitalized).font(.headline)
                if let q = item.totalLengthQuarters {
                    Text(MeasureHelpers.formatInchesQuarters(q)).font(.subheadline).foregroundStyle(.black)
                } else if let t = item.totalLengthCm {
                    Text(MeasureHelpers.formatCentimeters(t)).font(.subheadline).foregroundStyle(.black)
                }
                HStack(spacing: 6) {
                    let when = Date(timeIntervalSince1970: TimeInterval(item.dateTimeSec))
                    Text(when.formatted(date: .omitted, time: .shortened)).font(.caption).foregroundStyle(.black)
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
        CatchEntryInchesView()
            .environmentObject(CatchesViewModel())   // ✅ vm
            .environmentObject(SettingsStore())      // ✅ settings
    }
}


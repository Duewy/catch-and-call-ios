//
//  CatchEntryTournyCmdfssView.swift
//  CatchAndCall
//
//  Created by Dwayne Brame on 2025-11-04.

//  TODO: Set Up VCC and Ensure GPS works
//  Pre-GPS baseline (save→append→insert→refresh)

import SwiftUI
import Foundation
internal import _LocationEssentials


// MARK: - Formatting & Mapping Helpers


private enum CmsFmt {
    static func split(totaltenths: Int) -> (real: Int, dec: Int) {
        (totaltenths / 10, totaltenths % 10)
    }
}

// MARK: - Display Row
private struct CentimetersDisplayRow: Identifiable, Equatable {
    let id: UUID
    let catchID: Int64
    let species: String
    let clipColor: String
    let tenths: Int
}

// MARK: --- Main View ---------

struct CatchEntryTournamentCentimetersView: View {
    @EnvironmentObject var settings: SettingsStore
    
    // Rows rendered in the 6 tournament lanes
    @State private var rows: [CentimetersDisplayRow] = []
    
    // Add / Edit / Delete state
    @State private var showAdd = false
    @State private var editingItem: CentimetersDisplayRow? = nil
    @State private var confirmDelete: CentimetersDisplayRow? = nil
    
    // Blink state
    @State private var blinkTargetID: UUID? = nil
    @State private var blinkOn = false
    
    // Clip colors: source of truth is ClipColorUtils
    private var clipOrder: [String] { ClipColorUtils.activeClipOrder() }
    
    // Sorted by weight (heaviest first)
    private var sortedRows: [CentimetersDisplayRow] { rows.sorted { $0.tenths > $1.tenths } }
    
    // Top N tournament fish
    private var topN: [CentimetersDisplayRow] { Array(sortedRows.prefix(settings.tournamentLimit)) }
    
    //--- Set Values for Tourny Type --------
    private var totalReal: Int { topN.reduce(0) { $0 + $1.tenths } / 10 }
    private var totalDec: Int { topN.reduce(0) { $0 + $1.tenths } % 10 }
    
    // The shortest fish in the current top N (for blink target)
    private var smallestTopCatchID: UUID? { (topN.count == settings.tournamentLimit) ? topN.last?.id : nil }
    
    // === CatchEntryTournyCmsView Page =======
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                header
                addCatchButton
                lanes
                totals
                statusBar
                navButtons
            }
            .padding(.horizontal, 12)
            .padding(.top, 8)
        }
        .background(Color.softlockSand.ignoresSafeArea())
        
        // Add sheet (existing behaviour, unchanged)
        .sheet(isPresented: $showAdd) {
            addSheet
        }
        
        // Edit sheet (swipe → Edit)
        .sheet(item: $editingItem) { row in
            EditTournamentCentimetersSheet(
                row: row,
                speciesOptions: speciesOptionsFrom(settings.tournamentSpecies),
                availableClipColors: availableClipColorsForEdit(row: row)
            ) { newSpecies, newClip, newTenths in
                Task {
                    await updateTournamentCentimeters(
                        row: row,
                        species: newSpecies,
                        clip: newClip,
                        tenths: newTenths
                    )
                }
            }
        }
        
        // Delete confirmation (swipe → Delete)
        .alert(item: $confirmDelete) { row in
            Alert(
                title: Text("Delete this catch?"),
                message: Text("This will remove it from your tournament."),
                primaryButton: .destructive(Text("Delete")) {
                    deleteTournamentCentimeters(row: row)
                },
                secondaryButton: .cancel()
            )
        }
        
        // Data flow
        .onAppear(perform: refreshFromDB)
        .onChange(of: showAdd) { isOpen in if !isOpen { refreshFromDB() } }
        .onChange(of: settings.tournamentLimit) { _ in maybeBlinkOnChange() }
        .onChange(of: topN.map { $0.id }) { _ in maybeBlinkOnChange() }
    }
    
    // MARK: Sections
    private var header: some View {
        HStack(spacing: 8) {
            //---TIME ----
            Text(timeOnlyString().uppercased())
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(.black)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.clipWhite.opacity(0.66))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            
            Spacer(minLength: 2)
            
            //---- LOGO ------
            Image("catch_call_words_blue")
                .resizable()
                .scaledToFit()
                .frame(width: 235, height: 61)
                .scaleEffect(x: 0.8, y: 1)
        }
    }
    
    // ---- Sets the time to omit AM/PM  "12:33" ------
    private func timeOnlyString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm"     // no a = no AM/PM
        return formatter.string(from: Date())
    }
    
    
    //--- ADD Catch Button ---
    private var addCatchButton: some View {
        Button { showAdd = true } label: {
            Text("ADD CATCH")
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(Color.black)
                .padding(.horizontal, 36)
                .padding(.vertical, 12)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color.ltBrown))
                .overlay(RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.black, lineWidth: 3))
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 4)
    }
    
    // ---- Tournament Lanes as a List (supports swipe actions) ----
    private var lanes: some View {
        List {
            // Remove list separators + background
            ForEach(0..<6, id: \.self) { i in
                let item: CentimetersDisplayRow? = (i < sortedRows.count) ? sortedRows[i] : nil
                TournamentCentimetersLane(index: i,
                                          row: item,
                                          limit: settings.tournamentLimit,
                                          pageBg: Color.softlockSand,
                                          isBlink: item?.id == blinkTargetID,
                                          blinkOn: blinkOn)
                .listRowInsets(EdgeInsets(top: 11, leading: 21, bottom: 0, trailing: 0))
                .listRowBackground(Color.clear)
                .swipeActions(edge: .trailing) {
                    if let item = item {
                        Button("Edit") { editingItem = item }
                            .tint(.blue)
                        Button(role: .destructive) {
                            confirmDelete = item
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .frame(height: 6 * 70)   // Approx height of the 6 lanes
    }
    
    // ---- Show TOTAL Value ------
    private var totals: some View {
        HStack(spacing: 6) {
            Text("\(totalReal)")
                .font(.system(size: 48, weight: .bold))
                .foregroundStyle(.black)
                .padding(.horizontal, 6)
                .background(Color.clipWhite)
                .clipShape(RoundedRectangle(cornerRadius: 6))
            Text("•")
                .font(.system(size: 60, weight: .bold))
                .foregroundStyle(.black)
                .baselineOffset(2)
            Text("\(totalDec)")
                .font(.system(size: 48, weight: .bold))
                .foregroundStyle(.black)
                .padding(.horizontal, 6)
                .background(Color.clipWhite)
                .clipShape(RoundedRectangle(cornerRadius: 6))
            Text("Cms")
                .font(.system(size: 60, weight: .bold))
                .foregroundStyle(.black)
                .minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 2)
    }
    
    // ---- Show GPS & VCC Statues ---
    private var statusBar: some View {
        HStack(spacing: 24) {
            Text(settings.gpsEnabled ? "GPS ENABLED" : "GPS DISABLED")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(settings.gpsEnabled ? Color.red : Color.clipBlue)
            Text(settings.voiceControlEnabled ? "VCC ENABLED" : "MANUAL MODE")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(settings.voiceControlEnabled ? Color.clipOrange : Color.clipBlue)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 2)
    }
    
    // ---- Navigation Buttons ----
    private var navButtons: some View {
        HStack(spacing: 12) {
            NavigationLink {
                // -- MAIN MENU Button ------
                MainMenuView()
            } label: {
                Text("Main Page")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(height: 50)
                    .padding(.horizontal, 24)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color.softlockGreen))
                    .shadow(color: .black.opacity(0.25), radius: 3, x: 0, y: 2)
                    .overlay(RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.black, lineWidth: 3))
            }
            .buttonStyle(.plain)     // keeps the Custom Button Look
            
            
            NavigationLink {
                // -- SET UP Button ------
                SetUpView()
            } label: {
                Text("Set Up")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(height: 50)
                    .padding(.horizontal, 24)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color.softlockBlue))
                    .shadow(color: .black.opacity(0.25), radius: 3, x: 0, y: 2)
                    .overlay(RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.black, lineWidth: 3))
            }
            .buttonStyle(.plain)     // keeps the Custom Button Look
            
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
    
    // MARK: Add Sheet (GPS-aware)
    private var addSheet: some View {
        TournamentCentimetersSheet(
            isPresented: $showAdd,
            tournamentSpecies: settings.tournamentSpecies,
            speciesOptions: speciesOptionsFrom(settings.tournamentSpecies),
            availableClipColors: availableClipColorsTopN()
        ) { species, clip, tenths in
            
            if settings.gpsEnabled {
                
                // Request GPS from Location Service
                LocationService.shared.requestCoordinate { coordinate in
                    
                    // GPS failed → save without location
                    guard let coordinate = coordinate else {
                        saveTournamentCmsCatch(
                            species: species,
                            clip: clip,
                            tenths: tenths,
                            latE7: nil,
                            lonE7: nil
                        )
                        return
                    }
                    
                    // Convert to E7 format used by DB
                    let latE7 = Int(coordinate.latitude  * 10_000_000)
                    let lonE7 = Int(coordinate.longitude * 10_000_000)
                    
                    saveTournamentCmsCatch(
                        species: species,
                        clip: clip,
                        tenths: tenths,
                        latE7: latE7,
                        lonE7: lonE7
                    )
                }
                
            } else {
                
                // GPS disabled → regular save
                saveTournamentCmsCatch(
                    species: species,
                    clip: clip,
                    tenths: tenths,
                    latE7: nil,
                    lonE7: nil
                )
            }
            
        }
        .presentationDetents([.large])
    }
    
    // MARK: - DB: Load / Save / Update / Delete
    
    private func refreshFromDB() {
        DispatchQueue.global(qos: .userInitiated).async {
            var newRows: [CentimetersDisplayRow] = []
            do {
                let today = try DatabaseManager.shared.getCatchesOn(date: Date())
                let filtered = today.filter {
                    ($0.totalLengthCm ?? 0) > 0 &&
                    (($0.catchType ?? "") == "Tournament")
                }
                
                newRows = filtered.map { c in
                    CentimetersDisplayRow(
                        id: UUID(),
                        catchID: c.id,
                        species: c.species,
                        clipColor: (c.clipColor ?? "RED").uppercased(),
                        tenths: c.totalLengthCm ?? 0
                    )
                }
            } catch {
                newRows = []
            }
            
            DispatchQueue.main.async {
                self.rows = newRows
            }
        }
    }
    
  
    // ===== Save Catch Information ====
    private func saveTournamentCmsCatch(
        species: String,
        clip: String,
        tenths: Int,
        latE7: Int?,
        lonE7: Int?
    ) {
        let nowSec = Int64(Date().timeIntervalSince1970)
        
        
        // -- Persist -build the CatchItem and insert into SQLite ---
        let item = CatchItem(
            id: 0,
            dateTimeSec: nowSec,
            species: species,
            totalWeightOz: nil,
            totalWeightPoundsHundredth: nil,
            totalWeightHundredthKg: nil,
            totalLengthQuarters: nil,
            totalLengthCm: tenths,
            catchType: "Tournament",
            markerType: SpeciesUtils.TournamentSpeciesCode.markerType(for: species),
            clipColor: clip,
            latitudeE7: latE7 ,
            longitudeE7: lonE7 ,
            primaryPhotoId: nil,
            createdAtSec: nowSec
        )
        
        do { _ = try DatabaseManager.shared.insertCatch(item) } catch { /* keep quiet */ }
        
        // Reconcile with DB & blink
        DispatchQueue.main.async {
            self.refreshFromDB()
            self.triggerBlink()
        }
    }
    
    
    @MainActor
    private func updateTournamentCentimeters(
        row: CentimetersDisplayRow,
        species: String,
        clip: String,
        tenths: Int
    ) async {
        do {
            guard var item = try DatabaseManager.shared.getCatch(id: row.catchID) else { return }
            
            item.species = species
            item.clipColor = clip
            item.markerType = SpeciesUtils.TournamentSpeciesCode.markerType(for: species)
            item.totalLengthCm = tenths
            item.catchType = "Tournament"
            
            try DatabaseManager.shared.updateCatch(item)
            refreshFromDB()
        } catch {
            print("ERROR updating tournament catch:", error)
        }
    }
    
    private func deleteTournamentCentimeters(row: CentimetersDisplayRow) {
        do {
            try DatabaseManager.shared.deleteCatch(id: row.catchID)
            refreshFromDB()
        } catch {
            print("ERROR deleting tournament catch:", error)
        }
    }
    
    
    // MARK: - Blink Logic
    private func triggerBlink(times: Int = 6) {
        guard let id = smallestTopCatchID else { return }

        blinkTargetID = id

        // Duration for one blink phase
        let blinkDuration = 0.25
        let delayBetween = 0.35

        for i in 0..<times * 2 {    // times * 2 because toggle = ON → OFF is 1 blink
            let delay = Double(i) * delayBetween

            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.easeInOut(duration: blinkDuration)) {
                    blinkOn.toggle()
                }
            }
        }
    }

    // --- Set Blink Trigger ------
    private func maybeBlinkOnChange() {
        if topN.count == settings.tournamentLimit { triggerBlink() }
    }
    
    // MARK: Species & Clip
    
    //===  Get and List Species from SetUp page ====
    private func speciesOptionsFrom(_ tournamentSpecies: String) -> [String] {
        let key = tournamentSpecies
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        
        // NOTE:
        // We only expect clean names from SpeciesUtils at this point.
        // Special tournament behaviour:
        // - Bass tournaments allow LM + SM (and optionally Spotted Bass).
        
        switch key {
        case "largemouth", "largemouth bass", "large mouth", "large mouth bass":
            // Largemouth selected → LM, SM
            return ["Large Mouth", "Small Mouth"]
            
        case "smallmouth", "smallmouth bass", "small mouth", "small mouth bass":
            // Smallmouth selected → SM, LM (user-focus on SM first)
            return ["Small Mouth", "Large Mouth"]
            
        case "spotted bass":
            // Spotted Bass selected → LM, SM, SB
            return ["Large Mouth", "Small Mouth", "Spotted Bass"]
            
        default:
            // All other species: just the one chosen
            return [titleCase(tournamentSpecies)]
        }
    }
    
    private func titleCase(_ raw: String) -> String {
        raw.trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .split(separator: " ")
            .map { $0.capitalized }
            .joined(separator: " ")
    }
    
    
    
    // ==== Available Clip Colors ======
    private func availableClipColorsTopN() -> [String] {
        let used = Set(topN.map { $0.clipColor.uppercased() })
        let filtered = clipOrder.filter { !used.contains($0) }
        return filtered.isEmpty ? clipOrder : filtered
    }

    // ==== Available Clip Colors EDIT / DELETE Sheet ======
    private func availableClipColorsForEdit(row: CentimetersDisplayRow) -> [String] {
        var list = availableClipColorsTopN()

        // Make sure current clip color is first option
        let current = row.clipColor.uppercased()
        list.removeAll { $0.uppercased() == current }
        list.insert(current, at: 0)

        return list
    }


}

// MARK: - Rows (Android-style lane: clip • real • dec • species)
private struct TournamentCentimetersLane: View {
    let index: Int
    let row: CentimetersDisplayRow?
    let limit: Int
    let pageBg: Color
    let isBlink: Bool
    let blinkOn: Bool

    var body: some View {
        let hideRow6When4 = (limit == 4 && index == 5)
        if hideRow6When4 {
            EmptyView()
        } else {
            let dim  = (limit == 4 && index == 4) || (limit == 5 && index == 5)
            let withinLimit = index < limit

            let bgColor: Color = withinLimit
                ? (row != nil ? ClipColorUtils.bg(row!.clipColor) : Color.veryLiteGrey.opacity(0.85))
                : .clear

            let fgColor: Color = row != nil ? ClipColorUtils.fg(row!.clipColor) : .black

            let (real, dec) = CmsFmt.split(totaltenths: row?.tenths ?? 0)

            HStack(spacing: 6) {
                //-- Clip Color Letter ---
                Text(row?.clipColor.first.map { String($0) } ?? "")
                    .font(.system(size: 40, weight: .regular))
                    .foregroundStyle(row != nil ? fgColor : .black)
                    .frame(width: 44, height: 54)
                    .background(bgColor)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.black.opacity(0.58)))
                    .padding(.leading, 10)
                // -- REAL Value --------
                Text(row != nil ? String(real) : "")
                    .font(.system(size: 45, weight: .bold).monospacedDigit())
                    .foregroundStyle(fgColor)
                    .frame(width: 120, height: 54)
                    .background(RoundedRectangle(cornerRadius: 6).fill(bgColor))
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.black.opacity(0.58)))
                Text(".")
                    .font(.system(size: 45, weight: .bold).monospacedDigit())
                    .foregroundStyle(Color.black)
                    .frame(width: 10, height: 54)
                   
                // -- DEC Value ---------
                Text(row != nil ? String(dec) : "")
                    .font(.system(size: 45, weight: .bold).monospacedDigit())
                    .foregroundStyle(fgColor)
                    .frame(width: 120, height: 54)
                    .background(RoundedRectangle(cornerRadius: 6).fill(bgColor))
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.black.opacity(0.58)))
                // --- Species Letters -------
                Text(row.map { SpeciesUtils.TournamentSpeciesCode.code(from: $0.species) } ?? "")
                    .font(.system(size: 20, weight: .regular))
                    .foregroundStyle(.black)
                    .frame(width: 56, height: 54, alignment: .leading)
                    .background(pageBg)
                    .padding(.leading, 2)
            }
            .opacity(dim ? 0.5 : 1)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isBlink && blinkOn ? Color.black : .clear, lineWidth: 3)
            )
        }
    }
}

// MARK: - Add Catch Sheet
private struct TournamentCentimetersSheet: View {
    @Binding var isPresented: Bool

    let tournamentSpecies: String
    let speciesOptions: [String]
    let availableClipColors: [String]

    let onSave: (_ species: String, _ clip: String, _ tenths: Int) -> Void

    @State private var selectedSpecies: String = ""
    @State private var selectedClip: String = ""
    @State private var wholeText: String = ""
    @State private var decText: String = ""

    // .pounds = whole cm, .ounces = tenths (0–9)
    @State private var padTarget: NumberPad.Target = .pounds

    private var tenths: Int {
        (Int(wholeText) ?? 0) * 10 + (Int(decText) ?? 0)
    }

    private var canSave: Bool {
        tenths > 0 &&
        !selectedClip.isEmpty &&
        !selectedSpecies.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(spacing: 12) {
            Text("Tournament Catch Centimeters")
                .font(.headline)
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color.softlockSand)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .padding(.horizontal, 6)

            HStack {
                Text("Selected Species"); Spacer(); Text("Select Clip Color")
            }
            .font(.subheadline)
            .foregroundStyle(.black)
            .padding(.horizontal, 6)

            HStack(spacing: 10) {
                Menu {
                    ForEach(speciesOptions, id: \.self) { s in
                        Button(s) { selectedSpecies = s }
                    }
                } label: {
                    pickerLabel(text: selectedSpecies.isEmpty ? "Select" : selectedSpecies)
                }

                Spacer(minLength: 8)

                Menu {
                    ForEach(availableClipColors, id: \.self) { c in
                        Button {
                            selectedClip = c
                        } label: {
                            Label(c.capitalized, systemImage: "square.fill")
                                .labelStyle(.titleAndIcon)
                        }
                        .tint(ClipColorUtils.bg(c))
                    }
                } label: {
                    HStack(spacing: 10) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(ClipColorUtils.bg(selectedClip))
                            .frame(width: 16, height: 16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 3)
                                    .stroke(Color.black.opacity(0.95), lineWidth: 1)
                            )

                        Text(selectedClip.isEmpty ? "Select" : selectedClip.capitalized)
                            .font(.body.weight(.semibold))
                            .foregroundStyle(.black)
                        Spacer()
                        Image(systemName: "chevron.down")
                            .foregroundStyle(.black.opacity(0.75))
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 12)
                    .frame(minWidth: 160)
                    .background(Color.veryLiteGrey.opacity(0.85))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(.black.opacity(0.35))
                    )
                }
            }
            .padding(.horizontal, 6)

            // Length entry (cm + tenth)
            VStack(alignment: .center, spacing: 2) {
                HStack(spacing: 1) {
                    // Whole cm
                    Text(wholeText.isEmpty ? "0" : wholeText)
                        .font(.system(size: 30, weight: .semibold))
                        .foregroundStyle(.black)
                        .frame(width: 80, height: 40)
                        .background(padTarget == .pounds ? Color.white : Color.veryLiteGrey)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(
                                    padTarget == .pounds ? Color.halo_light_blue : Color.veryLiteGrey,
                                    lineWidth: 2
                                )
                        )
                        .onTapGesture {
                            padTarget = .pounds
                            wholeText = ""
                        }

                    Text("•")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundStyle(.black)
                        .baselineOffset(2)

                    // Tenths (0–9)
                    Text(decText.isEmpty ? "0" : decText)
                        .font(.system(size: 30, weight: .semibold))
                        .foregroundStyle(.black)
                        .frame(width: 60, height: 40)
                        .background(padTarget == .ounces ? Color.white : Color.veryLiteGrey)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(
                                    padTarget == .ounces ? Color.halo_light_blue : Color.veryLiteGrey,
                                    lineWidth: 2
                                )
                        )
                        .onTapGesture {
                            padTarget = .ounces
                            decText = ""
                        }

                    Text("Cms")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.black)
                        .padding(.leading, 4)
                }

                HStack {
                    Spacer()
                    Text("XX.X Cms")
                        .font(.footnote)
                        .foregroundStyle(.black)
                    Spacer()
                }
            }
            .padding(.top, 6)
            .padding(.leading, 6)

            // NumberPad
            NumberPad(
                text: padTarget == .pounds ? $wholeText : $decText,
                target: padTarget,
                maxLen: padTarget == .pounds ? 3 : 1,
                clampRange: padTarget == .ounces ? 0...9 : nil,
                onDone: {}
            )
            .background(Color.softlockSand.opacity(0.2))

            HStack(spacing: 10) {
                // Cancel
                Button("Cancel") { isPresented = false }
                    .font(.headline)
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .background(Color.veryLiteGrey.opacity(0.9))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.black, lineWidth: 1)
                    )

                // Save
                Button("SAVE_CATCH") { commitSave() }
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .background(Color.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.black, lineWidth: 1)
                    )
                    .disabled(!canSave)
                    .opacity(canSave ? 1 : 0.5)
            }
            .padding(.horizontal, 6)
            .padding(.bottom, 4)
        }
        .padding(.top, 6)
        .background(Color.softlockSand)
        .onAppear {
            selectedSpecies = speciesOptions.first ?? ""
            selectedClip = availableClipColors.first ?? ""
        }
    }

    // Sheet helpers
    private func pickerLabel(text: String) -> some View {
        HStack {
            Text(text)
                .font(.body.weight(.semibold))
                .foregroundStyle(.black)
                .lineLimit(1)
            Spacer()
            Image(systemName: "chevron.down")
                .foregroundStyle(.black.opacity(0.75))
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .frame(minWidth: 160)
        .background(Color.veryLiteGrey.opacity(0.85))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(.black.opacity(0.35))
        )
    }

    private func commitSave() {
        onSave(
            normalizeSpecies(selectedSpecies),
            selectedClip.uppercased(),
            tenths
        )
        isPresented = false
    }

    private func normalizeSpecies(_ s: String) -> String {
        s.trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: "_", with: " ")
    }
}


// MARK: - EDIT Tournament Centimeters Sheet (same look, pre-filled)
private struct EditTournamentCentimetersSheet: View {
    let row: CentimetersDisplayRow
    let speciesOptions: [String]
    let availableClipColors: [String]
    let onSave: (_ species: String, _ clip: String, _ totaltenths: Int) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var selectedSpecies: String = ""
    @State private var selectedClip: String = ""
    @State private var wholeText: String = ""
    @State private var decText: String = ""

    // .pounds = whole cm, .ounces = tenth (0–9)
    @State private var padTarget: NumberPad.Target = .pounds

    private var totalTenths: Int {
        (Int(wholeText) ?? 0) * 10 + (Int(decText) ?? 0)
    }

    private var canSave: Bool {
        totalTenths > 0 &&
        !selectedClip.isEmpty &&
        !selectedSpecies.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(spacing: 12) {
            Text("Edit Centimeters Catch")
                .font(.headline)
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color.clipVeryGreen)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .padding(.horizontal, 6)

            HStack {
                Text("Selected Species")
                Spacer()
                Text("Select Clip Color")
            }
            .font(.subheadline)
            .foregroundStyle(.black)
            .padding(.horizontal, 6)

            HStack(spacing: 10) {
                // Species
                Menu {
                    ForEach(speciesOptions, id: \.self) { s in
                        Button(s) { selectedSpecies = s }
                    }
                } label: {
                    pickerLabel(text: selectedSpecies.isEmpty ? "Select" : selectedSpecies)
                }

                Spacer(minLength: 8)

                // Clip color
                Menu {
                    ForEach(availableClipColors, id: \.self) { c in
                        Button {
                            selectedClip = c
                        } label: {
                            Label(c.capitalized, systemImage: "square.fill")
                                .labelStyle(.titleAndIcon)
                        }
                        .tint(ClipColorUtils.bg(c))
                    }
                } label: {
                    HStack(spacing: 10) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(ClipColorUtils.bg(selectedClip))
                            .frame(width: 16, height: 16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 3)
                                    .stroke(Color.black.opacity(0.95), lineWidth: 1)
                            )

                        Text(selectedClip.isEmpty ? "Select" : selectedClip.capitalized)
                            .font(.body.weight(.semibold))
                            .foregroundStyle(.black)
                        Spacer()
                        Image(systemName: "chevron.down")
                            .foregroundStyle(.black.opacity(0.75))
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 12)
                    .frame(minWidth: 160)
                    .background(Color.veryLiteGrey.opacity(0.85))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(.black.opacity(0.35))
                    )
                }
            }
            .padding(.horizontal, 6)

            // Length Entry
            VStack(alignment: .center, spacing: 2) {
                HStack(spacing: 1) {
                    // Whole cm
                    Text(wholeText.isEmpty ? "0" : wholeText)
                        .font(.system(size: 30, weight: .semibold))
                        .foregroundStyle(.black)
                        .frame(width: 80, height: 40)
                        .background(padTarget == .pounds ? Color.white : Color.veryLiteGrey)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(
                                    padTarget == .pounds ? Color.halo_light_blue : Color.veryLiteGrey,
                                    lineWidth: 2
                                )
                        )
                        .onTapGesture {
                            padTarget = .pounds
                            wholeText = ""
                        }

                    Text("•")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundStyle(.black)
                        .baselineOffset(2)

                    // Tenth (0–9)
                    Text(decText.isEmpty ? "0" : decText)
                        .font(.system(size: 30, weight: .semibold))
                        .foregroundStyle(.black)
                        .frame(width: 60, height: 40)
                        .background(padTarget == .ounces ? Color.white : Color.veryLiteGrey)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(
                                    padTarget == .ounces ? Color.halo_light_blue : Color.veryLiteGrey,
                                    lineWidth: 2
                                )
                        )
                        .onTapGesture {
                            padTarget = .ounces
                            decText = ""
                        }

                    Text("Cms")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.black)
                        .padding(.leading, 4)
                }

                HStack {
                    Spacer()
                    Text("XX.X Cms")
                        .font(.footnote)
                        .foregroundStyle(.black)
                    Spacer()
                }
            }
            .padding(.top, 6)
            .padding(.leading, 6)

            // NumberPad
            NumberPad(
                text: padTarget == .pounds ? $wholeText : $decText,
                target: padTarget,
                maxLen: padTarget == .pounds ? 3 : 1,
                clampRange: padTarget == .ounces ? 0...9 : nil,
                onDone: {}
            )
            .background(Color.veryLiteGrey.opacity(0.2))

            HStack(spacing: 10) {
                Button("Cancel") {
                    dismiss()
                }
                .font(.headline)
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(Color.veryLiteGrey.opacity(0.9))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.black, lineWidth: 3)
                )

                Button("Save") {
                    onSave(
                        normalizeSpecies(selectedSpecies),
                        selectedClip.uppercased(),
                        totalTenths
                    )
                    dismiss()
                }
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(Color.blue)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.black, lineWidth: 3)
                )
                .disabled(!canSave)
                .opacity(canSave ? 1 : 0.5)
            }
            .padding(.horizontal, 6)
            .padding(.bottom, 4)
        }
        .padding(.top, 6)
        .background(Color.softlockSand)
        .onAppear {
            // Species: match on case-insensitive against options
            if let idx = speciesOptions.firstIndex(where: {
                $0.trimmingCharacters(in: .whitespacesAndNewlines)
                    .lowercased() == row.species.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            }) {
                selectedSpecies = speciesOptions[idx]
            } else {
                selectedSpecies = speciesOptions.first ?? ""
            }

            // Clip color
            selectedClip = row.clipColor.uppercased()

            // Pre-fill from DB (split tenths)
            let (real, dec) = CmsFmt.split(totaltenths: row.tenths)
            wholeText = String(real)
            decText = String(dec)
        }
    }

    // Helpers (Edit sheet)
    private func pickerLabel(text: String) -> some View {
        HStack {
            Text(text)
                .font(.body.weight(.semibold))
                .foregroundStyle(.black)
                .lineLimit(1)
            Spacer()
            Image(systemName: "chevron.down")
                .foregroundStyle(.black.opacity(0.75))
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .frame(minWidth: 160)
        .background(Color.veryLiteGrey.opacity(0.85))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(.black.opacity(0.35))
        )
    }

    private func normalizeSpecies(_ s: String) -> String {
        s.trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: "_", with: " ")
    }
}


#Preview {
    NavigationStack {
        CatchEntryTournamentCentimetersView()
    }
    .environmentObject(SettingsStore())
}


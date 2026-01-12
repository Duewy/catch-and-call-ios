//
//  CatchEntryTournyInchesView.swift
//  CatchAndCall
//
//  Created by Dwayne Brame on 2025-11-04.

// Formating of values,   Inches is real, Quarters are dec

import SwiftUI
import Foundation
internal import _LocationEssentials


// MARK: - Formatting & Mapping Helpers


private enum InchesFmt {
    static func split(totalfourths: Int) -> (real: Int, dec: Int) {
        (totalfourths / 4, totalfourths % 4)
    }
}

// MARK: - Display Row
private struct InchesDisplayRow: Identifiable, Equatable {
    let id: UUID
    let catchID: Int64
    let species: String
    let clipColor: String
    let quarters: Int
}

// MARK: --- Main View ---------

struct CatchEntryTournamentInchesView: View {
    @EnvironmentObject var settings: SettingsStore
    
    // Rows rendered in the 6 tournament lanes
    @State private var rows: [InchesDisplayRow] = []
    
    // Add / Edit / Delete state
    @State private var showAdd = false
    @State private var editingItem: InchesDisplayRow? = nil
    @State private var confirmDelete: InchesDisplayRow? = nil

        // Blink State
    @State private var blinkTargetID: UUID? = nil
    @State private var blinkOn = false

    // Clip colors: source of truth is ClipColorUtils
    private var clipOrder: [String] { ClipColorUtils.activeClipOrder() }

    // Sorted by Length (longest first)
    private var sortedRows: [InchesDisplayRow] { rows.sorted { $0.quarters > $1.quarters } }
    
    // Top N tournament fish
    private var topN: [InchesDisplayRow] { Array(sortedRows.prefix(settings.tournamentLimit)) }
    
    //--- Set Values for Tourny Type --------
    private var totalReal: Int { topN.reduce(0) { $0 + $1.quarters } / 4 }
    private var totalDec: Int { topN.reduce(0) { $0 + $1.quarters } % 4 }
    
    // Shortest fish in current top N (for the Blink Target)
    private var smallestTopCatchID: UUID? { (topN.count == settings.tournamentLimit) ? topN.last?.id : nil }

    
    // === CatchEntryTournyInchesView Page =======
    
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
        .background(Color.ltBrown.ignoresSafeArea())
        
        // Add Catch sheet
        .sheet(isPresented: $showAdd) { addSheet }
      
        // Edit Catch sheet (swipe → Edit)
                .sheet(item: $editingItem) { row in
                    EditTournamentInchesSheet(
                        row: row,
                        speciesOptions: speciesOptionsFrom(settings.tournamentSpecies),
                        availableClipColors: availableClipColorsForEdit(row: row)
                    ) { newSpecies, newClip, newQuarters in
                        Task {
                            await updateTournamentInches(
                                row: row,
                                species: newSpecies,
                                clip: newClip,
                                quarters: newQuarters
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
                    deleteTournamentInches(row: row)
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
                .padding(.horizontal, 38)
                .padding(.vertical, 12)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color.yellow))
                .overlay(RoundedRectangle(cornerRadius: 8)
                                   .stroke(Color.black, lineWidth: 3))
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 4)
    }

    private var lanes: some View {
        List {
            // Remove list separators + background
            ForEach(0..<6, id: \.self) { i in
                let item: InchesDisplayRow? = (i < sortedRows.count) ? sortedRows[i] : nil
                TournamentInchesLane(index: i,
                                     row: item,
                                     limit: settings.tournamentLimit,
                                     pageBg: Color.ltBrown,
                                     isBlink: item?.id == blinkTargetID,
                                     blinkOn: blinkOn
                                     )
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
            Text("&")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(.black)
                .baselineOffset(2)
            Text("\(totalDec)")
                .font(.system(size: 48, weight: .bold))
                .foregroundStyle(.black)
                .padding(.horizontal, 6)
                .background(Color.clipWhite)
                .clipShape(RoundedRectangle(cornerRadius: 6))
            Text("/4  Inches") //TODO: see about formating /4 smaller
                .font(.system(size: 20, weight: .bold))
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
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color.blue))
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
        TournamentInchesSheet(
            isPresented: $showAdd,
            tournamentSpecies: settings.tournamentSpecies,
            speciesOptions: speciesOptionsFrom(settings.tournamentSpecies),
            availableClipColors: availableClipColorsTopN()
        ) { species, clip, quarters in

            if settings.gpsEnabled {
                // Request GPS from LocationService
                LocationService.shared.requestCoordinate { coordinate in

                    // If GPS failed → save without coords
                    guard let coordinate = coordinate else {
                        saveTournamentInchesCatch(
                            species: species,
                            clip: clip,
                            quarters: quarters,
                            latE7: nil,
                            lonE7: nil
                        )
                        return
                    }

                    // Convert to E7 format
                    let latE7 = Int(coordinate.latitude  * 10_000_000)
                    let lonE7 = Int(coordinate.longitude * 10_000_000)

                    saveTournamentInchesCatch(
                        species: species,
                        clip: clip,
                        quarters: quarters,
                        latE7: latE7,
                        lonE7: lonE7
                    )
                }

            } else {
                // GPS disabled → normal save
                saveTournamentInchesCatch(
                    species: species,
                    clip: clip,
                    quarters: quarters,
                    latE7: nil,
                    lonE7: nil
                )
            }
        }
        .presentationDetents([.large])
    }

   
    // MARK: === Add Catch to DB ====
    private func refreshFromDB() {
        DispatchQueue.global(qos: .userInitiated).async {
            var newRows: [InchesDisplayRow] = []
            do {
                let today = try DatabaseManager.shared.getCatchesOn(date: Date())
                let filtered = today.filter {
                    // Only tournament catches with Cms stored
                    ($0.totalLengthQuarters ?? 0) > 0 &&
                    (($0.catchType ?? "") == "Tournament")
                }
                newRows = filtered.map { c in
                    InchesDisplayRow(
                        id: UUID(),
                        catchID: c.id,
                        species: c.species,
                        clipColor: (c.clipColor ?? "RED").uppercased(),
                        quarters: c.totalLengthQuarters ?? 0
                    )
                }
            } catch {
                newRows = []
            }
            DispatchQueue.main.async { self.rows = newRows }
        }
    }


    // ===== Save Catch Information ====
    private func saveTournamentInchesCatch(
        species: String,
        clip: String,
        quarters: Int,
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
            totalLengthQuarters: quarters,
            totalLengthCm: nil,
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
    private func updateTournamentInches(
        row: InchesDisplayRow,
        species: String,
        clip: String,
        quarters: Int
    ) async {
        do {
            guard var item = try DatabaseManager.shared.getCatch(id: row.catchID) else { return }

            item.species = species
            item.clipColor = clip
            item.markerType = SpeciesUtils.TournamentSpeciesCode.markerType(for: species)
            item.totalLengthQuarters = quarters
            item.catchType = "Tournament"

            try DatabaseManager.shared.updateCatch(item)
            refreshFromDB()
        } catch {
            print("ERROR updating tournament catch:", error)
        }
    }

    private func deleteTournamentInches(row: InchesDisplayRow) {
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
    // ==== Available Clip Colors for edit ======
    private func availableClipColorsForEdit(row: InchesDisplayRow) -> [String] {
        var list = availableClipColorsTopN()

        //- Make sure current clip color is first option -
        let current = row.clipColor.uppercased()
        list.removeAll { $0.uppercased() == current }
        list.insert(current, at: 0)

        return list
    }

}

// MARK: - Rows (Android-style lane: clip • real • dec • species)
private struct TournamentInchesLane: View {
    let index: Int
    let row: InchesDisplayRow?
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

            let (real, dec) = InchesFmt.split(totalfourths: row?.quarters ?? 0)

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
                // -- DEC Value (as fraction) ---------
                (row != nil ?
                    Text(String(dec))
                        .font(.system(size: 45, weight: .bold).monospacedDigit())
                    + Text(" /4")
                        .font(.system(size: 30))  // smaller fraction text
                        .baselineOffset(-2)    // lowere so it looks like fraction
                : Text(""))
                    .foregroundStyle(fgColor)
                    .frame(width: 120, height: 54, alignment: .center)
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

// MARK: --- Add Catch Entry Sheet --
private struct TournamentInchesSheet: View {
    @Binding var isPresented: Bool

    let tournamentSpecies: String
    let speciesOptions: [String]
    let availableClipColors: [String]

    let onSave: (_ species: String, _ clip: String, _ quarters: Int) -> Void

    @State private var selectedSpecies: String = ""
    @State private var selectedClip: String = ""
    @State private var wholeText: String = ""
    @State private var decText: String = ""

    // Use the same NumberPad target convention as Pounds/Kgs:
    // .pounds = left box (whole inches), .ounces = right box (quarters 0–3)
    @State private var padTarget: NumberPad.Target = .pounds

    // ==== Converts REAL and DEC Values into INT for DB =====
    private var quarters: Int {
        (Int(wholeText) ?? 0) * 4 + (Int(decText) ?? 0)
    }

    private var canSave: Bool {
        quarters > 0 &&
        !selectedClip.isEmpty &&
        !selectedSpecies.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(spacing: 12) {
            Text("Tournament Catch Inches")
                .font(.headline)
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color.ltBrown)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .padding(.horizontal, 6)

            HStack {
                Text("Selected Species"); Spacer(); Text("Select Clip Color")
            }
            .font(.subheadline)
            .foregroundStyle(Color.black)
            .padding(.horizontal, 6)

            HStack(spacing: 10) {
                // Species menu
                Menu {
                    ForEach(speciesOptions, id: \.self) { s in
                        Button(s) { selectedSpecies = s }
                    }
                } label: {
                    pickerLabel(text: selectedSpecies.isEmpty ? "Select" : selectedSpecies)
                }

                Spacer(minLength: 8)

                // Clip color menu
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

            // Length Entry – Pounds-style: two display boxes + NumberPad
            VStack(alignment: .center, spacing: 2) {
                HStack(spacing: 1) {
                    // Whole inches (0–999)
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

                    // Quarters (0–3)
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

                    // " /4 Inches" label
                    (
                        Text(" /4")
                            .font(.caption)
                            .baselineOffset(-3)
                        + Text(" Inches")
                            .font(.title3.weight(.bold))
                    )
                    .foregroundStyle(.black)
                    .padding(.leading, 4)
                }

                HStack {
                    Spacer()
                    Text("XX X/4 Inches")
                        .font(.footnote)
                        .foregroundStyle(.black.opacity(0.75))
                    Spacer()
                }
            }
            .padding(.top, 6)
            .padding(.leading, 6)

            // Shared NumberPad (like Pounds/Kgs)
            NumberPad(
                text: padTarget == .pounds ? $wholeText : $decText,
                target: padTarget,
                maxLen: padTarget == .pounds ? 3 : 1,
                clampRange: padTarget == .ounces ? 0...3 : nil,
                onDone: {}
            )
            .background(Color.ltBrown.opacity(0.2))

            // Buttons
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
                            .stroke(Color.black, lineWidth: 3)
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
                            .stroke(Color.black, lineWidth: 3)
                    )
                    .disabled(!canSave)
                    .opacity(canSave ? 1 : 0.5)
            }
            .padding(.horizontal, 6)
            .padding(.bottom, 4)
        }
        .padding(.top, 6)
        .background(Color.ltBrown)
        .onAppear {
            selectedSpecies = speciesOptions.first ?? ""
            selectedClip = availableClipColors.first ?? ""
        }
    }

    // Sheet helpers (unchanged)
    private func pickerLabel(text: String) -> some View {
        HStack {
            Text(text)
                .font(.body.weight(.semibold))
                .foregroundStyle(.black)
                .lineLimit(1)
            Spacer()
            Image(systemName: "chevron.down")
                .foregroundStyle(.black.opacity(0.6))
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

    // These helpers are now unused but safe to keep if you want.
    private func seedZeroIfEmpty(_ s: inout String) { if s.isEmpty { s = "0" } }

    private func sanitize(_ s: inout String) {
        s = s.filter(\.isNumber)
        if s.count > 3 { s = String(s.prefix(3)) }
        if let v = Int(s) { s = String(min(max(v, 0), 999)) }
        if s.count > 1, s.hasPrefix("0") { s.removeFirst() }
    }

    private func sanitizeQuarters(_ s: inout String) {
        s = s.filter(\.isNumber)
        if s.count > 1 { s = String(s.prefix(1)) }  // single digit 0–3
        if let v = Int(s) { s = String(min(max(v, 0), 3)) }
    }

    private func commitSave() {
        onSave(
            normalizeSpecies(selectedSpecies),
            selectedClip.uppercased(),
            quarters
        )
        isPresented = false
    }

    private func normalizeSpecies(_ s: String) -> String {
        s.trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: "_", with: " ")
    }
}


// MARK: --- EDIT Tournament Inches Sheet (same look, pre-filled) ---
private struct EditTournamentInchesSheet: View {
    let row: InchesDisplayRow
    let speciesOptions: [String]
    let availableClipColors: [String]
    let onSave: (_ species: String, _ clip: String, _ quarters: Int) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var selectedSpecies: String = ""
    @State private var selectedClip: String = ""
    @State private var wholeText: String = ""
    @State private var decText: String = ""

    // Use the same NumberPad target convention:
    // .pounds = whole inches, .ounces = quarters (0–3)
    @State private var padTarget: NumberPad.Target = .pounds

    private var quarters: Int {
        (Int(wholeText) ?? 0) * 4 + (Int(decText) ?? 0)
    }

    private var canSave: Bool {
        quarters > 0 &&
        !selectedClip.isEmpty &&
        !selectedSpecies.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(spacing: 12) {
            Text("Edit Inches Catch")
                .font(.headline)
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color.veryLiteGrey)
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

            // Length Entry (Pounds-style)
            VStack(alignment: .center, spacing: 2) {
                HStack(spacing: 1) {
                    // Whole inches
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

                    // Quarters (0–3)
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

                    (
                        Text(" /4")
                            .font(.caption)
                            .baselineOffset(-3)
                        + Text(" Inches")
                            .font(.title3.weight(.bold))
                    )
                    .foregroundStyle(.black)
                    .padding(.leading, 4)
                }

                HStack {
                    Spacer()
                    Text("XX X/4 Inches")
                        .font(.footnote)
                        .foregroundStyle(.black.opacity(0.75))
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
                clampRange: padTarget == .ounces ? 0...3 : nil,
                onDone: {}
            )
            .background(Color.veryLiteGrey.opacity(0.2))

            // Buttons
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
                        .stroke(Color.black, lineWidth: 1)
                )

                Button("Save") {
                    onSave(
                        normalizeSpecies(selectedSpecies),
                        selectedClip.uppercased(),
                        quarters
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
                        .stroke(Color.black, lineWidth: 1)
                )
                .disabled(!canSave)
                .opacity(canSave ? 1 : 0.5)
            }
            .padding(.horizontal, 6)
            .padding(.bottom, 4)
        }
        .padding(.top, 6)
        .background(Color.ltBrown)
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

            // Length split into whole + quarter
            let (real, dec) = InchesFmt.split(totalfourths: row.quarters)
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
                .foregroundStyle(.black.opacity(0.6))
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

    private func seedZeroIfEmpty(_ s: inout String) { if s.isEmpty { s = "0" } }

    private func sanitize(_ s: inout String) {
        s = s.filter(\.isNumber)
        if s.count > 3 { s = String(s.prefix(3)) }
        if let v = Int(s) { s = String(min(max(v, 0), 999)) }
        if s.count > 1, s.hasPrefix("0") { s.removeFirst() }
    }

    private func sanitizeQuarters(_ s: inout String) {
        s = s.filter(\.isNumber)
        if s.count > 1 { s = String(s.prefix(1)) }  // single digit 0–3
        if let v = Int(s) { s = String(min(max(v, 0), 3)) }
    }

    private func normalizeSpecies(_ s: String) -> String {
        s.trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: "_", with: " ")
    }
}



#Preview {
    NavigationStack {
        CatchEntryTournamentInchesView()
    }
    .environmentObject(SettingsStore())
}



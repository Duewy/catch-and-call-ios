//
//  CatchEntryTournyKgsView.swift
//  CatchAndCall
//
//  Created by Dwayne Brame on 2025-11-04.
//
//  Pre-GPS baseline (save→append→insert→refresh)

import SwiftUI
import Foundation
internal import _LocationEssentials


// MARK: - Formatting & Mapping Helpers


private enum KgsFmt {
    static func split(totalKgsHundredths: Int) -> (real: Int, dec: Int) {
        (totalKgsHundredths / 100, totalKgsHundredths % 100)
    }
}

// MARK: - Display Row
private struct KgsDisplayRow: Identifiable, Equatable {
    let id: UUID
    let catchID: Int64
    let species: String
    let clipColor: String
    let hundredths: Int
}

// MARK: --- Main View ---------

struct CatchEntryTournamentKgsView: View {
    @EnvironmentObject var settings: SettingsStore
    
    // Rows rendered in the 6 tournament lanes
    @State private var rows: [KgsDisplayRow] = []
    
    // Add / Edit / Delete state
    @State private var showAdd = false
    @State private var editingItem: KgsDisplayRow? = nil
    @State private var confirmDelete: KgsDisplayRow? = nil

    // Blink state
    @State private var blinkTargetID: UUID? = nil
    @State private var blinkOn = false

    // Clip colors: source of truth is ClipColorUtils
    private var clipOrder: [String] { ClipColorUtils.activeClipOrder() }

    // Sorted by weight (heaviest first)
    private var sortedRows: [KgsDisplayRow] { rows.sorted { $0.hundredths > $1.hundredths } }
    
    // Top N tournament fish
    private var topN: [KgsDisplayRow] { Array(sortedRows.prefix(settings.tournamentLimit)) }
    
    //--- Set Values for Tourny Type --------
    private var totalReal: Int { topN.reduce(0) { $0 + $1.hundredths } / 100 }
    private var totalDec: Int { topN.reduce(0) { $0 + $1.hundredths } % 100 }
    private var smallestTopCatchID: UUID? { (topN.count == settings.tournamentLimit) ? topN.last?.id : nil }

    
    // === CatchEntryTournyKgsView Page =======
    
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
        .background(Color.halo_light_blue.ignoresSafeArea())
        
        // Add sheet (existing behaviour, unchanged)
        .sheet(isPresented: $showAdd) { addSheet }
        
        // Edit sheet (swipe → Edit)
        .sheet(item: $editingItem) { row in
            EditTournamentKgsSheet(
                row: row,
                speciesOptions: speciesOptionsFrom(settings.tournamentSpecies),
                availableClipColors: availableClipColorsForEdit(row: row)
            ) { newSpecies, newClip, newHundredths in
                Task {
                    await updateTournamentKgs(
                        row: row,
                        species: newSpecies,
                        clip: newClip,
                        hundredths: newHundredths
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
                    deleteTournamentKgs(row: row)
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
                .foregroundStyle(Color.clipWhite)
                .padding(.horizontal, 38)
                .padding(.vertical, 14)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color.clipBlue))
                .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.black, lineWidth: 3) )  // <-- border line
            }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 4)
    }

    // ---- Tournament Lanes as a List (supports swipe actions) ----
    private var lanes: some View {
        List {
            // Remove list separators + background
            ForEach(0..<6, id: \.self) { i in
                let item: KgsDisplayRow? =
                    (i < sortedRows.count) ? sortedRows[i] : nil

                TournamentKgsLane(
                    index: i,
                    row: item,
                    limit: settings.tournamentLimit,
                    pageBg: Color.halo_light_blue,
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
        .frame(height: 6 * 70)   // Approx height of your 6 lanes
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
            Text(String(format: "%02d", totalDec))
                .font(.system(size: 48, weight: .bold))
                .foregroundStyle(.black)
                .padding(.horizontal, 6)
                .background(Color.clipWhite)
                .clipShape(RoundedRectangle(cornerRadius: 6))
            Text("Kgs")
                .font(.system(size: 60, weight: .bold))
                .foregroundStyle(.black)
                .minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 2)
    }

    // ---- Show GPS & VCC Statues ---
    //TODO: Set Up Color Change on Value Settings
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
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color.clipBrightGreen))
                    .overlay(RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.black, lineWidth: 3)   // <-- border line
                            )
                    }
                    .buttonStyle(.plain)


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
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.black, lineWidth: 3)   // <-- border line
                    )
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    // MARK: Add Sheet (GPS-aware)
    private var addSheet: some View {
        TournamentKgsSheet(
            isPresented: $showAdd,
            tournamentSpecies: settings.tournamentSpecies,
            speciesOptions: speciesOptionsFrom(settings.tournamentSpecies),
            availableClipColors: availableClipColorsTopN()
        ) { species, clip, hundredths in

            if settings.gpsEnabled {
                LocationService.shared.requestCoordinate { coordinate in

                    // GPS failed → save without coordinates
                    guard let coordinate = coordinate else {
                        saveTournamentKgsCatch(
                            species: species,
                            clip: clip,
                            hundredths: hundredths,
                            latE7: nil,
                            lonE7: nil
                        )
                        return
                    }

                    let latE7 = Int(coordinate.latitude  * 10_000_000)
                    let lonE7 = Int(coordinate.longitude * 10_000_000)

                    saveTournamentKgsCatch(
                        species: species,
                        clip: clip,
                        hundredths: hundredths,
                        latE7: latE7,
                        lonE7: lonE7
                    )
                }

            } else {
                // GPS disabled → save without coords
                saveTournamentKgsCatch(
                    species: species,
                    clip: clip,
                    hundredths: hundredths,
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
            var newRows: [KgsDisplayRow] = []
            do {
                let today = try DatabaseManager.shared.getCatchesOn(date: Date())
                let filtered = today.filter {
                    ($0.totalWeightHundredthKg ?? 0) > 0 &&
                    (($0.catchType ?? "") == "Tournament")
                    }
                newRows = filtered.map { c in
                    KgsDisplayRow(
                        id: UUID(),
                        catchID: c.id,
                        species: c.species,
                        clipColor: (c.clipColor ?? "RED").uppercased(),
                        hundredths: c.totalWeightHundredthKg ?? 0
                    )
                }
            } catch {
                newRows = []
            }
            DispatchQueue.main.async { self.rows = newRows }
        }
    }

    // ===== Save Catch Information ====
    private func saveTournamentKgsCatch(
        species: String,
        clip: String,
        hundredths: Int,
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
            totalWeightHundredthKg: hundredths,
            totalLengthQuarters: nil,
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

    @MainActor
    private func updateTournamentKgs(
        row: KgsDisplayRow,
        species: String,
        clip: String,
        hundredths: Int
    ) async {
        do {
            guard var item = try DatabaseManager.shared.getCatch(id: row.catchID) else { return }

            item.species = species
            item.clipColor = clip
            item.markerType = SpeciesUtils.TournamentSpeciesCode.markerType(for: species)
            item.totalWeightHundredthKg = hundredths
            item.catchType = "Tournament"

            try DatabaseManager.shared.updateCatch(item)
            refreshFromDB()
        } catch {
            print("ERROR updating tournament catch:", error)
        }
    }

    private func deleteTournamentKgs(row: KgsDisplayRow) {
        do {
            try DatabaseManager.shared.deleteCatch(id: row.catchID)
            refreshFromDB()
        } catch {
            print("ERROR deleting tournament catch:", error)
        }
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

    // ==== Available Clip Colors EDIT/DELET ======
    private func availableClipColorsForEdit(row: KgsDisplayRow) -> [String] {
        var list = availableClipColorsTopN()

        // Make sure current clip color is first option
        let current = row.clipColor.uppercased()
        list.removeAll { $0.uppercased() == current }
        list.insert(current, at: 0)

        return list
    }


}

    // MARK: - Rows (Android-style lane: clip • real • dec • species)
    private struct TournamentKgsLane: View {
        let index: Int
        let row: KgsDisplayRow?
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

            let (real, dec) = KgsFmt.split(totalKgsHundredths: row?.hundredths ?? 0)

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
                // -- DEC Value ---------
                Text(row != nil ? String(format: "%02d", dec) : "")
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

// MARK: - Add Catch Sheet (Tournament Kgs)
private struct TournamentKgsSheet: View {
    @Binding var isPresented: Bool

    let tournamentSpecies: String
    let speciesOptions: [String]
    let availableClipColors: [String]

    let onSave: (_ species: String, _ clip: String, _ hundredths: Int) -> Void

    @State private var selectedSpecies: String = ""
    @State private var selectedClip: String = ""

    @State private var wholeText: String = ""
    @State private var decText: String = ""

    // Keep the enum defined so we don't break shared structure:
    private enum Field { case whole, dec }

    @State private var padTarget: NumberPad.Target = .pounds

    // Computed hundredths (same name used everywhere)
    private var hundredths: Int {
        (Int(wholeText) ?? 0) * 100 + (Int(decText) ?? 0)
    }

    private var canSave: Bool {
        hundredths > 0 &&
        !selectedSpecies.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !selectedClip.isEmpty
    }

    var body: some View {
        VStack(spacing: 12) {

            // ---- HEADER ----
            Text("Tournament Catch Kgs")
                .font(.headline)
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color.halo_light_blue)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .padding(.horizontal, 6)

            // ---- Species + Clip Row ----
            HStack {
                Text("Selected Species")
                Spacer()
                Text("Select Clip Color")
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 6)

            HStack(spacing: 10) {
                // Species Menu
                Menu {
                    ForEach(speciesOptions, id: \.self) { s in
                        Button(s) { selectedSpecies = s }
                    }
                } label: {
                    pickerLabel(text: selectedSpecies.isEmpty ? "Select" : selectedSpecies)
                }

                Spacer(minLength: 8)

                // Clip Color Menu
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
                            .overlay(RoundedRectangle(cornerRadius: 3)
                                .stroke(Color.black.opacity(0.95), lineWidth: 1))

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
                    .overlay(RoundedRectangle(cornerRadius: 8)
                        .stroke(.black.opacity(0.35)))
                }
            }
            .padding(.horizontal, 6)

            // ---- WEIGHT ENTRY using NumberPad ----
            VStack(alignment: .center, spacing: 6) {

                HStack(spacing: 6) {
                    Text("Kilograms")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.black)
                    Text("Hundredths (00–99)")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.black)
                }
                .padding(.bottom, 4)

                HStack(spacing: 6) {

                    // WHOLE KG
                    Text(wholeText.isEmpty ? "0" : wholeText)
                        .font(.system(size: 30, weight: .semibold))
                        .foregroundStyle(.black)
                        .frame(width: 70, height: 40)
                        .background(padTarget == .pounds ? Color.white : Color.veryLiteGrey)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10).stroke(
                                padTarget == .pounds ? Color.halo_light_blue : Color.veryLiteGrey,
                                lineWidth: 2
                            )
                        )
                        .onTapGesture {
                            padTarget = .pounds
                            wholeText = ""
                        }

                    Text("kg")
                        .foregroundStyle(.black)

                    // DECIMAL / HUNDREDTHS
                    Text(decText.isEmpty ? "00" : decText)
                        .font(.system(size: 30, weight: .semibold))
                        .foregroundStyle(.black)
                        .frame(width: 70, height: 40)
                        .background(padTarget == .ounces ? Color.white : Color.veryLiteGrey)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10).stroke(
                                padTarget == .ounces ? Color.halo_light_blue : Color.veryLiteGrey,
                                lineWidth: 2
                            )
                        )
                        .onTapGesture {
                            padTarget = .ounces
                            decText = ""
                        }

                    Text("hg")
                        .foregroundStyle(.black)
                }

                // ---- NumberPad ----
                NumberPad(
                    text: padTarget == .pounds ? $wholeText : $decText,
                    target: padTarget,
                    maxLen: padTarget == .pounds ? 3 : 2,
                    clampRange: padTarget == .ounces ? 0...99 : nil,
                    onDone: {}
                )
                .background(Color.halo_light_blue.opacity(0.2))
            }
            .padding(.top, 6)
            .padding(.leading, 6)

            // ---- Buttons Row ----
            HStack(spacing: 10) {
                Button("Cancel") {
                    isPresented = false
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

                Button("SAVE_CATCH") {
                    commitSave()
                }
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(Color.softlockBlue)
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
        .background(Color.halo_light_blue)
        .onAppear {
            selectedSpecies = speciesOptions.first ?? ""
            selectedClip = availableClipColors.first ?? ""
        }
    }

    // MARK: - Helpers
    private func pickerLabel(text: String) -> some View {
        HStack {
            Text(text)
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
        .overlay(RoundedRectangle(cornerRadius: 8)
            .stroke(.black.opacity(0.35)))
    }

    private func commitSave() {
        onSave(
            normalizeSpecies(selectedSpecies),
            selectedClip.uppercased(),
            hundredths
        )
        isPresented = false
    }

    private func normalizeSpecies(_ s: String) -> String {
        s.trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: "_", with: " ")
    }
}



// MARK: - Edit Tournament Kgs Sheet
private struct EditTournamentKgsSheet: View {
    let row: KgsDisplayRow
    let speciesOptions: [String]
    let availableClipColors: [String]
    let onSave: (_ species: String, _ clip: String, _ hundredths: Int) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var selectedSpecies: String = ""
    @State private var selectedClip: String = ""

    @State private var wholeText: String = ""
    @State private var decText: String = ""

    private enum Field { case whole, dec }
    @State private var padTarget: NumberPad.Target = .pounds

    private var hundredths: Int {
        (Int(wholeText) ?? 0) * 100 + (Int(decText) ?? 0)
    }

    private var canSave: Bool {
        hundredths > 0 &&
        !selectedClip.isEmpty &&
        !selectedSpecies.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(spacing: 12) {
            Text("Edit Kgs Catch")
                .font(.headline)
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color.clipVeryGreen)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .padding(.horizontal, 6)

            // ---- Species + Clip ----
            HStack {
                Text("Selected Species")
                Spacer()
                Text("Select Clip Color")
            }
            .font(.subheadline)
            .foregroundStyle(.black)
            .padding(.horizontal, 6)

            HStack(spacing: 10) {
                // Species Menu
                Menu {
                    ForEach(speciesOptions, id: \.self) { s in
                        Button(s) { selectedSpecies = s }
                    }
                } label: {
                    pickerLabel(text: selectedSpecies.isEmpty ? "Select" : selectedSpecies)
                }

                Spacer(minLength: 8)

                // Clip Color Menu
                Menu {
                    ForEach(availableClipColors, id: \.self) { c in
                        Button { selectedClip = c } label: {
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
                            .overlay(RoundedRectangle(cornerRadius: 3)
                                .stroke(Color.black.opacity(0.95), lineWidth: 1))

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
                    .overlay(RoundedRectangle(cornerRadius: 8)
                        .stroke(.black.opacity(0.35)))
                }
            }
            .padding(.horizontal, 6)

            // ---- WEIGHT ENTRY (NumberPad) ----
            VStack(alignment: .center, spacing: 6) {

                HStack(spacing: 6) {
                    Text("Kilograms")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.black)
                    Text("Hundredths (00–99)")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.black)
                }
                .padding(.bottom, 4)

                HStack(spacing: 6) {

                    // Whole KG
                    Text(wholeText.isEmpty ? "0" : wholeText)
                        .font(.system(size: 30, weight: .semibold))
                        .foregroundStyle(.black)
                        .frame(width: 70, height: 40)
                        .background(padTarget == .pounds ? Color.white : Color.veryLiteGrey)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(padTarget == .pounds ? Color.halo_light_blue : Color.veryLiteGrey,
                                        lineWidth: 2)
                        )
                        .onTapGesture {
                            padTarget = .pounds
                            wholeText = ""
                        }

                    Text("kg")
                        .foregroundStyle(.black)

                    // Decimal KG (hundredths)
                    Text(decText.isEmpty ? "00" : decText)
                        .font(.system(size: 30, weight: .semibold))
                        .foregroundStyle(.black)
                        .frame(width: 70, height: 40)
                        .background(padTarget == .ounces ? Color.white : Color.veryLiteGrey)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(padTarget == .ounces ? Color.halo_light_blue : Color.veryLiteGrey,
                                        lineWidth: 2)
                        )
                        .onTapGesture {
                            padTarget = .ounces
                            decText = ""
                        }

                    Text("hg")
                        .foregroundStyle(.black)
                }

                NumberPad(
                    text: padTarget == .pounds ? $wholeText : $decText,
                    target: padTarget,
                    maxLen: padTarget == .pounds ? 3 : 2,
                    clampRange: padTarget == .ounces ? 0...99 : nil,
                    onDone: {}
                )
                .background(Color.halo_light_blue.opacity(0.2))
            }
            .padding(.top, 6)
            .padding(.leading, 6)

            // ---- BUTTONS ----
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
                        hundredths
                    )
                    dismiss()
                }
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(Color.softlockBlue)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.black, lineWidth: 2)
                )
                .disabled(!canSave)
                .opacity(canSave ? 1 : 0.5)
            }
            .padding(.horizontal, 6)
            .padding(.bottom, 4)
        }
        .padding(.top, 6)
        .background(Color.halo_light_blue)
        .onAppear {
            // species
            if let idx = speciesOptions.firstIndex(where: {
                $0.trimmingCharacters(in: .whitespacesAndNewlines)
                    .lowercased() == row.species.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            }) {
                selectedSpecies = speciesOptions[idx]
            } else {
                selectedSpecies = speciesOptions.first ?? ""
            }

            // clip
            selectedClip = row.clipColor.uppercased()

            // weight load
            let (real, dec) = KgsFmt.split(totalKgsHundredths: row.hundredths)
            wholeText = String(real)
            decText = String(format: "%02d", dec)
        }
    }

    private func pickerLabel(text: String) -> some View {
        HStack {
            Text(text)
                .font(.body.weight(.semibold))
                .foregroundStyle(.black)
            Spacer()
            Image(systemName: "chevron.down").foregroundStyle(.black.opacity(0.75))
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .frame(minWidth: 160)
        .background(Color.veryLiteGrey.opacity(0.85))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8)
            .stroke(.black.opacity(0.35)))
    }

    private func normalizeSpecies(_ s: String) -> String {
        s.trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: "_", with: " ")
    }


//=== END === EDIT / DELETE Sheet =========
}
// === END ==== CatchEntryTournyKgsView.swift =======

#Preview {
    NavigationStack {
        CatchEntryTournamentKgsView()
    }
    .environmentObject(SettingsStore())
}


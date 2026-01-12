
//  CatchEntryTournyLbsView.swift
//  CatchAndCall
//
//  Created by Dwayne Brame on 2025-11-04.
//
//
//  Pre-GPS baseline (save→append→insert→refresh)
//  Tournament Catch Entry using Lbs/Ozs (total ounces stored)

import SwiftUI
import Foundation
import Combine
internal import _LocationEssentials

// MARK: - Formatting & Mapping Helpers

    //-- Split total ounces into (lbs, oz) --
private enum LbsOzFmt {
    static func split(totalOz: Int) -> (real: Int, dec: Int) {
        let lbs = totalOz / 16
        let oz  = totalOz % 16
        return (lbs, oz)
    }
}

// MARK: - Display Row
private struct LbsDisplayRow: Identifiable, Equatable {
    let id: UUID
    let catchID: Int64
    let species: String
    let clipColor: String
    let totalOz: Int
}

// MARK: --- Main View ---------

struct CatchEntryTournamentLbsView: View {
    
private var voiceCoordinator =
        VoiceSessionCoordinator(voiceManager: VoiceManager())
    
    @AppStorage("voiceEnabled") private var voiceEnabled = true
    @State private var toastText: String? = nil

    
    @EnvironmentObject var settings: SettingsStore

    @State private var rows: [LbsDisplayRow] = []

    // Add / Edit / Delete state
    @State private var showAdd = false
    @State private var editingItem: LbsDisplayRow? = nil
    @State private var confirmDelete: LbsDisplayRow? = nil

    // Blink state
    @State private var blinkTargetID: UUID? = nil
    @State private var blinkOn = false


    // Clip colors: source of truth is ClipColorUtils
    private var clipOrder: [String] { ClipColorUtils.activeClipOrder() }

    // Sorted by weight (heaviest first)
    private var sortedRows: [LbsDisplayRow] { rows.sorted { $0.totalOz > $1.totalOz } }
    // Top N tournament fish
    private var topN: [LbsDisplayRow] { Array(sortedRows.prefix(settings.tournamentLimit)) }

    //--- Set Values for Tourny Type (Lbs/Ozs) --------
    private var totalReal: Int {
        let sumOz = topN.reduce(0) { $0 + $1.totalOz }
        return sumOz / 16
    }
    private var totalDec: Int {
        let sumOz = topN.reduce(0) { $0 + $1.totalOz }
        return sumOz % 16
    }
    
    // The lightest fish in the current top N (for blink target)
    private var smallestTopCatchID: UUID? {
        (topN.count == settings.tournamentLimit) ? topN.last?.id : nil
    }

    
    // MARK:  === CatchEntryTournamentLbsView Page =======

    var body: some View {
        ScrollView {

            VStack(alignment: .leading, spacing: 8) {
                header
                addCatchButtonRow
                lanes
                totals
                statusBar
                navButtons
            }
            .padding(.horizontal, 12)
            .padding(.top, 8)
        }
        .background(Color.softlockGreen.ignoresSafeArea())
        .overlay(       // For the Toast Popup
            Group {
                if let toastText {
                    VStack {
                        ToastBanner(text: toastText)
                        Spacer()
                    }
                    .padding(.top, 12)
                    .transition(.opacity)
                }
            }
        )

        // --- ADD sheet --------
        .sheet(isPresented: $showAdd) {
            addSheet
        }

        // -------- EDIT sheet (swipe → Edit)--------
        .sheet(item: $editingItem) { row in
            EditTournamentLbsSheet(
                row: row,
                speciesOptions: speciesOptionsFrom(settings.tournamentSpecies),
                availableClipColors: availableClipColorsForEdit(row: row)
            ) { newSpecies, newClip, newTotalOz in
                Task {
                    await updateTournamentLbs(
                        row: row,
                        species: newSpecies,
                        clip: newClip,
                        totalOz: newTotalOz
                    )
                }
            }
        }

        //-------- DELETE confirmation (swipe → Delete)--------
        .alert(item: $confirmDelete) { row in
            Alert(
                title: Text("Delete this catch?"),
                message: Text("This will remove it from your tournament."),
                primaryButton: .destructive(Text("Delete")) {
                    deleteTournamentLbs(row: row)
                },
                secondaryButton: .cancel()
            )
        }
        
        .onAppear {
            guard settings.voiceControlEnabled else { return }

            VCRemoteTransport.bindPlayPause {
                print("🎧 Play/Pause received — starting tournament VC")
                voiceCoordinator.startSession(mode: .tournament)
            }

            print("🎧 VC armed — waiting for Play/Pause")
        }

        .onDisappear {
            VCRemoteTransport.unbind()
            voiceCoordinator.endSession(reason: "view disappeared")
        }

        .onReceive(
            NotificationCenter.default.publisher(for: .remotePlayPausePressed)
        ) { _ in
            guard settings.voiceControlEnabled else { return }
            guard !showAdd, editingItem == nil else { return }
            voiceCoordinator.startSession(mode: .tournament)

        }
        // Data flow
        .onChange(of: showAdd) { isOpen in if !isOpen { refreshFromDB() } }
        .onChange(of: settings.tournamentLimit) { _ in maybeBlinkOnChange() }
        .onChange(of: topN.map { $0.id }) { _ in maybeBlinkOnChange() }
       
        
    }// === END == VIEW ==========
        

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
    private var addCatchButtonRow: some View {
        HStack(spacing: 12) {
            
            // --- ADD CATCH (manual) ---
            Button { showAdd = true } label: {
                Text("ADD CATCH")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(Color.clipWhite)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.softlockBlue)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.black, lineWidth: 3)
                    )
            }
        }
            .padding(.horizontal, 45)
            .padding(.bottom, 4)
        }
//---------------------------------
    private func showToast(_ text: String) {
        withAnimation { toastText = text }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation { toastText = nil }
        }
    }

    // ---- Tournament Lanes as a List (supports swipe actions) ----
    private var lanes: some View {
        List {
            ForEach(0..<6, id: \.self) { i in
                let item: LbsDisplayRow? =
                    (i < sortedRows.count) ? sortedRows[i] : nil

                TournamentLbsLane(
                    index: i,
                    row: item,
                    limit: settings.tournamentLimit,
                    pageBg: Color.brightGreen,          // Set Background Color for Measurment Mode
                    isBlink: item?.id == blinkTargetID,
                    blinkOn: blinkOn
                )
                .listRowInsets(EdgeInsets(top: 11, leading: 21, bottom: 0, trailing: 0))
                .listRowBackground(Color.clear)
                .swipeActions(edge: .trailing) {
                    if let item = item {
                        Button("Edit") {
                            editingItem = item
                        }
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
        .frame(height: 6 * 70)  // Approx height of your 6 lanes
    }          // TODO: Check that the sizing flows with differnt screen sizes

    
    // ---- Show TOTAL Value ------
    private var totals: some View {
        HStack(spacing: 6) {
            Text("\(totalReal)")
                .font(.system(size: 48, weight: .bold))
                .foregroundStyle(.black)
                .padding(.horizontal, 6)
                .background(Color.clipWhite)
                .clipShape(RoundedRectangle(cornerRadius: 6))
            Text("Lbs")
                .font(.system(size: 60, weight: .bold))
                .foregroundStyle(.black)
                .baselineOffset(2)
            Text(String(format: "%02d", totalDec))
                .font(.system(size: 48, weight: .bold))
                .foregroundStyle(.black)
                .padding(.horizontal, 6)
                .background(Color.clipWhite)
                .clipShape(RoundedRectangle(cornerRadius: 6))
            Text("oz")
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
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.logGreenSecondary)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.black, lineWidth: 3)   // <-- border line
                    )
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
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.blue)
                    )
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

    // MARK: --- Add Catch PopUp Sheet (GPS-aware) ---
    
    private var addSheet: some View {
        TournamentLbsSheet(
            isPresented: $showAdd,
            tournamentSpecies: settings.tournamentSpecies,
            speciesOptions: speciesOptionsFrom(settings.tournamentSpecies),
            availableClipColors: availableClipColorsTopN()
        ) { species, clip, totalOz in

            if settings.gpsEnabled {
                // Request a location for tournament catch
                LocationService.shared.requestCoordinate { coordinate in
                    guard let coordinate = coordinate else {
                        // If GPS fails → save without coordinates
                        saveTournamentLbsCatch(
                            species: species,
                            clip: clip,
                            totalOz: totalOz,
                            latE7: nil,
                            lonE7: nil
                        )
                        return
                    }

                    let latE7 = Int(coordinate.latitude  * 10_000_000)
                    let lonE7 = Int(coordinate.longitude * 10_000_000)

                    saveTournamentLbsCatch(
                        species: species,
                        clip: clip,
                        totalOz: totalOz,
                        latE7: latE7,
                        lonE7: lonE7
                    )
                }
            } else {
                // GPS disabled in SetUp → save without coords
                saveTournamentLbsCatch(
                    species: species,
                    clip: clip,
                    totalOz: totalOz,
                    latE7: nil,
                    lonE7: nil
                )
            }
        }
        .presentationDetents([.large])
    }


    // MARK: === Add Catch to DB Load / Save / Update / Delete ====
    private func refreshFromDB() {
        DispatchQueue.global(qos: .userInitiated).async {
            var newRows: [LbsDisplayRow] = []
            do {
                let today = try DatabaseManager.shared.getCatchesOn(date: Date())
                let filtered = today.filter {
                    (($0.totalWeightOz ?? 0) > 0) &&
                    (($0.catchType ?? "") == "Tournament")
                }
                newRows = filtered.map { c in
                    LbsDisplayRow(
                        id: UUID(),
                        catchID: c.id,
                        species: c.species,
                        clipColor: (c.clipColor ?? "RED").uppercased(),
                        totalOz: c.totalWeightOz ?? 0
                    )
                }
            } catch {
                newRows = []
            }
            DispatchQueue.main.async { self.rows = newRows }
        }
    }

    // ===== Save Catch Information ====
    private func saveTournamentLbsCatch(
        species: String,
        clip: String,
        totalOz: Int,
        latE7: Int?,
        lonE7: Int?
    ) {
        let nowSec = Int64(Date().timeIntervalSince1970)

      
        // -- Persist -build the CatchItem and insert into SQLite ---
        let item = CatchItem(
            id: 0,
            dateTimeSec: nowSec,
            species: species,
            totalWeightOz: totalOz,
            totalWeightPoundsHundredth: nil,
            totalWeightHundredthKg: nil,
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
        //TODO: check to see if it is just refreshFromDB() and then triggerBlink()
        // Reconcile with DB & blink
        DispatchQueue.main.async {
            self.refreshFromDB()
            self.triggerBlink()
        }
    }

    // === Update Catch Total Values ====
    @MainActor
    private func updateTournamentLbs(
        row: LbsDisplayRow,
        species: String,
        clip: String,
        totalOz: Int
    ) async {
        do {
            guard var item = try DatabaseManager.shared.getCatch(id: row.catchID) else { return }

            item.species = species
            item.clipColor = clip
            item.markerType = SpeciesUtils.TournamentSpeciesCode.markerType(for: species)
            item.totalWeightOz = totalOz
            item.catchType = "Tournament"

            try DatabaseManager.shared.updateCatch(item)
            refreshFromDB()
        } catch {
            print("ERROR updating Lbs/Oz tournament catch:", error)
        }
    }

    //===== DELETE Catch Value ========
    private func deleteTournamentLbs(row: LbsDisplayRow) {
        do {
            try DatabaseManager.shared.deleteCatch(id: row.catchID)
            refreshFromDB()
        } catch {
            print("ERROR deleting Lbs/Oz tournament catch:", error)
        }
    }


    // MARK: Species & Clip Helpers

    //===  Get and List Species from SetUp page ====
    private func speciesOptionsFrom(_ tournamentSpecies: String) -> [String] {
        let key = tournamentSpecies
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

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

  //--- Ajust the Characters to Caps ---
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

    private func availableClipColorsForEdit(row: LbsDisplayRow) -> [String] {
        var list = availableClipColorsTopN()

        // Ensure current clip color is kept as first option
        let current = row.clipColor.uppercased()
        list.removeAll { $0.uppercased() == current }
        list.insert(current, at: 0)

        return list
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
    
}//=== END ==== CatchEntry ===========


// MARK: - Rows (Android-style lane: clip • lbs • oz • species)
private struct TournamentLbsLane: View {
    let index: Int
    let row: LbsDisplayRow?
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

            let (real, dec) = LbsOzFmt.split(totalOz: row?.totalOz ?? 0)

            HStack(spacing: 0) {
                //-- Clip Color Letter ---
                Text(row?.clipColor.first.map { String($0) } ?? "")
                    .font(.system(size: 40, weight: .regular))
                    .foregroundStyle(row != nil ? fgColor : .black)
                    .frame(width: 44, height: 54)
                    .background(bgColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.black.opacity(0.58))
                    )
                    .padding(.leading, 10)
                    .padding(.trailing, 5)

                // -- REAL Value (Lbs) --------
                Text(row != nil ? String(real) : "")
                    .font(.system(size: 45, weight: .bold).monospacedDigit())
                    .foregroundStyle(fgColor)
                    .frame(width: 120, height: 54)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(bgColor)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.black.opacity(0.58))
                    )
                
                // -- DEC Value (Oz) ---------
                Text(row != nil ? String(format: "%02d", dec) : "")
                    .font(.system(size: 45, weight: .bold).monospacedDigit())
                    .foregroundStyle(fgColor)
                    .frame(width: 120, height: 54)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(bgColor)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.black.opacity(0.58))
                    )
                
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

// MARK: --- Add Catch Sheet (Lbs/Ozs) ---

private struct TournamentLbsSheet: View {
    @Binding var isPresented: Bool

    let tournamentSpecies: String
    let speciesOptions: [String]
    let availableClipColors: [String]

    let onSave: (_ species: String, _ clip: String, _ totalOz: Int) -> Void

    @State private var selectedSpecies: String = ""
    @State private var selectedClip: String = ""
    @State private var wholeText: String = ""   // lbs
    @State private var decText: String = ""     // oz
    @FocusState private var focus: Field?
    private enum Field { case whole, dec }
    @State private var padTarget: NumberPad.Target = .pounds

    private var parsedLbs: Int { Int(wholeText) ?? 0 }
    private var parsedOz:  Int { Int(decText) ?? 0 }

    private var totalOzComputed: Int {
        parsedLbs * 16 + parsedOz
    }
    
    private var canSave: Bool {
        totalOzComputed > 0 &&
        !selectedClip.isEmpty &&
        !selectedSpecies.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Tournament Catch (Lbs/Ozs)")
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
                // Species selection
                Menu {
                    ForEach(speciesOptions, id: \.self) { s in
                        Button(s) { selectedSpecies = s }
                    }
                } label: {
                    pickerLabel(text: selectedSpecies.isEmpty ? "Select" : selectedSpecies)
                }

                Spacer(minLength: 8)

                //-- Clip Color selection ---
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

            // Weight entry (lbs / oz)
            VStack(alignment: .center, spacing: 6) {

                HStack(spacing: 6) {
                    Text("Pounds")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.black)
                    Text("Ounces (0–15)")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.black)
                }
                .padding(.bottom, 4)

                HStack(spacing: 6) {

                    // ---- POUNDS ----
                    Text(wholeText.isEmpty ? "0" : wholeText)
                        .font(.system(size: 30, weight: .semibold))
                        .foregroundStyle(.black)
                        .frame(width: 60, height: 40)
                        .background(padTarget == .pounds ? Color.white : Color.veryLiteGrey)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(padTarget == .pounds ? Color.softlockGreen : Color.veryLiteGrey, lineWidth: 2)
                        )
                        .onTapGesture {
                            padTarget = .pounds
                            wholeText = ""
                        }

                    Text("lb")
                        .foregroundStyle(.black)

                    // ---- OUNCES ----
                    Text(decText.isEmpty ? "0" : decText)
                        .font(.system(size: 30, weight: .semibold))
                        .foregroundStyle(.black)
                        .frame(width: 60, height: 40)
                        .background(padTarget == .ounces ? Color.white : Color.veryLiteGrey)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(padTarget == .ounces ? Color.softlockGreen : Color.veryLiteGrey, lineWidth: 2)
                        )
                        .onTapGesture {
                            padTarget = .ounces
                            decText = ""
                        }

                    Text("oz")
                        .foregroundStyle(.black)
                }

                // -------- NumberPad wired to active target --------
                NumberPad(
                    text: padTarget == .pounds ? $wholeText : $decText,
                    target: padTarget,
                    maxLen: padTarget == .pounds ? 3 : 2,
                    clampRange: padTarget == .ounces ? 0...15 : nil,
                    onDone: {}
                )
                .background(Color.softlockSand)
            }
            .padding(.top, 6)
            .padding(.leading, 6)

            HStack(spacing: 10) {
                //----- CANCEL Button -------
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

                //---- SAVE CATCH Button -------
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
        .onAppear {
            selectedSpecies = speciesOptions.first ?? ""
            selectedClip   = availableClipColors.first ?? ""
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { focus = .whole }
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { focus = nil }
            }
        }
        .background(Color.softlockGreen)
    }// ==== END === TournamentLbsSheet ========
    
    // Helpers (Add sheet)
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

   

    private func seedZeroIfEmpty(_ s: inout String) {
        if s.isEmpty { s = "0" }
    }

    private func sanitize(_ s: inout String) {
        s = s.filter(\.isNumber)
        if s.count > 2 { s = String(s.prefix(2)) }
        if let v = Int(s) {
            s = String(min(max(v, 0), 99))
        }
        if s.count > 1, s.hasPrefix("0") {
            s.removeFirst()
        }
    }

    private func commitSave() {
        onSave(
            normalizeSpecies(selectedSpecies),
            selectedClip.uppercased(),
            totalOzComputed
        )
        isPresented = false
    }

    private func normalizeSpecies(_ s: String) -> String {
        s.trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: "_", with: " ")
    }
}

    
    //MARK: ------- EDIT Catch Entry ----------
    
private struct EditTournamentLbsSheet: View {
    let row: LbsDisplayRow
    let speciesOptions: [String]
    let availableClipColors: [String]
    let onSave: (_ species: String, _ clip: String, _ totalOz: Int) -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedSpecies: String = ""
    @State private var selectedClip: String = ""
    @State private var wholeText: String = ""   // lbs
    @State private var decText: String = ""     // oz
    @FocusState private var focus: Field?
    private enum Field { case whole, dec }
    @State private var padTarget: NumberPad.Target = .pounds

    private var parsedLbs: Int { Int(wholeText) ?? 0 }
    private var parsedOz: Int { Int(decText) ?? 0 }
    private var totalOzComputed: Int { parsedLbs * 16 + parsedOz }

    private var totalOz: Int {
        (Int(wholeText) ?? 0) * 16 + (Int(decText) ?? 0)
    }
    
    private var canSave: Bool {
        totalOz > 0 &&
        !selectedClip.isEmpty &&
        !selectedSpecies.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Edit Tournament Catch (Lbs/Oz)")
                .font(.headline)
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color.softlockSand)
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
            
            // Weight entry (FunDay-style NumberPad)
            VStack(alignment: .center, spacing: 6) {

                HStack(spacing: 6) {
                    Text("Pounds")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.black)
                    Text("Ounces (0–15)")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.black)
                }
                .padding(.bottom, 4)

                HStack(spacing: 6) {

                    // ---- POUNDS ----
                    Text(wholeText.isEmpty ? "0" : wholeText)
                        .font(.system(size: 30, weight: .semibold))
                        .foregroundStyle(.black)
                        .frame(width: 60, height: 40)
                        .background(padTarget == .pounds ? Color.white : Color.veryLiteGrey)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(padTarget == .pounds ? Color.softlockGreen : Color.veryLiteGrey, lineWidth: 2)
                        )
                        .onTapGesture {
                            padTarget = .pounds
                            wholeText = ""
                        }

                    Text("lb")
                        .foregroundStyle(.black)

                    // ---- OUNCES ----
                    Text(decText.isEmpty ? "0" : decText)
                        .font(.system(size: 30, weight: .semibold))
                        .foregroundStyle(.black)
                        .frame(width: 60, height: 40)
                        .background(padTarget == .ounces ? Color.white : Color.veryLiteGrey)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(padTarget == .ounces ? Color.softlockGreen : Color.veryLiteGrey, lineWidth: 2)
                        )
                        .onTapGesture {
                            padTarget = .ounces
                            decText = ""
                        }

                    Text("oz")
                        .foregroundStyle(.black)
                }

                // -------- NumberPad wired to active target --------
                NumberPad(
                    text: padTarget == .pounds ? $wholeText : $decText,
                    target: padTarget,
                    maxLen: padTarget == .pounds ? 3 : 2,
                    clampRange: padTarget == .ounces ? 0...15 : nil,
                    onDone: {}
                )
                .background(Color.softlockSand)
            }
            .padding(.top, 6)
            .padding(.leading, 6)

            
            HStack(spacing: 10) {
                Button("Cancel") { dismiss() }
                    .font(.headline)
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .background(Color.veryLiteGrey.opacity(0.9))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.black, lineWidth: 3)
                    )
                
                Button("SAVE CHANGES") { commitSave() }
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
        .onAppear(perform: prefillFields)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { focus = nil }
            }
        }
        .background(Color.softlockGreen)
    }
    
    // MARK: - Helpers
    
    private func prefillFields() {
        // Convert total ounces back to lbs / oz
        let lbs = row.totalOz / 16
        let oz = row.totalOz % 16
        
        wholeText = String(lbs)
        decText = String(oz)
        
        // Species: best guess matches existing row
        let prettySpecies = row.species
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .split(separator: " ")
            .map { $0.capitalized }
            .joined(separator: " ")
        
        if speciesOptions.contains(prettySpecies) {
            selectedSpecies = prettySpecies
        } else {
            selectedSpecies = speciesOptions.first ?? prettySpecies
        }
        
        selectedClip = availableClipColors.first ?? row.clipColor
        focus = .whole
    }
    
    
    private func seedZeroIfEmpty(_ s: inout String) {
        if s.isEmpty { s = "0" }
    }
    
 
    private func commitSave() {
        let speciesNorm = normalizeSpecies(selectedSpecies)
        let clipUpper = selectedClip.uppercased()
        onSave(speciesNorm, clipUpper, totalOz)
        dismiss()
    }
    
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
        CatchEntryTournamentLbsView()
    }
    .environmentObject(SettingsStore())
}

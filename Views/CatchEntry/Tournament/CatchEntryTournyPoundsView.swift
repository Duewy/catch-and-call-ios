//
//  CatchEntryTournyPoundsView.swift
//  CatchAndCall
//
//  Tournament – Pounds.hh (hundredths of pounds)
//

import SwiftUI
import Foundation
internal import _LocationEssentials


// MARK: - Formatting Helpers
private enum LbsFmt {
    static func split(totalHundredths: Int) -> (real: Int, dec: Int) {
        (totalHundredths / 100, totalHundredths % 100)
    }
}

// MARK: - Display Row for UI
private struct PoundsDisplayRow: Identifiable, Equatable {
    let id: UUID          // UI row id
    let catchID: Int64    // REAL DB id
    let species: String
    let clipColor: String
    let hundredths: Int
}

// MARK: - Main View
struct CatchEntryTournamentPoundsView: View {


    
    @EnvironmentObject var settings: SettingsStore

    // Rows rendered in the 6 tournament lanes
    @State private var rows: [PoundsDisplayRow] = []

    // Add / Edit / Delete state
    @State private var showAdd: Bool = false
    @State private var editingItem: PoundsDisplayRow? = nil
    @State private var confirmDelete: PoundsDisplayRow? = nil

    // Blink state
    @State private var blinkTargetID: UUID? = nil
    @State private var blinkOn: Bool = false

    // Clip colors (global order)
    private var clipOrder: [String] { ClipColorUtils.activeClipOrder() }

    // Sorted by weight (heaviest first)
    private var sortedRows: [PoundsDisplayRow] {
        rows.sorted { $0.hundredths > $1.hundredths }
    }

    // Top N tournament fish
    private var topN: [PoundsDisplayRow] {
        Array(sortedRows.prefix(settings.tournamentLimit))
    }

    // Totals across top N
    private var totalReal: Int {
        topN.reduce(0) { $0 + $1.hundredths } / 100
    }
    private var totalDec: Int {
        topN.reduce(0) { $0 + $1.hundredths } % 100
    }

    // The lightest fish in the current top N (for blink target)
    private var smallestTopCatchID: UUID? {
        (topN.count == settings.tournamentLimit) ? topN.last?.id : nil
    }

    // MARK: - Body
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
        .background(Color.clipVeryGreen.ignoresSafeArea())

        // Add sheet (existing behaviour, unchanged)
        .sheet(isPresented: $showAdd) {
            addSheet
        }

        // Edit sheet (swipe → Edit)
        .sheet(item: $editingItem) { row in
            EditTournamentPoundsSheet(
                row: row,
                speciesOptions: speciesOptionsFrom(settings.tournamentSpecies),
                availableClipColors: availableClipColorsForEdit(row: row)
            ) { newSpecies, newClip, newHundredths in
                Task {
                    await updateTournamentPounds(
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
                    deleteTournamentPounds(row: row)
                },
                secondaryButton: .cancel()
            )
        }

        // Data flow
        .onAppear(perform: refreshFromDB)
        .onChange(of: showAdd) { isOpen in
            if !isOpen { refreshFromDB() }
        }
        .onChange(of: settings.tournamentLimit) { _ in
            maybeBlinkOnChange()
        }
        .onChange(of: topN.map { $0.id }) { _ in
            maybeBlinkOnChange()
        }
    }

    // MARK: - Sections

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

    
    private var addCatchButton: some View {
        Button {
            showAdd = true
        } label: {
            Text("ADD CATCH")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(Color.clipWhite)
                .padding(.horizontal, 40)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.softlockGreen)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.black, lineWidth: 3)  // <-- border line
                )
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 4)
        
    }

    // ---- Tournament Lanes as a List (supports swipe actions) ----
    private var lanes: some View {
        List {
            // Remove list separators + background
            ForEach(0..<6, id: \.self) { i in
                let item: PoundsDisplayRow? =
                    (i < sortedRows.count) ? sortedRows[i] : nil

                TournamentPoundsLane(
                    index: i,
                    row: item,
                    limit: settings.tournamentLimit,
                    pageBg: Color.clipVeryGreen,
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

            Text("lbs")
                .font(.system(size: 60, weight: .bold))
                .foregroundStyle(.black)
                .minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 2)
    }

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

    private var navButtons: some View {
        HStack(spacing: 12) {
            NavigationLink {
                MainMenuView()
            } label: {
                Text("Main Page")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(height: 50)
                    .padding(.horizontal, 24)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.green)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.black, lineWidth: 3)   // <-- border line
                    )
            }
            .buttonStyle(.plain)

            NavigationLink {
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

    // MARK: - Add Sheet wrapper (existing Add popup, unchanged)

    private var addSheet: some View {
        TournamentPoundsSheet(
            isPresented: $showAdd,
            tournamentSpecies: settings.tournamentSpecies,
            speciesOptions: speciesOptionsFrom(settings.tournamentSpecies),
            availableClipColors: availableClipColorsTopN()
        ) { species, clip, hundredths in

            if settings.gpsEnabled {
                LocationService.shared.requestCoordinate { coordinate in
                    guard let coordinate = coordinate else {
                        saveTournamentPoundsCatch(
                            species: species,
                            clip: clip,
                            hundredths: hundredths,
                            latE7: nil,
                            lonE7: nil
                        )
                        return
                    }

                    let latE7 = Int(coordinate.latitude * 10_000_000)
                    let lonE7 = Int(coordinate.longitude * 10_000_000)

                    saveTournamentPoundsCatch(
                        species: species,
                        clip: clip,
                        hundredths: hundredths,
                        latE7: latE7,
                        lonE7: lonE7
                    )
                }
            } else {
                saveTournamentPoundsCatch(
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

    // MARK: - DB: Load / Save / Update / Delete

    private func refreshFromDB() {
        DispatchQueue.global(qos: .userInitiated).async {
            var newRows: [PoundsDisplayRow] = []
            do {
                let today = try DatabaseManager.shared.getCatchesOn(date: Date())
                let filtered = today.filter {
                    ($0.totalWeightPoundsHundredth ?? 0) > 0 &&
                    (($0.catchType ?? "") == "Tournament")
                }

                newRows = filtered.map { c in
                    PoundsDisplayRow(
                        id: UUID(),
                        catchID: c.id,
                        species: c.species,
                        clipColor: (c.clipColor ?? "RED").uppercased(),
                        hundredths: c.totalWeightPoundsHundredth ?? 0
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

    private func saveTournamentPoundsCatch(
        species: String,
        clip: String,
        hundredths: Int,
        latE7: Int?,
        lonE7: Int?
    ) {
        let nowSec = Int64(Date().timeIntervalSince1970)

        let item = CatchItem(
            id: 0,
            dateTimeSec: nowSec,
            species: species,
            totalWeightOz: nil,
            totalWeightPoundsHundredth: hundredths,
            totalWeightHundredthKg: nil,
            totalLengthQuarters: nil,
            totalLengthCm: nil,
            catchType: "Tournament",
            markerType: SpeciesUtils.TournamentSpeciesCode.markerType(for: species),
            clipColor: clip,
            latitudeE7: latE7,
            longitudeE7: lonE7,
            primaryPhotoId: nil,
            createdAtSec: nowSec
        )

        do {
            _ = try DatabaseManager.shared.insertCatch(item)
        } catch {
            // Keep quiet, but you could log if desired
        }

        // Always reload from DB so rows have real catch IDs
        refreshFromDB()
        triggerBlink()
    }

    @MainActor
    private func updateTournamentPounds(
        row: PoundsDisplayRow,
        species: String,
        clip: String,
        hundredths: Int
    ) async {
        do {
            guard var item = try DatabaseManager.shared.getCatch(id: row.catchID) else { return }

            item.species = species
            item.clipColor = clip
            item.markerType = SpeciesUtils.TournamentSpeciesCode.markerType(for: species)
            item.totalWeightPoundsHundredth = hundredths
            item.catchType = "Tournament"

            try DatabaseManager.shared.updateCatch(item)
            refreshFromDB()
        } catch {
            print("ERROR updating tournament catch:", error)
        }
    }

    private func deleteTournamentPounds(row: PoundsDisplayRow) {
        do {
            try DatabaseManager.shared.deleteCatch(id: row.catchID)
            refreshFromDB()
        } catch {
            print("ERROR deleting tournament catch:", error)
        }
    }

    // MARK: - Species & Clip helpers

    private func speciesOptionsFrom(_ tournamentSpecies: String) -> [String] {
        let key = tournamentSpecies
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        switch key {
        case "largemouth", "largemouth bass", "large mouth", "large mouth bass":
            return ["Large Mouth", "Small Mouth"]

        case "smallmouth", "smallmouth bass", "small mouth", "small mouth bass":
            return ["Small Mouth", "Large Mouth"]

        case "spotted bass":
            return ["Large Mouth", "Small Mouth", "Spotted Bass"]

        default:
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

    private func availableClipColorsTopN() -> [String] {
        let used = Set(topN.map { $0.clipColor.uppercased() })
        let filtered = clipOrder.filter { !used.contains($0) }
        return filtered.isEmpty ? clipOrder : filtered
    }

    private func availableClipColorsForEdit(row: PoundsDisplayRow) -> [String] {
        var list = availableClipColorsTopN()

        // Make sure current clip color is first option
        let current = row.clipColor.uppercased()
        list.removeAll { $0.uppercased() == current }
        list.insert(current, at: 0)

        return list
    }

    // MARK: - Blink Logic -- Blinks 6 times to show the next fish to cull ---
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


    private func maybeBlinkOnChange() {
        if topN.count == settings.tournamentLimit {
            triggerBlink()
        }
    }
}

// MARK: - Tournament Row (lane)
private struct TournamentPoundsLane: View {
    let index: Int
    let row: PoundsDisplayRow?
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

            let (real, dec) = LbsFmt.split(totalHundredths: row?.hundredths ?? 0)

            HStack(spacing: 0) {
                // Clip letter
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

                // REAL value
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
                

                // DEC value
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

                // Species letters
                Text(row.map { SpeciesUtils.TournamentSpeciesCode.code(from: $0.species) } ?? "")
                    .font(.system(size: 20, weight: .regular))
                    .foregroundStyle(.black)
                    .frame(width: 56, height: 54, alignment: .leading)
                    .background(pageBg)
                    .padding(.leading, 2)
            }
            .opacity(dim ? 0.5 : 1.0)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isBlink && blinkOn ? Color.black : .clear, lineWidth: 3)
            )
        }
    }
}

// MARK: - Add Catch Sheet (unchanged look)
private struct TournamentPoundsSheet: View {
    @Binding var isPresented: Bool

    let tournamentSpecies: String
    let speciesOptions: [String]
    let availableClipColors: [String]

    let onSave: (_ species: String, _ clip: String, _ hundredths: Int) -> Void

    @State private var selectedSpecies: String = ""
    @State private var selectedClip: String = ""
    @State private var wholeText: String = ""
    @State private var decText: String = ""
    @FocusState private var focus: Field?
    private enum Field { case whole, dec }
    
    @State private var padTarget: NumberPad.Target = .pounds

    private var parsedWhole: Int { Int(wholeText) ?? 0 }
    private var parsedDec:   Int { Int(decText)   ?? 0 }

    private var hundredths: Int {
        parsedWhole * 100 + parsedDec
    }

    private var canSave: Bool {
        hundredths > 0 &&
        !selectedClip.isEmpty &&
        !selectedSpecies.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(spacing: 12) {
            Text("Tournament Catch Pounds")
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
            .foregroundStyle(.secondary)
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

            // Weight entry (FunDay-style NumberPad)
            VStack(alignment: .center, spacing: 6) {
                HStack(spacing: 6) {
                    Text("Pounds")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.black)
                    Text("Hundredths (00–99)")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.black)
                }
                .padding(.bottom, 4)

                HStack(spacing: 6) {
                    // LEFT: whole pounds
                    Text(wholeText.isEmpty ? "0" : wholeText)
                        .font(.system(size: 30, weight: .semibold))
                        .foregroundStyle(.black)
                        .frame(width: 60, height: 40)
                        .background(padTarget == .pounds ? Color.white : Color.veryLiteGrey)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(padTarget == .pounds ? Color.clipVeryGreen : Color.veryLiteGrey, lineWidth: 2)
                        )
                        .onTapGesture {
                            padTarget = .pounds
                            wholeText = ""
                        }
                    Text("lb")
                        .foregroundStyle(.black)

                    // RIGHT: hundredths
                    Text(decText.isEmpty ? "00" : decText)
                        .font(.system(size: 30, weight: .semibold))
                        .foregroundStyle(.black)
                        .frame(width: 70, height: 40)
                        .background(padTarget == .ounces ? Color.white : Color.veryLiteGrey)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(padTarget == .ounces ? Color.clipVeryGreen : Color.veryLiteGrey, lineWidth: 2)
                        )
                        .onTapGesture {
                            padTarget = .ounces
                            decText = ""
                        }
                    Text("hh")
                }

                NumberPad(
                    text: padTarget == .pounds ? $wholeText : $decText,
                    target: padTarget,
                    maxLen: padTarget == .pounds ? 3 : 2,
                    clampRange: padTarget == .ounces ? 0...99 : nil,
                    onDone: {}
                )
                .background(Color.softlockSand)
            }
            .padding(.top, 6)
            .padding(.leading, 6)


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
                        .stroke(Color.black, lineWidth: 2)
                )

                Button("SAVE_CATCH") {
                    commitSave()
                }
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(Color.blue)
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
        .onAppear {
            selectedSpecies = speciesOptions.first ?? ""
            selectedClip   = availableClipColors.first ?? ""
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                focus = .whole
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { focus = nil }
            }
        }
        .background(Color.clipVeryGreen)
    }

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

    private func sanitizePounds(_ s: inout String) {
        s = s.filter(\.isNumber)
        if s.count > 2 { s = String(s.prefix(2)) }
        if let v = Int(s) {
            s = String(min(max(v, 0), 999))
        }
        if s.count > 1, s.hasPrefix("0") {
            s.removeFirst()
        }
    }
    private func sanitizeDecimal(_ s: inout String) {
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

// MARK: - EDIT Tournament Pounds Sheet (same look, pre-filled)
private struct EditTournamentPoundsSheet: View {
    let row: PoundsDisplayRow
    let speciesOptions: [String]
    let availableClipColors: [String]
    let onSave: (_ species: String, _ clip: String, _ hundredths: Int) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var selectedSpecies: String = ""
    @State private var selectedClip: String = ""
    @State private var wholeText: String = ""
    @State private var decText: String = ""
    @FocusState private var focus: Field?
    private enum Field { case whole, dec }

    @State private var padTarget: NumberPad.Target = .pounds

    private var parsedWhole: Int { Int(wholeText) ?? 0 }
    private var parsedDec:   Int { Int(decText)   ?? 0 }

    private var hundredths: Int {parsedWhole * 100 + parsedDec}

    private var canSave: Bool {
        hundredths > 0 &&
        !selectedClip.isEmpty &&
        !selectedSpecies.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        
        VStack(spacing: 12) {
            Text("Edit Pounds Catch")
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

            // Weight entry (FunDay-style NumberPad)
            VStack(alignment: .center, spacing: 6) {
                HStack(spacing: 6) {
                    Text("Pounds")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.black)
                    Text("Hundredths (00–99)")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.black)
                }
                .padding(.bottom, 4)

                HStack(spacing: 6) {
                    Text(wholeText.isEmpty ? "0" : wholeText)
                        .font(.system(size: 30, weight: .semibold))
                        .foregroundStyle(.black)
                        .frame(width: 60, height: 40)
                        .background(padTarget == .pounds ? Color.white : Color.veryLiteGrey)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(padTarget == .pounds ? Color.clipVeryGreen : Color.veryLiteGrey, lineWidth: 2)
                        )
                        .onTapGesture {
                            padTarget = .pounds
                            wholeText = ""
                        }
                    Text("lb")
                        .foregroundStyle(.black)

                    Text(decText.isEmpty ? "00" : decText)
                        .font(.system(size: 30, weight: .semibold))
                        .foregroundStyle(.black)
                        .frame(width: 70, height: 40)
                        .background(padTarget == .ounces ? Color.white : Color.veryLiteGrey)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(padTarget == .ounces ? Color.clipVeryGreen : Color.veryLiteGrey, lineWidth: 2)
                        )
                        .onTapGesture {
                            padTarget = .ounces
                            decText = ""
                        }
                    Text("hh")
                }

                NumberPad(
                    text: padTarget == .pounds ? $wholeText : $decText,
                    target: padTarget,
                    maxLen: padTarget == .pounds ? 3 : 2,
                    clampRange: padTarget == .ounces ? 0...99 : nil,
                    onDone: {}
                )
                .background(Color.softlockSand)
            }
            .padding(.top, 6)
            .padding(.leading, 6)


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
                        .stroke(Color.black, lineWidth: 2)
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
                .background(Color.blue)
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

            // Weight (split into whole + dec)
            let (real, dec) = LbsFmt.split(totalHundredths: row.hundredths)
            wholeText = String(real)
            decText = String(format: "%02d", dec)

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                focus = .whole
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { focus = nil }
            }
        }
        .background(Color.clipVeryGreen)
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

    private func numericBox(text: Binding<String>, placeholder: String) -> some View {
        HStack(spacing: 6) {
            TextField(placeholder, text: text)
                .keyboardType(.numberPad)
                .textFieldStyle(.plain)
                .multilineTextAlignment(.trailing)
                .font(.title2.weight(.bold).monospacedDigit())
                .foregroundColor(.black)
                .onTapGesture {
                    // Always clear the current value when the user taps
                    text.wrappedValue = ""
                }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 8)
        .frame(width: 80)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(.black.opacity(0.35))
        )
    }

    private func seedZeroIfEmpty(_ s: inout String) {
        if s.isEmpty { s = "0" }
    }

    private func sanitizePounds(_ s: inout String) {
        s = s.filter(\.isNumber)
        if s.count > 2 { s = String(s.prefix(2)) }
        if let v = Int(s) {
            s = String(min(max(v, 0), 999))
        }
        if s.count > 1, s.hasPrefix("0") {
            s.removeFirst()
        }
    }
    private func sanitizeDecimal(_ s: inout String) {
        s = s.filter(\.isNumber)
        if s.count > 2 { s = String(s.prefix(2)) }
        if let v = Int(s) {
            s = String(min(max(v, 0), 99))
        }
        if s.count > 1, s.hasPrefix("0") {
            s.removeFirst()
        }
    }

    private func normalizeSpecies(_ s: String) -> String {
        s.trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: "_", with: " ")
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        CatchEntryTournamentPoundsView()
            .environmentObject(SettingsStore())
    }
}

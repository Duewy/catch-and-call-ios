import SwiftUI
import UIKit
internal import _LocationEssentials

// =============================================================
// CatchEntryLbsOz.swift
// Single-file SwiftUI screen with embedded popup for lbs/oz entry
// =============================================================

// MARK: - Add / Edit Catch Popup (Lbs/Ozs)
struct AddCatchLbsOzPopup: View {
    @Environment(\.dismiss) private var dismiss

    // Provided externally
    var speciesList: [String]

    // Reuse for Add or Edit
    var initialSpecies: String? = nil
    var initialLbs: Int? = nil
    var initialOz: Int? = nil
    var title: String = "Add Catch"

    // Local state
    @State private var selectedSpeciesIndex: Int = 0
    @State private var lbsText: String = ""
    @State private var ozText: String  = ""

    // Android-style numeric pad target
    //TODO: May not require # PAD
    @State private var padTarget: NumberPad.Target = .pounds

    // Save callback
    let onSave: (_ species: String, _ lbs: Int, _ oz: Int) -> Void
    
    // Delete Confirmation State
    @State private var confirmDelete: CatchItem? = nil
    
    // Parsed values
    private var parsedLbs: Int { Int(lbsText) ?? 0 }
    private var parsedOz: Int  { Int(ozText)  ?? 0 }

    // Validation
    private var canSave: Bool {
        let lbsOK = parsedLbs >= 0
        let ozOK  = (0...15).contains(parsedOz)
        return lbsOK && ozOK && (parsedLbs * 16 + parsedOz) > 0
    }

    var body: some View {
        ZStack {
            Color.softlockGreen.ignoresSafeArea()

            VStack(spacing: 16) {
                // Header
                HStack {
                    Text(title)
                        .font(.system(size: 24, weight: .bold))
                    Spacer()
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(.black)
                }

                // Species selector (Menu) 🐠
                VStack(spacing: 6) {
                    Text("Species")
                        .font(.system(size: 20, weight: .semibold))
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
                                .foregroundStyle(.secondary)
                        }
                        .padding(12)
                        .background(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.veryLiteGrey, lineWidth: 1))
                    }
                }

                // User Lbs & oz INPUTS 📝
                VStack(alignment: .center, spacing: 6) {
                    Text("Weight")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(.black)

                    // Labels row
                    HStack(spacing: 6) {
                        Text("Pounds /").font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.black)
                        Text("Ounces (0–15)").font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.black)
                    }
                    .padding(.bottom, 4)

                    // Entry Boxes row
                    HStack(spacing: 6) {
                        Text(lbsText.isEmpty ? "0" : lbsText)
                            .font(.system(size: 30, weight: .semibold))
                            .foregroundStyle(.black)
                            .frame(width: 60, height: 40)
                            .background(padTarget == .pounds ? Color.white : Color.veryLiteGrey)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(padTarget == .pounds ? Color.softlockGreen : Color.veryLiteGrey, lineWidth: 2)
                            )
                            .onTapGesture { padTarget = .pounds; lbsText = "" }

                        Text("Lbs")

                        Text(ozText.isEmpty ? "0" : ozText)
                            .font(.system(size: 30, weight: .semibold))
                            .foregroundStyle(.black)
                            .frame(width: 60, height: 40)
                            .background(padTarget == .ounces ? Color.white : Color.veryLiteGrey)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(padTarget == .ounces ? Color.softlockGreen : Color.veryLiteGrey, lineWidth: 2)
                            )
                            .onTapGesture { padTarget = .ounces; ozText = "" }

                        Text("oz")
                    }

                    //TODO: Is the # pad required?????
                    // Always-on NumberPad 0 - 9 #️⃣
                    NumberPad(
                        text: padTarget == .pounds ? $lbsText : $ozText,
                        target: padTarget,
                        maxLen: 3,
                        clampRange: (padTarget == .ounces) ? 0...15 : nil,
                        onDone: { }
                    )
                    .background(Color.softlockSand)
                }

                // Save
                HStack {
                    Button {
                        let sp = speciesList[selectedSpeciesIndex]
                        let clampedOz = max(0, min(parsedOz, 15))
                        onSave(sp, parsedLbs, clampedOz)
                        dismiss()
                    } label: { Text("Save Catch").bold() }
                    .buttonStyle(.borderedProminent)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.black, lineWidth: 2)
                    )
                    .disabled(!canSave)
                }
            }
            .padding(16)
        }
        .onAppear {
            // Prefill when editing
            if let s = initialSpecies,
               let idx = speciesList.firstIndex(where: { $0.caseInsensitiveCompare(s) == .orderedSame }) {
                selectedSpeciesIndex = idx
            } else {
                selectedSpeciesIndex = min(selectedSpeciesIndex, max(0, speciesList.count - 1))
            }
            if let L = initialLbs { lbsText = String(L) }
            if let O = initialOz  { ozText  = String(O) }
        }

        // Keep popup high enough that Save is visible
        .presentationDetents([ .large]) // tweak height to taste
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Main View (Catch Entry – Lbs/Ozs)
struct CatchEntryLbsOzView: View {
    @EnvironmentObject var vm: CatchesViewModel
    @EnvironmentObject var settings: SettingsStore
    
    @State private var showingAddPopup = false
    @State private var editingItem: CatchItem? = nil
    @State private var confirmDelete: CatchItem? = nil

    // --- Active species list (from SpeciesUtils / UserDefaults) ---
    @State private var speciesList: [String] = []
    
    // Only show catches that actually have lb/oz stored
    private var lbsOzToday: [CatchItem] {
        vm.today.filter { ($0.totalWeightOz ?? 0) > 0 &&
            ($0.catchType ?? "") == "Fun Day"
        }
    }


    var body: some View {
        VStack(spacing: 0) {
            if lbsOzToday.isEmpty {
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
                    Section(
                        header: Text("    Today's Catches")
                            .font(.headline)
                            .foregroundColor(.black)
                            .underline() )
                    {
                        // === Catch Entries ======
                        ForEach(lbsOzToday) { c in
                            CatchRow(item: c)
                                .listRowBackground(Color.clear)
                                .foregroundStyle(.black)
                                .background(Color.clear)
                                .overlay(
                                    Rectangle()     // Seration Line at Bottom of Entry
                                        .frame(height: 6)
                                        .foregroundColor(Color.gray),
                                    alignment: .bottom
                                )
                                .listRowSeparator(.hidden)
                            
                            // === Editing Catch Entry ====
                            // Swipe Action
                                .swipeActions(edge: .trailing) {
                                    Button("Edit") { editingItem = c }
                                        .tint(.blue)
                                    Button(role: .destructive) {
                                        confirmDelete = c
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                                .onTapGesture { editingItem = c } // optional tap-to-edit
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .background(Color.softlockGreen)
                .alert(item: $confirmDelete) { item in
                    let total = item.totalWeightOz ?? 0
                    let parts = DatabaseManager.lbsOz(fromTotalOz: total)
                    let when = Date(timeIntervalSince1970: TimeInterval(item.dateTimeSec))   // <-- add this

                    return Alert(
                        title: Text("Delete this catch?"),
                        message: Text("\(item.species.capitalized) – \(parts.lbs) lb \(parts.oz) oz at \(when.formatted(date: .omitted, time: .shortened))"),
                        primaryButton: .destructive(Text("Delete")) {
                            withAnimation { vm.deleteCatch(id: item.id) }
                        },
                        secondaryButton: .cancel()
                    )
                }

                
                HStack {
                    Spacer()
                    //---- Footer summary line ------
                    if !lbsOzToday.isEmpty {
                        // Compute totals
                        let totalCatches = lbsOzToday.count
                        let totalWeightOz = lbsOzToday.compactMap { $0.totalWeightOz }.reduce(0, +)
                        let parts = DatabaseManager.lbsOz(fromTotalOz: totalWeightOz)

                        Text("Catches: \(totalCatches)")
                            .font(.subheadline)
                            .foregroundColor(.black)

                        Text("Total: \(parts.lbs) lb \(parts.oz) oz")
                            .font(.subheadline)
                            .foregroundColor(.black)
                    }

                        // --- ADD CATCH Button  -------
                        Button { showingAddPopup = true } label: {
                            Label("Add a Catch", systemImage: "plus.circle.fill")
                                .font(.headline)
                        }
                        .buttonStyle(.borderedProminent)
                        Spacer()
                }
            }
            // === NAVIGATION BUTTONS (always visible at bottom) ===
            HStack(spacing: 12) {
                NavigationLink {
                    MainMenuView()
                } label: {
                    // --- MAIN MENU Button -----
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
                    //--- SET UP Button ------
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
        .background(Color.green)
        .onAppear { vm.reloadToday() }

        // EDIT sheet
        .sheet(item: $editingItem) { item in
            let parts = DatabaseManager.lbsOz(fromTotalOz: item.totalWeightOz ?? 0)
            AddCatchLbsOzPopup(
                speciesList: speciesList,
                initialSpecies: item.species,
                initialLbs: parts.lbs,
                initialOz: parts.oz,
                title: "Edit Catch"
            ) { species, newLbs, newOz in
                vm.updateCatchLbsOzs(original: item, species: species, lbs: newLbs, oz: newOz)
            }
        }

        // ADD Catch Information sheet
        .sheet(isPresented: $showingAddPopup) {
            AddCatchLbsOzPopup(
                speciesList: speciesList
            ) { species, lbs, oz in
                // Check SetUp toggle
                if settings.gpsEnabled {
                    // Ask your LocationService for a coordinate
                    LocationService.shared.requestCoordinate { coordinate in
                        // If location fails, just save without GPS
                        guard let coordinate = coordinate else {
                            vm.saveLbsOz(species: species, lbs: lbs, oz: oz)
                            return
                        }

                        let latE7 = Int(coordinate.latitude  * 10_000_000)
                        let lonE7 = Int(coordinate.longitude * 10_000_000)

                        vm.saveLbsOz(
                            species: species,
                            lbs: lbs,
                            oz: oz,
                            latE7: latE7,
                            lonE7: lonE7
                        )
                    }
                } else {
                    // GPS disabled in SetUp → save without lat/lon
                    vm.saveLbsOz(species: species, lbs: lbs, oz: oz)
                }
            }
        }


      //-------- Title BAR ----------
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.softlockGreen, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.light, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack(spacing: 0) {
                    Text("Catch Entry")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundColor(.black)

                    Text("(Lbs/Ozs)")
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

}

// MARK: - Row
private struct CatchRow: View {
    let item: CatchItem

    var body: some View {
        HStack(spacing: 22) {
            Spacer()
            // Species image
            SpeciesIcon(species: item.species, size: 85)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.species.capitalized)
                    .font(.headline)
                    .foregroundStyle(.black)

                let lbs = (item.totalWeightOz ?? 0) / 16
                let oz  = (item.totalWeightOz ?? 0) % 16
                Text("\(lbs) lb \(oz) oz")
                    .font(.subheadline)
                    .foregroundStyle(.black)

                // Date + GPS icon
                HStack(spacing: 6) {
                    let when = Date(timeIntervalSince1970: TimeInterval(item.dateTimeSec))
                    Text(when.formatted(date: .omitted, time: .shortened))
                        .font(.caption)
                        .foregroundStyle(.black)

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
        CatchEntryLbsOzView()
            .environmentObject(CatchesViewModel())   // ✅ vm
            .environmentObject(SettingsStore())      // ✅ settings
    }
}


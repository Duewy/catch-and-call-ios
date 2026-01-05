//
//  MapQuerySheetView.swift
//  CatchAndCall
//
//  Themed SwiftUI equivalent of PopupMapQuery.
//  - Brown background (matches MapTypeSheetView)
//  - Card-style sections
//  - Colored Cancel / Get Map buttons
//

import Foundation
import SwiftUI

struct MapQuerySheetView: View {
    @Environment(\.dismiss) private var dismiss

    @Binding var filters: MapQueryFilters
    var onApply: () -> Void

    @State private var fromDate: Date = Date()
    @State private var toDate: Date = Date()
    
    // Species options + selection
    @State private var speciesOptions: [String] = []
    @State private var selectedSpecies: Set<String> = []
    @State private var isSpeciesExpanded: Bool = false

    @State private var eventType: String = "Both"

    @State private var sizeMin: String = ""
    @State private var sizeMax: String = ""
    
    @State private var sizeType: String = "Weight"
    @State private var measurementType: String = "Imperial (Lbs/oz - Inches)"

    private let eventOptions = ["Fun Day", "Tournament", "Both"]
    private let sizeTypeOptions = ["Weight", "Length"]
    private let measurementOptions = [
        "Imperial",
        "Metric",
        "All"
    ]

    // Match the map sheet background (tweak as desired)
    private let sheetBackground = Color.ltBrown

    var body: some View {
        ZStack {

            NavigationStack {
                
                Form {
                    // We hide the default white form background
                    // and rely on our ZStack color.
                    Section {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("From")
                                .font(.subheadline)
                                .foregroundColor(.black)

                            // --- DATES SELECTION --------
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.veryLiteGrey.opacity(0.75))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.black.opacity(0.3), lineWidth: 1)
                                    )

                                DatePicker(
                                    "",
                                    selection: $fromDate,
                                    displayedComponents: .date
                                )
                                .foregroundColor(.black)
                                .datePickerStyle(.compact)
                                .labelsHidden()
                                .padding(4)
                            }


                            Divider()
                                .padding(.vertical, 2)
                                .foregroundColor(.black)

                            Text("To")
                                .font(.subheadline)
                                .foregroundColor(.black)

                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.veryLiteGrey.opacity(0.75))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.black.opacity(0.3), lineWidth: 1)
                                    )

                                DatePicker(
                                    "",
                                    selection: $toDate,
                                    displayedComponents: .date
                                )
                                .foregroundColor(.black)
                                .datePickerStyle(.compact)
                                .labelsHidden()
                                .padding(4)
                            }

                        }
                        .padding(.vertical, 2)
                    } header: {
                        Text("DATE RANGE")
                            .font(.headline)
                            .foregroundColor(.black)
                    }
                    .listRowBackground(Color.logYellowSecondary)

                    // --- SPECIES SELECTION --------
                    Section {
                        VStack(alignment: .leading, spacing: 6) {
                           
                            // Summary row (tap to expand/collapse)
                            Button {
                                withAnimation {
                                    isSpeciesExpanded.toggle()
                                }
                            } label: {
                                HStack {
                                    Text(selectedSpecies.isEmpty
                                         ? "All species"
                                         : selectedSpecies.sorted().joined(separator: ", "))
                                        .font(.headline)
                                        .foregroundColor(.black)
                                        .lineLimit(2)
                                    Spacer()
                                    Image(systemName: isSpeciesExpanded ? "chevron.up" : "chevron.down")
                                        .foregroundColor(.secondary)
                                }
                                .padding(8)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.softlockSand)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.black.opacity(0.3), lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)

                            if isSpeciesExpanded {
                                // Top row: All + Clear All
                                HStack {
                                    Button {
                                        // "All species" = no specific selections
                                        selectedSpecies.removeAll()
                                    } label: {
                                        HStack {
                                            Image(systemName: selectedSpecies.isEmpty ? "checkmark.square.fill" : "square")
                                                .foregroundColor(.clipBrightGreen)
                                            Text("All species")
                                                .foregroundColor(.black)
                                        }
                                    }
                                    .buttonStyle(.plain)

                                    Spacer()

                                    Button {
                                        // Explicit Clear All (same as All species)
                                        selectedSpecies.removeAll()
                                    } label: {
                                        Text("Clear All")
                                            .font(.footnote.bold())
                                            .foregroundColor(.black)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 2)
                                            .foregroundColor(.black)
                                            .background(Color.red.opacity(0.8))
                                            .cornerRadius(6)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 6)
                                                    .stroke(Color.black, lineWidth: 1)
                                            )
                                    }
                                }
                                .padding(.horizontal, 4)

                                Divider()

                                // Checklist
                                ScrollView {
                                    LazyVStack(alignment: .leading, spacing: 4) {
                                        ForEach(speciesOptions, id: \.self) { sp in
                                            Button {
                                                if selectedSpecies.contains(sp) {
                                                    selectedSpecies.remove(sp)
                                                } else {
                                                    selectedSpecies.insert(sp)
                                                }
                                            } label:
                                            {
                                                HStack {
                                                    Image(systemName: selectedSpecies.contains(sp) ? "checkmark.square.fill" : "square")
                                                        .foregroundColor(.clipBrightGreen)
                                                    Text(sp)
                                                        .font(.headline)
                                                        .foregroundColor(.black)
                                                    Spacer()
                                                }
                                                .padding(6)
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                }
                                .frame(maxHeight: 220)   // tweak height to taste
                            }
                        }
                        .padding(.vertical, 2)
                    } header: {
                        Text("SPECIES")
                            .font(.headline)
                            .foregroundColor(.black)
                    }
                    .listRowBackground(Color.logYellowSecondary)


                    // --- EVENT SELECTION --------
                    Section {
                        VStack(alignment: .leading, spacing: 4) {
                          
                            HStack(spacing: 8) {
                                ForEach(eventOptions, id: \.self) { option in
                                    Button {
                                        eventType = option
                                    } label: {
                                        Text(option)
                                            .font(.subheadline)
                                            .foregroundColor(.black)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 8)
                                    }
                                    .buttonStyle(.plain)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(eventType == option
                                                  ? Color.yellow               // SELECTED = yellow
                                                  : Color.veryLiteGrey.opacity(0.63))  // OTHERS = grey
                                    )
                                    .foregroundColor(.black)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.black.opacity(0.4), lineWidth: 1)
                                    )
                                }
                            }
                        }
                        .padding(.vertical, 2)
                    } header: {
                        Text("EVENT TYPE")
                            .font(.headline)
                            .foregroundColor(.black)
                    }
                    .listRowBackground(Color.logYellowSecondary)


                    // --- SIZE SELECTION --------
                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                        
                            HStack(spacing: 8) {
                                ForEach(sizeTypeOptions, id: \.self) { option in
                                    Button {
                                        sizeType = option
                                    } label: {
                                        Text(option)
                                            .font(.subheadline)
                                            .foregroundColor(.black)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 8)
                                    }
                                    .buttonStyle(.plain)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(sizeType == option
                                                  ? Color.logOrange     // SELECTED = orange
                                                  : Color.veryLiteGrey.opacity(0.63)) // NOT SELECTED = grey
                                    )
                                    .foregroundColor(.black)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.black.opacity(0.4), lineWidth: 1)
                                    )
                                }
                            }

                            HStack {
                                queryMiniField(
                                    placeholder: "Min",
                                    text: $sizeMin
                                )
                                Text("to")
                                    .font(.subheadline)
                                    .foregroundColor(.black)
                                queryMiniField(
                                    placeholder: "Max",
                                    text: $sizeMax
                                )
                            }.foregroundColor(.black)
                        }
                        .padding(.vertical, 2)
                    } header: {
                        Text("SIZE FILTER")
                            .font(.headline)
                            .foregroundColor(.black)
                    }
                    .listRowBackground(Color.logYellowSecondary)

                    // --- MEASUREMENT TYPE SELECTION --------
                    Section {
                        HStack(spacing: 8) {
                            ForEach(measurementOptions, id: \.self) { option in
                                Button {
                                    measurementType = option
                                } label: {
                                    Text(option)
                                        .font(.subheadline)
                                        .foregroundColor(.black)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 8)
                                }
                                .buttonStyle(.plain)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(measurementType == option
                                              ? Color.clipBrightGreen
                                              : Color.veryLiteGrey.opacity(0.63))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.black.opacity(0.4), lineWidth: 1)
                                )
                            }
                        }

                    }
                    header: {
                        Text("MEASUREMENT TYPE")
                            .font(.headline)
                            .foregroundColor(.black)
                    }
                    .listRowBackground(Color.logYellowSecondary)
                }
                
                .scrollContentBackground(.hidden)   // remove white behind Form
                .background(Color.ltBrown)          // Sets the background to ltBrown
                .navigationTitle("Map Query")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(action: { dismiss() }) {
                            Text("Cancel")
                                .font(.headline)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 2)
                                .foregroundColor(.black)
                                .background(Color.red.opacity(0.85))
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.black, lineWidth: 1)
                                )
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button(action: { commitFiltersAndClose() }) {
                            Text("Get Map")
                                .font(.headline)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 2)
                                .foregroundColor(.black)
                                .background(Color.clipBrightGreen.opacity(0.9))
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.black, lineWidth: 1)
                                )
                        }
                    }
                }
                
                .onAppear {
                    loadSpeciesOptions()
                    loadFromExistingFilters()
                }
            }
        }
    }

    // MARK: - Styled field helpers

     private func queryMiniField(
        placeholder: String,
        text: Binding<String>
    ) -> some View {
        TextField(placeholder, text: text)
            .keyboardType(.decimalPad)
            .textFieldStyle(.plain)
            .padding(2)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.softlockSand)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.black.opacity(0.3), lineWidth: 1)
            )
    }

    // MARK: - Species loading

    private func loadSpeciesOptions() {
        // Use the USER-REORDERED species list (single source of truth)
        speciesOptions = SpeciesStorage.loadOrderedSpeciesList()
    }

    
    // MARK: - Existing logic (unchanged)

    private func loadFromExistingFilters() {
        // DATE RANGE
        if filters.dateRange != "All" {
            let parts = filters.dateRange
                .components(separatedBy: "to")
                .map { $0.trimmingCharacters(in: .whitespaces) }

            let fmt = DateFormatter()
            fmt.locale = Locale(identifier: "en_US_POSIX")
            fmt.timeZone = .current
            fmt.dateFormat = "yyyy-MM-dd"

            if parts.count == 2 {
                if let d1 = fmt.date(from: parts[0]) {
                    fromDate = d1
                }
                if let d2 = fmt.date(from: parts[1]) {
                    toDate = d2
                }
            }
        } else {
            // Default both to today if "All"
            let today = Date()
            fromDate = today
            toDate = today
        }

        // SPECIES
        if filters.species == "All" {
            selectedSpecies = []
        } else {
            let parts = filters.species
                .split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
            selectedSpecies = Set(parts)
        }

        // EVENT TYPE, SIZE, MEASUREMENT
        eventType        = filters.eventType
        sizeType         = filters.sizeType

        // If the saved measurementType is valid, use it.
        // Otherwise default to Imperial (first option).
        if measurementOptions.contains(filters.measurementType) {
            measurementType = filters.measurementType
        } else {
            measurementType = measurementOptions[0]   // "Imperial (Lbs/oz - Inches)"
        }

        // crude parse of "min - max"
        let parts = filters.sizeRange
            .split(separator: "-")
            .map { $0.trimmingCharacters(in: .whitespaces) }
        if parts.count == 2 {
            sizeMin = parts[0]
            sizeMax = parts[1]
        }
    }


    private func commitFiltersAndClose() {
        // Ensure fromDate <= toDate
        let startDate = min(fromDate, toDate)
        let endDate   = max(fromDate, toDate)

        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "en_US_POSIX")
        fmt.timeZone = .current
        fmt.dateFormat = "yyyy-MM-dd"

        let startString = fmt.string(from: startDate)
        let endString   = fmt.string(from: endDate)
        let finalDateRange = "\(startString) to \(endString)"

        // SPECIES → build from selectedSpecies set
        let finalSpecies: String
        if selectedSpecies.isEmpty {
            finalSpecies = "All"
        } else {
            finalSpecies = selectedSpecies
                .map { SpeciesStorage.normalizeSpeciesName($0) }
                .sorted()
                .joined(separator: ", ")
        }


        // Size range
        let finalSizeMin   = sizeMin.isEmpty ? "0" : sizeMin
        let finalSizeMax   = sizeMax.isEmpty ? "9999" : sizeMax

        filters = MapQueryFilters(
            dateRange: finalDateRange,
            species: finalSpecies,
            eventType: eventType,
            sizeType: sizeType,
            sizeRange: "\(finalSizeMin) - \(finalSizeMax)",
            measurementType: measurementType
        )

        onApply()
        dismiss()
    }

    

}

// MARK: - Preview

#Preview {
    if #available(iOS 17.0, *) {
        MapQuerySheetPreviewWrapper()
    } else {
        Text("iOS 17 required")
    }
}

@available(iOS 17.0, *)
private struct MapQuerySheetPreviewWrapper: View {
    @State private var filters = MapQueryFilters.default

    var body: some View {
        MapQuerySheetView(filters: $filters) {
            print("Apply pressed in preview")
        }
    }
}

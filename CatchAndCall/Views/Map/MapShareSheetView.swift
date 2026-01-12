//
//  MapShareSheetView.swift
//  CatchAndCall
//
//  Created by Dwayne Brame on 2025-11-16.
//

import Foundation
import SwiftUI
import UIKit

@available(iOS 17.0, *)
struct ShareFieldOptions {
    var includeDateTime = true
    var includeSpecies = true
    var includeWeight = true
    var includeLength = true
    var includeGPS = true
    var includeEventType = true

    var hasAtLeastOneSelected: Bool {
        includeDateTime ||
        includeSpecies ||
        includeWeight ||
        includeLength ||
        includeGPS ||
        includeEventType
    }
}

@available(iOS 17.0, *)
struct MapShareSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var fieldOptions = ShareFieldOptions()

    @State private var shareURL: URL? = nil
    @State private var isPresentingShareSheet = false

    let filters: MapQueryFilters
    let catches: [CatchItem]
    private let pageBackground = Color.brown

    var body: some View {
        
        NavigationStack {

            Form {
                // MARK: - Summary
                Section("SUMMARY") {
                    Text(summaryText)
                        .font(.subheadline)
                        .foregroundColor(.black)
                        .multilineTextAlignment(.leading)
                }
                .foregroundColor(.black)
                .listRowBackground(Color.softlockSand)

                // MARK: - Select Data to Share
                Section {
                    Toggle("Include Date / Time", isOn: $fieldOptions.includeDateTime)
                    Toggle("Include Species", isOn: $fieldOptions.includeSpecies)
                    Toggle("Include Weight", isOn: $fieldOptions.includeWeight)
                    Toggle("Include Length", isOn: $fieldOptions.includeLength)
                    Toggle("Include GPS Coordinates", isOn: $fieldOptions.includeGPS)
                    Toggle("Include Event Type", isOn: $fieldOptions.includeEventType)
                }
                header: {
                    Text("SELECT DATA TO SHARE")
                        .foregroundColor(.black)
                } footer: {
                    if !fieldOptions.hasAtLeastOneSelected {
                        Text("Select at least one field to include in the shared data.")
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                }
                .foregroundColor(.black)
                .listRowBackground(Color.softlockSand)

                // MARK: - Export Options
                Section("EXPORT OPTIONS") {
                    let exportDisabled = !fieldOptions.hasAtLeastOneSelected || catches.isEmpty

                    Button {
                        saveAsCSV()
                    } label: {
                        Text("Save as CSV")
                            .font(.headline)
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .background(Color.blue.opacity(exportDisabled ? 0.55 : 0.95))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.black, lineWidth: 2)
                            )
                            .cornerRadius(10)
                    }
                    .buttonStyle(.plain)
                    .disabled(exportDisabled)

                    Button {
                        saveAsKML()
                    } label: {
                        Text("Save as KML (Google Earth)")
                            .font(.headline)
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .background(Color.clipBrightGreen.opacity(exportDisabled ? 0.55 : 0.95))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.black, lineWidth: 2)
                            )
                            .cornerRadius(10)
                    }
                    .buttonStyle(.plain)
                    .disabled(exportDisabled)
                }
                .foregroundColor(.black)
                .listRowBackground(Color.softlockSand)


                // MARK: - Cancel
                Section {
                    Button {
                            dismiss()
                        } label: {
                            Text("Cancel")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity, minHeight: 44)
                                .background(Color.orange.opacity(0.85))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.black, lineWidth: 2)
                                )
                                .cornerRadius(10)
                        }
                        .buttonStyle(.plain)
                    }
                    .listRowBackground(Color.clear)
            }
            .listSectionSpacing(.compact)
            .scrollContentBackground(.hidden)
                .background(pageBackground)
                .navigationTitle("Save / Share")
            }
            .background(pageBackground.ignoresSafeArea())
            .preferredColorScheme(.light)
        
        // 🔹 share sheet when we have a file URL
        .sheet(isPresented: $isPresentingShareSheet) {
            if let url = shareURL {
                ActivityView(activityItems: [url])
            }
        }
    }

    // MARK: - Summary Helper
    private var summaryText: String {
        if catches.isEmpty {
            return "No catches are available to share for the current map filters."
        } else {
            let count = catches.count
            let plural = count == 1 ? "catch" : "catches"
            return "You are sharing \(count) \(plural) that match your current map query."
        }
    }
    
    // MARK: - CSV Builder

    private func makeCSV(options: ShareFieldOptions) -> String {
        var rows: [String] = []

        // Header row
        var header: [String] = []
        if options.includeDateTime   { header.append("DateTime") }
        if options.includeSpecies    { header.append("Species") }
        if options.includeWeight     { header.append("Weight") }
        if options.includeLength     { header.append("Length") }
        if options.includeGPS {
            header.append("Latitude")
            header.append("Longitude")
        }
        if options.includeEventType  { header.append("EventType") }
        rows.append(header.joined(separator: ","))

        // Formatter for DateTime
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "en_US_POSIX")
        fmt.timeZone = .current
        fmt.dateFormat = "yyyy-MM-dd HH:mm"

        // Data rows
        for c in catches {
            var cols: [String] = []

            if options.includeDateTime {
                let date = Date(timeIntervalSince1970: TimeInterval(c.dateTimeSec))
                cols.append(fmt.string(from: date))
            }

            if options.includeSpecies {
                cols.append(c.species)
            }

            if options.includeWeight {
                // Lbs/oz stored as total ounces
                if let totalOz = c.totalWeightOz {
                    let lbs = totalOz / 16
                    let oz  = totalOz % 16
                    cols.append("\(lbs) lb \(oz) oz")
                }
                // Decimal pounds (hundredths)
                else if let hundredthLb = c.totalWeightPoundsHundredth {
                    let whole = hundredthLb / 100
                    let hundredths = abs(hundredthLb % 100)
                    cols.append("\(whole).\(String(format: "%02d", hundredths)) lb")
                }
                // Kilograms.xx (hundredths)
                else if let hundredthKg = c.totalWeightHundredthKg {
                    let whole = hundredthKg / 100
                    let hundredths = abs(hundredthKg % 100)
                    cols.append("\(whole).\(String(format: "%02d", hundredths)) kg")
                } else {
                    cols.append("")
                }
            }

            if options.includeLength {
                // Inches quarters
                if let q = c.totalLengthQuarters {
                    let inches = q / 4
                    let quarter = q % 4
                    cols.append("\(inches) \(quarter)/4 in")
                }
                // Cm tenths
                else if let tenthsCm = c.totalLengthCm {
                    let whole = tenthsCm / 10
                    let tenth = abs(tenthsCm % 10)
                    cols.append("\(whole).\(tenth) cm")
                } else {
                    cols.append("")
                }
            }

            if options.includeGPS {
                if let latE7 = c.latitudeE7,
                   let lonE7 = c.longitudeE7 {
                    let lat = Double(latE7) / 1_000_0000.0
                    let lon = Double(lonE7) / 1_000_0000.0
                    cols.append(String(format: "%.6f", lat))
                    cols.append(String(format: "%.6f", lon))
                } else {
                    cols.append("")
                    cols.append("")
                }
            }

            if options.includeEventType {
                cols.append(c.catchType ?? "")
            }

            rows.append(cols.joined(separator: ","))
        }

        return rows.joined(separator: "\n")
    }

    
    // MARK: - KML Builder

    private func makeKML(options: ShareFieldOptions) -> String {
        var lines: [String] = []

        // Helper to escape XML special characters
        func xmlEscape(_ s: String) -> String {
            s
                .replacingOccurrences(of: "&", with: "&amp;")
                .replacingOccurrences(of: "<", with: "&lt;")
                .replacingOccurrences(of: ">", with: "&gt;")
        }

        // Date formatter for placemark names / descriptions
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "en_US_POSIX")
        fmt.timeZone = .current
        fmt.dateFormat = "yyyy-MM-dd HH:mm"

        lines.append("<?xml version=\"1.0\" encoding=\"UTF-8\"?>")
        lines.append("<kml xmlns=\"http://www.opengis.net/kml/2.2\">")
        lines.append("<Document>")
        lines.append("<name>BassAnglerTracker Catches</name>")
        lines.append("<description>\(xmlEscape(summaryText))</description>")

        for c in catches {
            // We only include catches with GPS
            guard
                let latE7 = c.latitudeE7,
                let lonE7 = c.longitudeE7
            else {
                continue
            }

            let lat = Double(latE7) / 1_000_0000.0
            let lon = Double(lonE7) / 1_000_0000.0

            // Build a readable name (e.g., "2025-02-10 largemouth")
            let date = Date(timeIntervalSince1970: TimeInterval(c.dateTimeSec))
            let dateString = fmt.string(from: date)
            let speciesName = c.species
            let placemarkName = xmlEscape("\(dateString) \(speciesName)")

            // Build description lines based on selected fields
            var descLines: [String] = []

            if options.includeDateTime {
                descLines.append("Date/Time: \(dateString)")
            }
            if options.includeSpecies {
                descLines.append("Species: \(speciesName)")
            }
            if options.includeWeight {
                if let totalOz = c.totalWeightOz {
                    let lbs = totalOz / 16
                    let oz  = totalOz % 16
                    descLines.append("Weight: \(lbs) lb \(oz) oz")
                } else if let hundredthLb = c.totalWeightPoundsHundredth {
                    let whole = hundredthLb / 100
                    let hundredths = abs(hundredthLb % 100)
                    descLines.append("Weight: \(whole).\(String(format: "%02d", hundredths)) lb")
                } else if let hundredthKg = c.totalWeightHundredthKg {
                    let whole = hundredthKg / 100
                    let hundredths = abs(hundredthKg % 100)
                    descLines.append("Weight: \(whole).\(String(format: "%02d", hundredths)) kg")
                }
            }
            if options.includeLength {
                if let q = c.totalLengthQuarters {
                    let inches = q / 4
                    let quarter = q % 4
                    descLines.append("Length: \(inches) \(quarter)/4 in")
                } else if let tenthsCm = c.totalLengthCm {
                    let whole = tenthsCm / 10
                    let tenth = abs(tenthsCm % 10)
                    descLines.append("Length: \(whole).\(tenth) cm")
                }
            }
            if options.includeEventType {
                if let type = c.catchType, !type.isEmpty {
                    descLines.append("Event: \(type)")
                }
            }
            if options.includeGPS {
                descLines.append(String(format: "GPS: %.6f, %.6f", lat, lon))
            }

            let descriptionText = xmlEscape(descLines.joined(separator: "\n"))

            lines.append("  <Placemark>")
            lines.append("    <name>\(placemarkName)</name>")
            lines.append("    <description>\(descriptionText)</description>")
            lines.append("    <Point>")
            // NOTE: KML expects lon,lat,altitude
            lines.append(String(format: "      <coordinates>%.6f,%.6f,0</coordinates>", lon, lat))
            lines.append("    </Point>")
            lines.append("  </Placemark>")
        }

        lines.append("</Document>")
        lines.append("</kml>")

        return lines.joined(separator: "\n")
    }

    
    
    //TODO: (to be wired to your real logic)
    // MARK: - Actions

    // --- SAVE CSV File ---
    private func saveAsCSV() {
        // Extra safety: respect the toggle + data rules
        guard fieldOptions.hasAtLeastOneSelected, !catches.isEmpty else {
            print("CSV export skipped: no fields selected or no catches.")
            return
        }

        let csvString = makeCSV(options: fieldOptions)

        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "CatchAndCall_MapExport.csv"
        let fileURL = tempDir.appendingPathComponent(fileName)

        do {
            try csvString.write(to: fileURL, atomically: true, encoding: .utf8)
            print("✅ CSV saved to: \(fileURL.path)")

            // 🔹 Trigger the share sheet
            shareURL = fileURL
            isPresentingShareSheet = true
        } catch {
            print("❌ Failed to save CSV: \(error)")
        }
    }

    // --- SAVE KML File -------
    private func saveAsKML() {
        // Extra safety: respect the toggle + data rules
        guard fieldOptions.hasAtLeastOneSelected, !catches.isEmpty else {
            print("KML export skipped: no fields selected or no catches.")
            return
        }

        let kmlString = makeKML(options: fieldOptions)

        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "CatchAndCall_MapExport.kml"
        let fileURL = tempDir.appendingPathComponent(fileName)

        do {
            try kmlString.write(to: fileURL, atomically: true, encoding: .utf8)
            print("✅ KML saved to: \(fileURL.path)")

            // 🔹 Trigger the share sheet
            shareURL = fileURL
            isPresentingShareSheet = true
        } catch {
            print("❌ Failed to save KML: \(error)")
        }
    }

    private func saveScreenshot() {
        // TODO: Hook into your map screenshot pipeline
        print("TODO: Save screenshot of map")
    }

    // (Optional) You can delete this helper if it's no longer used
    private func onShare(_ options: ShareFieldOptions) {
        let csv = makeCSV(options: options)
        print("Sharing CSV:\n\(csv)")
    }
}


// MARK: - UIKit Share Wrapper

struct ActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: applicationActivities
        )
    }

    func updateUIViewController(
        _ uiViewController: UIActivityViewController,
        context: Context
    ) {
        // nothing to update
    }
}


#Preview {
    if #available(iOS 17.0, *) {
        MapShareSheetView(
            filters: .default,
            catches: []
        )
    } else {
        Text("iOS 17 required")
    }
}

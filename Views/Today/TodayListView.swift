import SwiftUI

struct TodayListView: View {
    @EnvironmentObject var vm: CatchesViewModel
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        List {
            if vm.today.isEmpty {
                Text("No catches yet today.")
                    .foregroundStyle(.secondary)
            } else {
                // ---- Rows ----
                Section {
                    ForEach(vm.today) { item in
                        CatchRow(item: item)
                            .listRowSeparator(.hidden)
                    }
                } header: {
                    Text("Today's Catches")
                        .font(.headline)
                        .foregroundColor(.primary)
                }

                // ---- Totals (per stored unit; no mixing) ----
                Section {
                    let totOz        = vm.today.compactMap { $0.totalWeightOz }.reduce(0, +)
                    let totLbHund    = vm.today.compactMap { $0.totalWeightPoundsHundredth }.reduce(0, +)
                    let totKgHund    = vm.today.compactMap { $0.totalWeightHundredthKg }.reduce(0, +)
                    let totQuarters  = vm.today.compactMap { $0.totalLengthQuarters }.reduce(0, +)
                    let totCmTenths  = vm.today.compactMap { $0.totalLengthCm }.reduce(0, +)

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Catches: \(vm.today.count)")
                            .font(.subheadline)
                            .foregroundColor(.primary)

                        if totOz > 0 {
                            let (lbs, oz) = MeasureHelpers.lbsOz(fromTotalOz: totOz)
                            Text("Total (lb/oz): \(lbs) lb \(oz) oz")
                        }
                        if totLbHund > 0 {
                            Text("Total (lb.hh): \(MeasureHelpers.formatPoundsHundredth(totLbHund))")
                        }
                        if totKgHund > 0 {
                            Text("Total (kg.hh): \(MeasureHelpers.formatKgsHundredth(totKgHund))")
                        }
                        if totQuarters > 0 {
                            Text("Total (in): \(MeasureHelpers.formatInchesQuarters(totQuarters))")
                        }
                        if totCmTenths > 0 {
                            Text("Total (cm): \(MeasureHelpers.formatCentimeters(totCmTenths))")
                        }
                    }
                    .font(.subheadline)
                    .foregroundColor(.primary)
                } header: {
                    Text("Totals (by unit)")
                        .font(.headline)
                        .foregroundColor(.primary)
                }
            }
        }
        .listStyle(.plain)
        .navigationTitle("Today’s Catches")
        .task { vm.reloadToday() }                 // first appear
        .refreshable { vm.reloadToday() }          // pull to refresh
        .onChange(of: scenePhase) { phase in       // come back to foreground
            if phase == .active { vm.reloadToday() }
        }
    }
}

// MARK: - Row
private struct CatchRow: View {
    let item: CatchItem

    var body: some View {
        HStack(spacing: 16) {
            SpeciesIcon(species: item.species, size: 72)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.species.capitalized)
                    .font(.headline)

                // Weight (priority: lb/oz → lb.hh → kg.hh)
                if let ozTotal = item.totalWeightOz {
                    let (lbs, oz) = MeasureHelpers.lbsOz(fromTotalOz: ozTotal)
                    Text("\(lbs) lb \(oz) oz")
                        .font(.subheadline).foregroundStyle(.secondary)
                } else if let hLb = item.totalWeightPoundsHundredth {
                    Text(MeasureHelpers.formatPoundsHundredth(hLb))
                        .font(.subheadline).foregroundStyle(.secondary)
                } else if let hKg = item.totalWeightHundredthKg {
                    Text(MeasureHelpers.formatKgsHundredth(hKg))
                        .font(.subheadline).foregroundStyle(.secondary)
                }

                // Length (priority: inches → cm)
                if let q = item.totalLengthQuarters {
                    Text(MeasureHelpers.formatInchesQuarters(q))
                        .font(.subheadline).foregroundStyle(.secondary)
                } else if let t = item.totalLengthCm {
                    Text(MeasureHelpers.formatCentimeters(t))
                        .font(.subheadline).foregroundStyle(.secondary)
                }

                // Time + GPS
                HStack(spacing: 6) {
                    let when = MeasureHelpers.dateFromSeconds(item.dateTimeSec)
                    Text(when.formatted(date: .omitted, time: .shortened))
                        .font(.caption).foregroundStyle(.secondary)

                    let hasGPS = (item.latitudeE7 != nil && item.longitudeE7 != nil)
                    Image(hasGPS ? "map_icon_fun_day" : "map_icon_fall_back")
                        .resizable().scaledToFit()
                        .frame(width: 14, height: 14)
                        .opacity(hasGPS ? 1.0 : 0.65)
                        .accessibilityLabel(hasGPS ? Text("GPS recorded") : Text("GPS not recorded"))
                }
            }

            Spacer()
        }
    }
}

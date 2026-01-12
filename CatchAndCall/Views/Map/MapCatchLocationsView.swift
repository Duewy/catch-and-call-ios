//  MapCatchLocationsView.swift
//  CatchAndCall
//
//  SwiftUI version of MapCatchLocationsActivity.
//  - Shows Apple Map
//  - Has buttons: Close, Map Type, Filters
//  - For now: plots dummy points; later we plug in DatabaseManager + real filters.

import Foundation
import SwiftUI
import MapKit

@available(iOS 17.0, *)
struct MapCatchLocationsView: View {
    // MARK: - State

    @Environment(\.dismiss) private var dismiss

    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var mapType: MKMapType = .hybrid
    @State private var filters: MapQueryFilters = .default
    @State private var showingShareSheet = false
    @State private var shareCatches: [CatchItem] = []
    @State private var markers: [MapCatchMarker] = []

    @State private var showingFilterSheet = false
    @State private var showingMapTypeSheet = false

    // simple marker model (will be replaced with real catches)
    struct MapCatchMarker: Identifiable {
        let id = UUID()
        let title: String
        let subtitle: String
        let coordinate: CLLocationCoordinate2D
        let isTournament: Bool
    }



    // MARK: - Body

    var body: some View {
        ZStack {
            // Apple Map
            mapView

            // Overlay: buttons
            VStack {
                topBar
                Spacer()
            }
            .padding()
        }
        
        .sheet(isPresented: $showingFilterSheet) {
            MapQuerySheetView(filters: $filters) {
                applyFilters()
            }
        }
        
        .sheet(isPresented: $showingMapTypeSheet) {
            MapTypeSheetView(mapType: $mapType)
        }
        
        .sheet(isPresented: $showingShareSheet) {
            MapShareSheetView(
                filters: filters,
                catches: shareCatches
            )
            .presentationDetents([.large]) 
        }
        .onAppear {
            loadInitialMarkers()
        }

    }

    // MARK: - Subviews

    private var mapView: some View {
        Map(position: $cameraPosition) {
            ForEach(markers) { marker in
                Annotation(marker.title,
                           coordinate: marker.coordinate) {
                    VStack(spacing: 2) {
                        let iconName  = marker.isTournament ? "flag.fill" : "fish.fill"
                        let iconColor = marker.isTournament ? Color.red : Color.blue

                        ZStack {
                            // OUTLINE (black, slightly larger)
                            Image(systemName: iconName)
                                .imageScale(.large)
                                .foregroundColor(.black)
                                .scaleEffect(1.15)

                            // MAIN ICON
                            Image(systemName: iconName)
                                .imageScale(.large)
                                .foregroundColor(iconColor)
                        }

                        Text(marker.title)
                            .font(.caption2)
                            .foregroundColor(.black)
                        Text(marker.subtitle)
                            .font(.caption2)
                            .foregroundColor(.black)
                    }
                }
            }
        }
        .mapStyle(styleForCurrentType())
        .ignoresSafeArea()
    }

    private var topBar: some View {
        VStack{
            HStack {
                // ---- Close Button (Orange) ----
                Button(action: { dismiss() }) {
                    Text("Close")
                        .font(.headline)
                        .foregroundColor(.black)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.orange.opacity(0.95))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.black, lineWidth: 3)
                        )
                        .cornerRadius(8)
                }
                
                // ---- Map Type Button (Yellow) ----
                Button(action: { showingMapTypeSheet = true }) {
                    Text("Map Type")
                        .font(.headline)
                        .foregroundColor(.black)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.yellow.opacity(0.95))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.black, lineWidth: 3)
                        )
                        .cornerRadius(8)
                }
            }
            HStack{
                // ---- Filters Button (Green) ----
                Button(action: { showingFilterSheet = true }) {
                    Text("Filters")
                        .font(.headline)
                        .foregroundColor(.black)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.green.opacity(0.95))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.black, lineWidth: 3)
                        )
                        .cornerRadius(8)
                }
                
                // ---- Share Button (Blue) ----
                Button(action: { showingShareSheet = true }) {
                    Text("Share")
                        .font(.title3.bold())
                        .foregroundColor(.black)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.cyan.opacity(0.95))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.black, lineWidth: 3)
                        )
                        .cornerRadius(8)
                }
            }
            .disabled(markers.isEmpty)
            .opacity(markers.isEmpty ? 0.4 : 1.0)

        }
        .padding(.horizontal)
    }



    // MARK: - Logic

    private func styleForCurrentType() -> MapStyle {
        switch mapType {
        case .standard:
            return .standard
        case .satellite:
            return .imagery
        case .hybrid:
            return .hybrid
        case .mutedStandard:
            return .standard(elevation: .realistic, pointsOfInterest: .excludingAll)
        default:
            return .standard
        }
    }

    
    // MARK: - Map Type Sheet

    struct MapTypeSheetView: View {
        @Environment(\.dismiss) private var dismiss
        @Binding var mapType: MKMapType

        // Light brown background color
        private let sheetBackground = Color(
            red: 0.80,   // tweak these if you want
            green: 0.70,
            blue: 0.55,
            opacity: 0.95
        )

        var body: some View {
            ZStack {
                sheetBackground
                    .ignoresSafeArea()

                VStack(spacing: 16) {
                    Text("Choose Map Type")
                        .font(.title3.bold())
                        .padding(.top, 12)

                    mapTypeButton(
                        title: "Standard",
                        color: .clipBrightGreen.opacity(0.9),
                        textColor: .black
                    ) {
                        mapType = .standard
                        dismiss()
                    }

                    mapTypeButton(
                        title: "Satellite",
                        color: Color.blue.opacity(0.85),
                        textColor: .white
                    ) {
                        mapType = .satellite
                        dismiss()
                    }

                    mapTypeButton(
                        title: "Hybrid",
                        color: Color.orange.opacity(0.85),
                        textColor: .black
                    ) {
                        mapType = .hybrid
                        dismiss()
                    }

                    mapTypeButton(
                        title: "Muted Standard",
                        color: Color.darkYellow.opacity(0.75),
                        textColor: .black
                    ) {
                        mapType = .mutedStandard
                        dismiss()
                    }

                    Divider()
                        .padding(.vertical, 4)

                    mapTypeButton(
                        title: "Cancel",
                        color: Color.red.opacity(0.8),
                        textColor: .black
                    ) {
                        dismiss()
                    }

                    Spacer(minLength: 8)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }

        private func mapTypeButton(
            title: String,
            color: Color,
            textColor: Color,
            action: @escaping () -> Void
        ) -> some View {
            Button(action: action) {
                Text(title)
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .foregroundColor(textColor)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(color)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.black, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
        }
    }

    
    /// Initial map state = "last few catches with GPS", else Gilmour fallback
    private func loadInitialMarkers() {
        do {
            let recent = try DatabaseManager.shared
                .getCatchesWithLocationForMap(limit: 100, filters: nil)
            //TODO: check out the limit of map locations
            //TODO: May want to have the limit up to 500 or more???
            
            shareCatches = recent
            updateMarkers(from: recent)
        } catch {
            print("Map loadInitialMarkers failed: \(error)")
            // Fallback to Three Brothers on error
            shareCatches = []        // nothing to share on error
            updateMarkers(from: [])
        }
    }


    // Build markers & camera from DB catches
    
    private func updateMarkers(from catches: [CatchItem]) {
        // Convert CatchItem → MapCatchMarker📍
        let newMarkers: [MapCatchMarker] = catches.compactMap { c in
            guard
                let latE7 = c.latitudeE7,
                let lonE7 = c.longitudeE7
            else {
                return nil
            }

            let lat = Double(latE7) / 1_000_0000.0
            let lon = Double(lonE7) / 1_000_0000.0

            let coord = CLLocationCoordinate2D(latitude: lat, longitude: lon)

            let isTournament = (c.catchType ?? "")
                .lowercased()
                .contains("tourn")

            // Simple title/subtitle for now
            let title = c.species
            let date = Date(timeIntervalSince1970: TimeInterval(c.dateTimeSec))
            let fmt = DateFormatter()
            fmt.dateFormat = "yyyy-MM-dd HH:mm"
            let subtitle = fmt.string(from: date)

            return MapCatchMarker(
                title: title,
                subtitle: subtitle,
                coordinate: coord,
                isTournament: isTournament
            )
        }

        if newMarkers.isEmpty {
            // Fallback to Three Brothers Islands if no GPS catches match
            let threeBrothers = MapCatchMarker(
                title: "Three Brother Islands",
                subtitle: "Once a great fishery, before the Commorants",
                coordinate: CLLocationCoordinate2D(latitude: 44.20609722, longitude: -76.62511389),
                isTournament: false
            )
            markers = [threeBrothers]
            cameraPosition = .region(
                MKCoordinateRegion(
                    center: threeBrothers.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.4, longitudeDelta: 0.4)
                )
            )
        } else {
            markers = newMarkers

            // Center on the first catch, with a tighter span
            if let first = newMarkers.first {
                cameraPosition = .region(
                    MKCoordinateRegion(
                        center: first.coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2)
                    )
                )
            }
        }
    }

    
    /// Called when filters change (from MapQuerySheetView).
    private func applyFilters() {
        do {
            let results = try DatabaseManager.shared
                .getCatchesWithLocationForMap(limit: nil, filters: filters)
            print("Map filters applied: \(filters)")
            // 🔹 These are the catches the share sheet will use
            shareCatches = results
            updateMarkers(from: results)
        } catch {
            print("Map applyFilters failed: \(error)")
            // On failure, don't share anything new
            shareCatches = []
        }
    }

    
}

// MARK: - Preview

#Preview {
    if #available(iOS 17.0, *) {
        MapCatchLocationsView()
    } else {
        // Fallback on earlier versions
    }
}

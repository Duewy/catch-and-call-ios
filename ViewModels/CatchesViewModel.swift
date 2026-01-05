//  CatchesViewModel.swift
//  CatchAndCall

import Foundation
import Combine

@MainActor
final class CatchesViewModel: ObservableObject {
    @Published var today: [CatchItem] = []

    init() {
        do {
            try DatabaseManager.shared.openIfNeeded()
            print("DB opened 👍")
            reloadToday()
        } catch {
            print("DB open failed: \(error)")
        }
    }
    
 //--------------------------------------------------
    func reloadToday() {
        do {
            today = try DatabaseManager.shared.getCatchesOn(date: Date())
        } catch {
            print("Reload failed: \(error)")
        }
    }
    
    //--------------------------------------------------
    // ============================
    // Lbs / Ozs  (SAVED as Ounces)
    // ============================
    func saveLbsOz(species: String, lbs: Int, oz: Int, latE7: Int? = nil, lonE7: Int? = nil) {
        do {
            let totalOz = DatabaseManager.totalOz(lbs: lbs, oz: oz)
            let nowSec = Int64(Date().timeIntervalSince1970)

            let item = CatchItem(
                id: 0,
                dateTimeSec: nowSec,
                species: SpeciesStorage.normalizeSpeciesName(species),
                totalWeightOz: totalOz,
                totalWeightPoundsHundredth: nil,
                totalWeightHundredthKg: nil,
                totalLengthQuarters: nil,
                totalLengthCm: nil,
                catchType: "Fun Day",
                markerType: nil,
                clipColor: nil,
                latitudeE7: latE7,
                longitudeE7: lonE7,
                primaryPhotoId: nil,
                createdAtSec: nowSec
            )

            _ = try DatabaseManager.shared.insertCatch(item)
            reloadToday()
        } catch {
            print("Save failed: \(error)")
        }
    }//-----------------END-- SaveLbs ----------------
    // ============================
    // Pounds.xx  (SAVED as hundredths of pounds)
    // ============================
    func savePoundsHundredth(species: String, whole: Int, hundredths: Int, latE7: Int? = nil, lonE7: Int? = nil) {
        do {
            let w = max(0, whole)
            let h = max(0, min(hundredths, 99))
            let hundredthLb = DatabaseManager.poundsHundredth(whole: w, hundredths: h)
            let nowSec = Int64(Date().timeIntervalSince1970)

            let item = CatchItem(
                id: 0,
                dateTimeSec: nowSec,
                species: SpeciesStorage.normalizeSpeciesName(species),
                totalWeightOz: nil,
                totalWeightPoundsHundredth: hundredthLb,
                totalWeightHundredthKg: nil,
                totalLengthQuarters: nil,
                totalLengthCm: nil,
                catchType: "Fun Day",
                markerType: nil,
                clipColor: nil,
                latitudeE7: latE7,
                longitudeE7: lonE7,
                primaryPhotoId: nil,
                createdAtSec: nowSec
            )

            _ = try DatabaseManager.shared.insertCatch(item)
            reloadToday()
        } catch {
            print("Save failed: \(error)")
        }
    }

    // ============================
    // Kilograms.xx  (SAVED as hundredths of kg)
    // ============================
    func saveKgsHundredth(species: String, wholeKg: Int, hundredths: Int, latE7: Int? = nil, lonE7: Int? = nil) {
        do {
            let w = max(0, wholeKg)
            let h = max(0, min(hundredths, 99))
            let hundredthKg = w &* 100 &+ h
            let nowSec = Int64(Date().timeIntervalSince1970)

            let item = CatchItem(
                id: 0,
                dateTimeSec: nowSec,
                species: SpeciesStorage.normalizeSpeciesName(species),
                totalWeightOz: nil,
                totalWeightPoundsHundredth: nil,
                totalWeightHundredthKg: hundredthKg,
                totalLengthQuarters: nil,
                totalLengthCm: nil,
                catchType: "Fun Day",
                markerType: nil,
                clipColor: nil,
                latitudeE7: latE7,
                longitudeE7: lonE7,
                primaryPhotoId: nil,
                createdAtSec: nowSec
            )

            _ = try DatabaseManager.shared.insertCatch(item)
            reloadToday()
        } catch {
            print("Save failed: \(error)")
        }
    }

    // ============================
    // Inches (whole + quarter)  (SAVED as quarters)
    // ============================
    func saveInchesQuarters(species: String, wholeInches: Int, quarter: Int, latE7: Int? = nil, lonE7: Int? = nil) {
        do {
            let w = max(0, wholeInches)
            let q = max(0, min(quarter, 3))
            let quarters = DatabaseManager.quartersFromInches(whole: w, quarter: q)
            let nowSec = Int64(Date().timeIntervalSince1970)

            let item = CatchItem(
                id: 0,
                dateTimeSec: nowSec,
                species: SpeciesStorage.normalizeSpeciesName(species),
                totalWeightOz: nil,
                totalWeightPoundsHundredth: nil,
                totalWeightHundredthKg: nil,
                totalLengthQuarters: quarters,
                totalLengthCm: nil,
                catchType: "Fun Day",
                markerType: nil,
                clipColor: nil,
                latitudeE7: latE7,
                longitudeE7: lonE7,
                primaryPhotoId: nil,
                createdAtSec: nowSec
            )

            _ = try DatabaseManager.shared.insertCatch(item)
            reloadToday()
        } catch {
            print("Save failed: \(error)")
        }
    }

    // ============================
    // Centimeters (whole + tenth)  (SAVED as tenths of cm)
    // ============================
    func saveCentimeters(species: String, wholeCm: Int, tenth: Int, latE7: Int? = nil, lonE7: Int? = nil) {
        do {
            let w = max(0, wholeCm)
            let t = max(0, min(tenth, 9))
            let tenths = DatabaseManager.tenthsCm(whole: w, tenth: t)
            let nowSec = Int64(Date().timeIntervalSince1970)

            let item = CatchItem(
                id: 0,
                dateTimeSec: nowSec,
                species: SpeciesStorage.normalizeSpeciesName(species),
                totalWeightOz: nil,
                totalWeightPoundsHundredth: nil,
                totalWeightHundredthKg: nil,
                totalLengthQuarters: nil,
                totalLengthCm: tenths,
                catchType: "Fun Day",
                markerType: nil,
                clipColor: nil,
                latitudeE7: latE7,
                longitudeE7: lonE7,  
                primaryPhotoId: nil,
                createdAtSec: nowSec
            )

            _ = try DatabaseManager.shared.insertCatch(item)
            reloadToday()
        } catch {
            print("Save failed: \(error)")
        }
    }

 //--------------------------------------------------
    func deleteCatch(id: Int64) {
        do {
            try DatabaseManager.shared.deleteCatch(id: id)
            reloadToday()
        } catch {
            print("Delete failed: \(error)")
        }
    }
//-----------------------------------------------
    // ============================
    // Lbs / Ozs  (stored as Ounces)
    // ============================
    func updateCatchLbsOzs(original: CatchItem, species: String, lbs: Int, oz: Int) {
        let clampedOz = max(0, min(oz, 15))
        let total = DatabaseManager.totalOz(lbs: max(0, lbs), oz: clampedOz)

        var updated = original
        updated.species = SpeciesStorage.normalizeSpeciesName(species)
        updated.totalWeightOz = total

        do {
            try DatabaseManager.shared.updateCatch(updated)
            reloadToday()
        } catch {
            print("Update failed: \(error)")
        }
    }
    //--------------------------------------------------
    // ============================
    // Pounds.xx (stored as hundredths)
    // ============================
    func updateCatchPoundsHundredth(original: CatchItem, species: String, whole: Int, hundredths: Int) {
        let w = max(0, whole)
        let h = max(0, min(hundredths, 99))
        let hundredth = DatabaseManager.poundsHundredth(whole: w, hundredths: h)

        var updated = original
        updated.species = SpeciesStorage.normalizeSpeciesName(species)

        // Update only the WEIGHT family fields
        updated.totalWeightPoundsHundredth = hundredth
        updated.totalWeightOz = nil
        updated.totalWeightHundredthKg = nil

        do {
            try DatabaseManager.shared.updateCatch(updated)
            reloadToday()
        } catch {
            print("Update failed: \(error)")
        }
    }
    //--------------------------------------------------
    // ============================
    // Kilograms.xx (stored as hundredths)
    // ============================
    func updateCatchKgsHundredth(original: CatchItem, species: String, wholeKg: Int, hundredths: Int) {
        let w = max(0, wholeKg)
        let h = max(0, min(hundredths, 99))
        let hundredthKg = w &* 100 &+ h   // integer math only

        var updated = original
        updated.species = SpeciesStorage.normalizeSpeciesName(species)

        // Update only the WEIGHT family fields
        updated.totalWeightHundredthKg = hundredthKg
        updated.totalWeightOz = nil
        updated.totalWeightPoundsHundredth = nil

        do {
            try DatabaseManager.shared.updateCatch(updated)
            reloadToday()
        } catch {
            print("Update failed: \(error)")
        }
    }
    //--------------------------------------------------
    // ============================
    // Centimeters (whole + tenth) → tenths of cm
    // ============================
    func updateCatchCentimeters(original: CatchItem, species: String, wholeCm: Int, tenth: Int) {
        let w = max(0, wholeCm)
        let t = max(0, min(tenth, 9))
        let tenths = DatabaseManager.tenthsCm(whole: w, tenth: t)

        var updated = original
        updated.species = SpeciesStorage.normalizeSpeciesName(species)

        // Update only the LENGTH family fields
        updated.totalLengthCm = tenths
        updated.totalLengthQuarters = nil

        do {
            try DatabaseManager.shared.updateCatch(updated)
            reloadToday()
        } catch {
            print("Update failed: \(error)")
        }
    }
    //--------------------------------------------------
    // ============================
    // Inches (whole + quarter) → quarters
    // ============================
    func updateCatchInchesQuarters(original: CatchItem, species: String, wholeInches: Int, quarter: Int) {
        let w = max(0, wholeInches)
        let q = max(0, min(quarter, 3))
        let quarters = DatabaseManager.quartersFromInches(whole: w, quarter: q)

        var updated = original
        updated.species = SpeciesStorage.normalizeSpeciesName(species)

        // Update only the LENGTH family fields
        updated.totalLengthQuarters = quarters
        updated.totalLengthCm = nil

        do {
            try DatabaseManager.shared.updateCatch(updated)
            reloadToday()
        } catch {
            print("Update failed: \(error)")
        }
    }
    //--------------------------------------------------

}

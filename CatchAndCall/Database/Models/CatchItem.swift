// =============================
// File: Database/Models/CatchItem.swift
// =============================


import Foundation

struct CatchItem: Identifiable {
    var id: Int64
    var dateTimeSec: Int64             // epoch seconds
    var species: String

    // Weights
    var totalWeightOz: Int?            // whole ounces
    var totalWeightPoundsHundredth: Int?
    var totalWeightHundredthKg: Int?

    // Lengths
    var totalLengthQuarters: Int?
    var totalLengthCm: Int?            // tenths of cm

    // Meta
    var catchType: String?
    var markerType: String?
    var clipColor: String?

    // Location (ints)
    var latitudeE7: Int?
    var longitudeE7: Int?

    var primaryPhotoId: String?
    var createdAtSec: Int64

    // --- Convenience for UI formatting (still integer math) ---
    var poundsWholeAndHundredths: (Int, Int)? {
        guard let h = totalWeightPoundsHundredth else { return nil }
        return DatabaseManager.poundsWholeAndHundredths(h)
    }

    var inchesWholeAndQuarters: (Int, Int)? {
        guard let q = totalLengthQuarters else { return nil }
        return DatabaseManager.inchesWholeAndQuarters(q)
    }

    var cmWholeAndTenth: (Int, Int)? {
        guard let t = totalLengthCm else { return nil }
        return DatabaseManager.cmWholeAndTenth(t)
    }

    var latString: String? {
        guard let e7 = latitudeE7 else { return nil }
        return DatabaseManager.decimalStringFromE7(e7)
    }

    var lonString: String? {
        guard let e7 = longitudeE7 else { return nil }
        return DatabaseManager.decimalStringFromE7(e7)
    }
}

//
//  MeasureHelpers.swift
//  CatchAndCall
//
//  Created by Dwayne Brame on 2025-11-01.
//

// =============================
// File: Helpers/MeasureHelpers.swift
// =============================

import Foundation

enum MeasureHelpers {
    // MARK: - Merge (UI parts -> canonical Ints)


    /// lbs/oz -> total ounces
    static func totalOz(lbs: Int, oz: Int) -> Int {
        let L = max(0, lbs)
        let O = max(0, min(oz, 15))
        return L &* 16 &+ O
    }

    /// whole + hundredths of lb -> hundredths
    static func poundsHundredth(whole: Int, hundredths: Int) -> Int {
        let w = max(0, whole)
        let h = max(0, min(hundredths, 99))
        return w &* 100 &+ h
    }

    /// whole + hundredths of kg -> hundredths
    static func kgsHundredth(whole: Int, hundredths: Int) -> Int {
        let w = max(0, whole)
        let h = max(0, min(hundredths, 99))
        return w &* 100 &+ h
    }

    /// whole inches + quarter (0..3) -> quarters
    static func quartersFromInches(whole: Int, quarter: Int) -> Int {
        let w = max(0, whole)
        let q = max(0, min(quarter, 3))
        return w &* 4 &+ q
    }

    /// whole cm + tenth (0..9) -> tenths of cm
    static func tenthsCm(whole: Int, tenth: Int) -> Int {
        let w = max(0, whole)
        let t = max(0, min(tenth, 9))
        return w &* 10 &+ t
    }

    // MARK: - Split (canonical Ints -> UI parts)

    static func lbsOz(fromTotalOz total: Int) -> (lbs: Int, oz: Int) {
        let t = max(0, total)
        return (t / 16, t % 16)
    }

    static func splitHundredth(_ h: Int) -> (whole: Int, hundredths: Int) {
        let absH = abs(h)
        return (absH / 100, absH % 100)
    }

    static func splitTenths(_ t: Int) -> (whole: Int, tenth: Int) {
        let absT = abs(t)
        return (absT / 10, absT % 10)
    }

    static func splitQuarters(_ q: Int) -> (whole: Int, quarter: Int) {
        let absQ = abs(q)
        return (absQ / 4, absQ % 4)
    }

    // MARK: - Integer-only formatting (for UI labels)

    static func formatPoundsHundredth(_ h: Int) -> String {
        let p = splitHundredth(h)
        return "\(p.whole).\(String(format: "%02d", p.hundredths)) lb"
    }

    static func formatKgsHundredth(_ h: Int) -> String {
        let k = splitHundredth(h)
        return "\(k.whole).\(String(format: "%02d", k.hundredths)) kg"
    }

    static func formatInchesQuarters(_ q: Int) -> String {
        let s = splitQuarters(q)
        let frac = ["", "¼", "½", "¾"][s.quarter]
        return s.quarter == 0 ? "\(s.whole)\"" : "\(s.whole) \(frac)\""
    }

    static func formatCentimeters(_ t: Int) -> String {
        let s = splitTenths(t)
        return "\(s.whole).\(s.tenth) cm"
    }

    // MARK: - Time & GPS (integer-safe)

    static func dateFromSeconds(_ sec: Int64) -> Date {
        Date(timeIntervalSince1970: TimeInterval(sec))
    }

    /// E7 int -> decimal string without using Double (e.g., -759123456 -> "-75.9123456")
    static func degreesString(fromE7 e7: Int) -> String {
        let sign = e7 < 0 ? "-" : ""
        let absVal = e7 < 0 ? -e7 : e7
        let whole = absVal / 10_000_000
        let frac  = absVal % 10_000_000
        return "\(sign)\(whole).\(String(format: "%07d", frac))"
    }
}


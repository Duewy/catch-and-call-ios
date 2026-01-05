// =============================
// File: Database/Helpers/DatabaseHelpers.swift
// =============================

import Foundation
import SQLite3

extension DatabaseManager {
    // NOTE: keeping your existing case names for compatibility,
    // but .weightDecimalLb now means "pounds * 100" (hundredths of lb)
    enum TournamentMeasure { case weightOz, weightDecimalLb, weightHundredthKg, length }

    struct TournamentConfig {
        var date: Date
        var limit: Int
        var species: [String]? = nil
        var includeCatchTypes: [String]? = ["Tournament"]
        var measure: TournamentMeasure
    }

    /// Unified Top-N for Tournament leaderboard (weight or length) with filters
    func getTopTournamentCatches(_ cfg: TournamentConfig,
                                 calendar: Calendar = .current) throws -> [CatchItem] {
        try openIfNeeded()

        // --- Int-only time range (seconds) ---
        let startSec = Int64(calendar.startOfDay(for: cfg.date).timeIntervalSince1970)
        let endSec   = startSec + 86_400

        // WHERE clauses and binders (all ints/strings)
        var whereClauses = ["date_time_sec >= ?", "date_time_sec < ?"]
        var binders: [(OpaquePointer?, Int32) -> Void] = []
        binders.append { stmt, i in self.bindInt64(stmt, i, startSec) }
        binders.append { stmt, i in self.bindInt64(stmt, i, endSec) }

        if let list = cfg.species, !list.isEmpty {
            let ph = Array(repeating: "?", count: list.count).joined(separator: ",")
            whereClauses.append("species IN (\(ph))")
            for s in list { binders.append { stmt, i in self.bindText(stmt, i, s) } }
        }
        if let kinds = cfg.includeCatchTypes, !kinds.isEmpty {
            let ph = Array(repeating: "?", count: kinds.count).joined(separator: ",")
            whereClauses.append("catch_type IN (\(ph))")
            for k in kinds { binders.append { stmt, i in self.bindText(stmt, i, k) } }
        }

        // ORDER expression + non-null guard, all using NEW columns
        let (orderExpr, nonNullCheck): (String, String) = {
            switch cfg.measure {
            case .weightOz:
                return ("total_weight_oz", "total_weight_oz IS NOT NULL")

            case .weightDecimalLb:
                // NEW: hundredths of pounds (lb * 100)
                return ("total_weight_hundredth_lb", "total_weight_hundredth_lb IS NOT NULL")

            case .weightHundredthKg:
                return ("total_weight_hundredth_kg", "total_weight_hundredth_kg IS NOT NULL")

            case .length:
                // Unify to millimetres (integer):
                // - total_length_cm = tenths of cm = millimetres value already
                // - total_length_quarters * 6.35mm  -> approx with integer rounding: (q*635 + 50) / 100
                let mmExpr = """
                CASE
                    WHEN total_length_cm IS NOT NULL
                        THEN total_length_cm
                    WHEN total_length_quarters IS NOT NULL
                        THEN ((total_length_quarters * 635 + 50) / 100)
                    ELSE 0
                END
                """
                return (mmExpr, "(total_length_cm IS NOT NULL OR total_length_quarters IS NOT NULL)")
            }
        }()

        let sql = """
        SELECT * FROM catches
        WHERE \(whereClauses.joined(separator: " AND ")) AND \(nonNullCheck)
        ORDER BY \(orderExpr) DESC, date_time_sec ASC
        LIMIT ?;
        """

        var rows: [CatchItem] = []
        var thrown: Error?

        queue.sync {
            var stmt: OpaquePointer?
            defer { sqlite3_finalize(stmt) }

            guard let db = db,
                  sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK
            else { thrown = lastError(); return }

            var idx: Int32 = 1
            for b in binders { b(stmt, idx); idx += 1 }
            self.bindInt(stmt, idx, cfg.limit)

            while sqlite3_step(stmt) == SQLITE_ROW, let s = stmt {
                rows.append(self.parseCatch(s))
            }
        }

        if let e = thrown { throw e }
        return rows
    }

    // Totals for leaderboard headers
    // NOTE: raw is kept as Double to avoid ripples in your callers,
    // but all math here stays integer until the final divide for display.
    func tournamentWeightTotal(_ items: [CatchItem], measure: TournamentMeasure) -> (display: String, raw: Double) {
        switch measure {
        case .weightOz:
            let sumOz = items.compactMap { $0.totalWeightOz }.reduce(0, +)
            let (lbs, oz) = DatabaseManager.lbsOz(fromTotalOz: sumOz)
            return ("\(lbs) lb \(oz) oz", Double(sumOz))

        case .weightDecimalLb:
            // NEW: use hundredths-of-pound column
            let sumHund = items.compactMap { $0.totalWeightPoundsHundredth }.reduce(0, +)
            // Display "12.34 lb" but computed from ints:
            let disp = MeasureHelpers.formatPoundsHundredth(sumHund)
            return (disp, Double(sumHund) / 100.0)

        case .weightHundredthKg:
            let sumHundKg = items.compactMap { $0.totalWeightHundredthKg }.reduce(0, +)
            let disp = MeasureHelpers.formatKgsHundredth(sumHundKg)
            return (disp, Double(sumHundKg) / 100.0)

        case .length:
            return ("—", 0)
        }
    }

    // Length totals purely with integers.
    // preferCm = true -> sum tenths-of-cm; otherwise sum quarters and print in inches+quarters.
    func tournamentLengthTotal(_ items: [CatchItem], preferCm: Bool) -> String {
        if preferCm {
            // Sum tenths-of-cm directly; convert quarters to tenths with integer rounding.
            let totalCm10 = items.reduce(0) { acc, c in
                if let cm10 = c.totalLengthCm { return acc &+ cm10 }
                if let q = c.totalLengthQuarters {
                    // q quarters * 6.35mm -> tenths-of-cm: (q * 635) / 100 with rounding
                    return acc &+ ((q &* 635 &+ 50) / 100)
                }
                return acc
            }
            // Format as X.Y cm via helper
            return MeasureHelpers.formatCentimeters(totalCm10)

        } else {
            // Sum quarters; if only cm present, convert cm (tenths) -> quarters with rounding.
            let totalQtr = items.reduce(0) { acc, c in
                if let q = c.totalLengthQuarters { return acc &+ q }
                if let cm10 = c.totalLengthCm {
                    // quarters ≈ round(mm / 6.35) -> round((cm10*10) / 6.35)
                    // Use integer rounding: (cm10*100 + 317) / 635
                    let qFromCm = (cm10 &* 100 &+ 317) / 635
                    return acc &+ qFromCm
                }
                return acc
            }
            // Render nicely: e.g., 12 ¼"
            return MeasureHelpers.formatInchesQuarters(totalQtr)
        }
    }
}

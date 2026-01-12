// =============================
// File: Database/Data/WeightData.swift
// =============================

import Foundation
import SQLite3

extension DatabaseManager {
    enum WeightMode { case totalOz, hundredthLb, hundredthKg }

    /// Top N catches for the given day by a chosen weight column (all integer storage)
    func getTopNCatches(by mode: WeightMode,
                        limit: Int,
                        on date: Date,
                        calendar: Calendar = .current) throws -> [CatchItem] {
        try openIfNeeded()

        let startSec = Int64(calendar.startOfDay(for: date).timeIntervalSince1970)
        let endSec   = startSec + 86_400

        let col: String = {
            switch mode {
            case .totalOz:    return "total_weight_oz"
            case .hundredthLb:return "total_weight_hundredth_lb"
            case .hundredthKg:return "total_weight_hundredth_kg"
            }
        }()

        let sql = """
        SELECT * FROM catches
        WHERE date_time_sec >= ? AND date_time_sec < ? AND \(col) IS NOT NULL
        ORDER BY \(col) DESC
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

            bindInt64(stmt, 1, startSec)
            bindInt64(stmt, 2, endSec)
            bindInt(stmt, 3, limit)

            while sqlite3_step(stmt) == SQLITE_ROW, let s = stmt {
                rows.append(parseCatch(s))
            }
        }

        if let e = thrown { throw e }
        return rows
    }
}

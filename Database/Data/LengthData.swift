// =============================
// File: Database/Data/LengthData.swift
// =============================

import Foundation
import SQLite3

extension DatabaseManager {
    /// Top N catches for the day by length, combining quarter-inches and millimetres (tenths of cm)
    func getTopNByLength(limit: Int,
                         on date: Date,
                         calendar: Calendar = .current) throws -> [CatchItem] {
        try openIfNeeded()

        let startSec = Int64(calendar.startOfDay(for: date).timeIntervalSince1970)
        let endSec   = startSec + 86_400

        // Unify to millimetres for sorting.
        // For quarter-inches: 1 quarter = 6.35 mm -> integer rounding: (q * 635 + 50) / 100
        let sql = """
        SELECT *,
               CASE
                   WHEN total_length_cm IS NOT NULL
                       THEN total_length_cm
                   WHEN total_length_quarters IS NOT NULL
                       THEN ((total_length_quarters * 635 + 50) / 100)
                   ELSE 0
               END AS sort_length_mm
        FROM catches
        WHERE date_time_sec >= ? AND date_time_sec < ?
        ORDER BY sort_length_mm DESC
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

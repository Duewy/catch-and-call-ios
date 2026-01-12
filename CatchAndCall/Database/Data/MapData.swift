//  MapData.swift
//  CatchAndCall
//
//  Helpers for map queries (catches with GPS & optional filters)

import Foundation
import SQLite3

extension DatabaseManager {

    /// Parse "YYYY-MM-DD to YYYY-MM-DD" into [startSec, endSec)
    private func mapDateRangeSeconds(from range: String) -> (Int64, Int64)? {
        let parts = range.components(separatedBy: "to")
            .map { $0.trimmingCharacters(in: .whitespaces) }
        guard parts.count == 2 else { return nil }

        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "en_US_POSIX")
        fmt.timeZone = .current
        fmt.dateFormat = "yyyy-MM-dd"

        guard
            let startDate = fmt.date(from: parts[0]),
            let endDate   = fmt.date(from: parts[1])
        else { return nil }

        let cal = Calendar.current
        let startDay = cal.startOfDay(for: startDate)
        let endDay   = cal.date(byAdding: .day, value: 1, to: cal.startOfDay(for: endDate)) ?? endDate

        let startSec = Int64(startDay.timeIntervalSince1970)
        let endSec   = Int64(endDay.timeIntervalSince1970)
        return (startSec, endSec)
    }

    /// Get catches that have GPS set, with *simple* filters:
    /// - dateRange: "YYYY-MM-DD to YYYY-MM-DD" or "All"
    /// - species: "All" or exact match
    /// - eventType: "Fun Day", "Tournament", or "Both"
    ///
    /// Size + measurement filters are TODO for now.
    func getCatchesWithLocationForMap(limit: Int? = nil,
                                      filters: MapQueryFilters? = nil) throws -> [CatchItem] {
        try openIfNeeded()

        var whereClauses: [String] = [
            "latitude_e7 IS NOT NULL",
            "longitude_e7 IS NOT NULL"
        ]

        var args: [Any] = []

        if let f = filters {
            // Date range
            if f.dateRange != "All",
               let (startSec, endSec) = mapDateRangeSeconds(from: f.dateRange) {
                whereClauses.append("date_time_sec >= ?")
                whereClauses.append("date_time_sec < ?")
                args.append(startSec)
                args.append(endSec)
            }

            // Species (we saved normalized species, usually lowercase)
            if f.species != "All" {
                whereClauses.append("species = ?")
                args.append(f.species.lowercased())
            }

            // Event type
            if f.eventType != "Both" {
                whereClauses.append("catch_type = ?")
                args.append(f.eventType)
            }

            // NOTE: sizeType + sizeRange + measurementType
            // can be wired later; for now we ignore them to keep it simple.
        }

        var sql = "SELECT * FROM catches"
        if !whereClauses.isEmpty {
            sql += " WHERE " + whereClauses.joined(separator: " AND ")
        }
        sql += " ORDER BY date_time_sec DESC"
        if let l = limit {
            sql += " LIMIT \(l)"
        }

        var rows: [CatchItem] = []
        var thrown: Error?

        queue.sync {
            var stmt: OpaquePointer?
            defer { sqlite3_finalize(stmt) }

            guard let db = db,
                  sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK
            else {
                thrown = lastError()
                return
            }

            // Bind arguments
            var idx: Int32 = 1
            for arg in args {
                if let v = arg as? Int64 {
                    bindInt64(stmt, idx, v)
                } else if let v = arg as? Int {
                    bindInt(stmt, idx, v)
                } else if let v = arg as? String {
                    bindText(stmt, idx, v)
                }
                idx += 1
            }

            while sqlite3_step(stmt) == SQLITE_ROW, let s = stmt {
                rows.append(parseCatch(s))
            }
        }

        if let e = thrown { throw e }
        return rows
    }
}

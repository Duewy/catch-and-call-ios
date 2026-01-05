// =============================
// File: Database/Core/DatabaseManager.swift
// =============================

import Foundation
import SQLite3

let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

final class DatabaseManager {
    static let shared = DatabaseManager()

    var db: OpaquePointer?
    let queue = DispatchQueue(label: "db.serial.queue")
    private let dbFileName = "catch_and_call.sqlite"
    private let targetUserVersion: Int32 = 1

    private init() {}

    // MARK: - Lifecycle
    func openIfNeeded() throws {
        if db != nil { return }
        let url = try databaseURL()
        var handle: OpaquePointer?
        if sqlite3_open(url.path, &handle) != SQLITE_OK {
            defer { if handle != nil { sqlite3_close(handle) } }
            throw error(message: "Unable to open database")
        }
        db = handle
        try enableWAL()
        try createTablesIfNeeded()
    }

    func close() {
        queue.sync {
            if let handle = db { sqlite3_close(handle); db = nil }
        }
    }

    /// One-time nuke when moving to this clean schema.
    func resetDatabase() throws {
        close()
        let url = try databaseURL()
        try FileManager.default.removeItem(at: url)
    }

    // MARK: - Schema (ALL INT STORAGE)
    private func createTablesIfNeeded() throws {
        let catchesSQL = """
        CREATE TABLE IF NOT EXISTS catches (
            id INTEGER PRIMARY KEY AUTOINCREMENT,

            -- time & identity
            date_time_sec INTEGER NOT NULL,          -- epoch seconds (Int64 ok in SQLite INTEGER)
            species TEXT NOT NULL,

            -- weights (integers only)
            total_weight_oz INTEGER,                 -- whole ounces
            total_weight_hundredth_lb INTEGER,       -- lb * 100 (12.34 lb -> 1234)
            total_weight_hundredth_kg INTEGER,       -- kg * 100 (2.34 kg -> 234)

            -- lengths (integers only)
            total_length_quarters INTEGER,           -- quarter-inches (12.25" -> 49)
            total_length_cm INTEGER,                 -- tenths of cm (45.7 cm -> 457)

            -- meta
            catch_type TEXT,
            marker_type TEXT,
            clip_color TEXT,

            -- location (integers only)
            latitude_e7 INTEGER,                     -- lat * 1e7 (e.g., 44.1234567 -> 441234567)
            longitude_e7 INTEGER,                    -- lon * 1e7

            primary_photo_id TEXT,
            created_at_sec INTEGER NOT NULL          -- epoch seconds
        );
        """

        let photosSQL = """
        CREATE TABLE IF NOT EXISTS photos (
            photo_id TEXT PRIMARY KEY,
            catch_id INTEGER,
            local_path TEXT NOT NULL,
            mime_type TEXT,
            width INTEGER,
            height INTEGER,
            file_size INTEGER,                       -- fits 64-bit in SQLite INTEGER
            taken_at_sec INTEGER,                    -- epoch seconds
            created_at_sec INTEGER NOT NULL,
            FOREIGN KEY(catch_id) REFERENCES catches(id) ON DELETE SET NULL
        );
        """

        let idx1 = "CREATE INDEX IF NOT EXISTS idx_catches_date ON catches(date_time_sec);"
        let idx2 = "CREATE INDEX IF NOT EXISTS idx_photos_catch_id ON photos(catch_id);"

        try exec(sql: catchesSQL)
        try exec(sql: photosSQL)
        try exec(sql: idx1)
        try exec(sql: idx2)
        try setUserVersion(targetUserVersion)
    }

    // MARK: - Catches CRUD
    @discardableResult
    func insertCatch(_ c: CatchItem) throws -> Int64 {
        try openIfNeeded()
        let sql = """
        INSERT INTO catches (
            date_time_sec,
            species,
            total_weight_oz,
            total_weight_hundredth_lb,
            total_weight_hundredth_kg,
            total_length_quarters,
            total_length_cm,
            catch_type, marker_type,
            clip_color,
            latitude_e7,
            longitude_e7,
            primary_photo_id,
            created_at_sec
            ) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?);
        """

        var rowid: Int64 = -1
        var thrown: Error?

        queue.sync {
            var stmt: OpaquePointer?
            defer { sqlite3_finalize(stmt) }

            guard let db = db,
                  sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK
            else { thrown = lastError(); return }

            bindInt64(stmt, 1, c.dateTimeSec)
            bindText(stmt, 2, c.species)

            bindIntOrNull(stmt, 3, c.totalWeightOz)
            bindIntOrNull(stmt, 4, c.totalWeightPoundsHundredth)
            bindIntOrNull(stmt, 5, c.totalWeightHundredthKg)

            bindIntOrNull(stmt, 6, c.totalLengthQuarters)
            bindIntOrNull(stmt, 7, c.totalLengthCm)

            bindTextOrNull(stmt, 8,  c.catchType)
            bindTextOrNull(stmt, 9,  c.markerType)
            bindTextOrNull(stmt, 10, c.clipColor)

            bindIntOrNull(stmt, 11, c.latitudeE7)
            bindIntOrNull(stmt, 12, c.longitudeE7)
            bindTextOrNull(stmt, 13, c.primaryPhotoId)

            bindInt64(stmt, 14, c.createdAtSec)

            if sqlite3_step(stmt) == SQLITE_DONE {
                rowid = sqlite3_last_insert_rowid(db)
            } else {
                thrown = lastError()
            }
        }

        if let e = thrown { throw e }
        return rowid
    }

    func updateCatch(_ c: CatchItem) throws {
        try openIfNeeded()
        let sql = """
        UPDATE catches SET
            date_time_sec=?,
            species=?,
            total_weight_oz=?,
            total_weight_hundredth_lb=?,
            total_weight_hundredth_kg=?,
            total_length_quarters=?,
            total_length_cm=?,
            catch_type=?,
            marker_type=?,
            clip_color=?,
            latitude_e7=?,
            longitude_e7=?,
            primary_photo_id=?
            WHERE id=?;
        """

        var thrown: Error?
        queue.sync {
            var stmt: OpaquePointer?
            defer { sqlite3_finalize(stmt) }

            guard let db = db,
                  sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK
            else { thrown = lastError(); return }

            bindInt64(stmt, 1, c.dateTimeSec)
            bindText(stmt, 2, c.species)

            bindIntOrNull(stmt, 3, c.totalWeightOz)
            bindIntOrNull(stmt, 4, c.totalWeightPoundsHundredth)
            bindIntOrNull(stmt, 5, c.totalWeightHundredthKg)

            bindIntOrNull(stmt, 6, c.totalLengthQuarters)
            bindIntOrNull(stmt, 7, c.totalLengthCm)

            bindTextOrNull(stmt, 8,  c.catchType)
            bindTextOrNull(stmt, 9,  c.markerType)
            bindTextOrNull(stmt, 10, c.clipColor)

            bindIntOrNull(stmt, 11, c.latitudeE7)
            bindIntOrNull(stmt, 12, c.longitudeE7)
            bindTextOrNull(stmt, 13, c.primaryPhotoId)

            bindInt64(stmt, 14, c.id)

            if sqlite3_step(stmt) != SQLITE_DONE { thrown = lastError() }
        }
        if let e = thrown { throw e }
    }

    func deleteCatch(id: Int64) throws {
        try openIfNeeded()
        let sql = "DELETE FROM catches WHERE id=?;"
        var thrown: Error?
        queue.sync {
            var stmt: OpaquePointer?
            defer { sqlite3_finalize(stmt) }
            guard let db = db,
                  sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK
            else { thrown = lastError(); return }
            bindInt64(stmt, 1, id)
            if sqlite3_step(stmt) != SQLITE_DONE { thrown = lastError() }
        }
        if let e = thrown { throw e }
    }

    func getCatch(id: Int64) throws -> CatchItem? {
        try openIfNeeded()
        let sql = "SELECT * FROM catches WHERE id=?;"
        return try queue.sync {
            var stmt: OpaquePointer?; defer { sqlite3_finalize(stmt) }
            guard let db = db,
                  sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK
            else { throw lastError() }
            bindInt64(stmt, 1, id)
            if sqlite3_step(stmt) == SQLITE_ROW, let s = stmt { return parseCatch(s) }
            return nil
        }
    }

    func getCatchesOn(date: Date, calendar: Calendar = .current) throws -> [CatchItem] {
        try openIfNeeded()
        let startSec = Int64(calendar.startOfDay(for: date).timeIntervalSince1970)
        let endSec   = Int64(calendar.date(byAdding: .day, value: 1, to: Date(timeIntervalSince1970: TimeInterval(startSec)))!.timeIntervalSince1970)
        let sql = "SELECT * FROM catches WHERE date_time_sec >= ? AND date_time_sec < ? ORDER BY date_time_sec ASC;"
        return try queue.sync {
            var stmt: OpaquePointer?; defer { sqlite3_finalize(stmt) }
            guard let db = db,
                  sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK
            else { throw lastError() }
            bindInt64(stmt, 1, startSec)
            bindInt64(stmt, 2, endSec)
            var rows: [CatchItem] = []
            while sqlite3_step(stmt) == SQLITE_ROW, let s = stmt { rows.append(parseCatch(s)) }
            return rows
        }
    }
    
    

    // MARK: - Parsing
    func parseCatch(_ s: OpaquePointer) -> CatchItem {
        // Column order matches CREATE TABLE
        let id = sqlite3_column_int64(s, 0)
        let dateTimeSec = sqlite3_column_int64(s, 1)
        let species = stringColumn(s, 2) ?? "unknown"

        let totalWeightOz              = intColumn(s, 3)
        let totalWeightPoundsHundredth = intColumn(s, 4)
        let totalWeightHundredthKg     = intColumn(s, 5)

        let totalLengthQuarters        = intColumn(s, 6)
        let totalLengthCm              = intColumn(s, 7)

        let catchType   = stringColumn(s, 8)
        let markerType  = stringColumn(s, 9)
        let clipColor   = stringColumn(s,10)

        let latitudeE7  = intColumn(s,11)
        let longitudeE7 = intColumn(s,12)

        let primaryPhotoId = stringColumn(s,13)
        // created_at_sec (14) is not needed to reconstruct model; we can store it too:
        // let createdAtSec = sqlite3_column_int64(s, 14)

        return CatchItem(
            id: id,
            dateTimeSec: dateTimeSec,
            species: species,
            totalWeightOz: totalWeightOz,
            totalWeightPoundsHundredth: totalWeightPoundsHundredth,
            totalWeightHundredthKg: totalWeightHundredthKg,
            totalLengthQuarters: totalLengthQuarters,
            totalLengthCm: totalLengthCm,
            catchType: catchType,
            markerType: markerType,
            clipColor: clipColor,
            latitudeE7: latitudeE7,
            longitudeE7: longitudeE7,
            primaryPhotoId: primaryPhotoId,
            createdAtSec: sqlite3_column_int64(s, 14)
        )
    }

    // MARK: - Core utils
    func databaseURL() throws -> URL {
        let dir = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        return dir.appendingPathComponent(dbFileName)
    }

    func enableWAL() throws {
        try exec(sql: "PRAGMA journal_mode=WAL;")
        try exec(sql: "PRAGMA synchronous=NORMAL;")
        try exec(sql: "PRAGMA foreign_keys=ON;")
    }

    func exec(sql: String) throws {
        try openIfNeeded()
        try queue.sync {
            var err: UnsafeMutablePointer<Int8>? = nil
            if sqlite3_exec(db, sql, nil, nil, &err) != SQLITE_OK {
                let message = err.flatMap { String(cString: $0) } ?? "Unknown SQL error"
                sqlite3_free(err)
                throw error(message: message)
            }
        }
    }

    func getUserVersion() throws -> Int32 {
        try openIfNeeded()
        var version: Int32 = 0
        queue.sync {
            var stmt: OpaquePointer?; defer { sqlite3_finalize(stmt) }
            guard let db = db,
                  sqlite3_prepare_v2(db, "PRAGMA user_version;", -1, &stmt, nil) == SQLITE_OK
            else { return }
            if sqlite3_step(stmt) == SQLITE_ROW { version = sqlite3_column_int(stmt, 0) }
        }
        return version
    }

    func setUserVersion(_ v: Int32) throws { try exec(sql: "PRAGMA user_version = \(v);") }

    // MARK: - Binds/readers
    func bindText(_ stmt: OpaquePointer?, _ idx: Int32, _ value: String) { sqlite3_bind_text(stmt, idx, value, -1, SQLITE_TRANSIENT) }
    
    func bindTextOrNull(_ stmt: OpaquePointer?, _ idx: Int32, _ value: String?) { if let v = value { bindText(stmt, idx, v) } else { sqlite3_bind_null(stmt, idx) } }
    
    func bindInt(_ stmt: OpaquePointer?, _ idx: Int32, _ value: Int) { sqlite3_bind_int(stmt, idx, Int32(value)) }
    
    func bindIntOrNull(_ stmt: OpaquePointer?, _ idx: Int32, _ value: Int?) { if let v = value { bindInt(stmt, idx, v) } else { sqlite3_bind_null(stmt, idx) } }
    
    func bindInt64(_ stmt: OpaquePointer?, _ idx: Int32, _ value: Int64) { sqlite3_bind_int64(stmt, idx, value) }
    
    func bindInt64OrNull(_ stmt: OpaquePointer?, _ idx: Int32, _ value: Int64?) { if let v = value { bindInt64(stmt, idx, v) } else { sqlite3_bind_null(stmt, idx) } }

    func stringColumn(_ stmt: OpaquePointer?, _ idx: Int32) -> String? { guard sqlite3_column_type(stmt, idx) != SQLITE_NULL, let c = sqlite3_column_text(stmt, idx) else { return nil }; return String(cString: c) }
    
    func intColumn(_ stmt: OpaquePointer?, _ idx: Int32) -> Int? { sqlite3_column_type(stmt, idx) == SQLITE_NULL ? nil : Int(sqlite3_column_int(stmt, idx)) }
    
    func int64Column(_ stmt: OpaquePointer?, _ idx: Int32) -> Int64? { sqlite3_column_type(stmt, idx) == SQLITE_NULL ? nil : sqlite3_column_int64(stmt, idx) }

    
    func lastError() -> Error { error(code: sqlite3_errcode(db), message: String(cString: sqlite3_errmsg(db))) }
    
    func error(code: Int32 = -1, message: String) -> NSError { NSError(domain: "Database", code: Int(exactly: code) ?? -1, userInfo: [NSLocalizedDescriptionKey: message]) }
}

// MARK: - App-level integer helpers (no DB doubles needed)
extension DatabaseManager {
    
    // pounds hundredths → components
    static func poundsWholeAndHundredths(_ hundredth: Int) -> (whole: Int, hundredths: Int) {
        let whole = hundredth / 100
        let hund  = abs(hundredth % 100)
        return (whole, hund)
    }
    
    // inches quarters → components
    static func inchesWholeAndQuarters(_ quarters: Int) -> (whole: Int, quarter: Int) {
        let whole = quarters / 4
        let q     = abs(quarters % 4)
        return (whole, q)
    }
    
    // cm (tenths) → whole + tenth
    static func cmWholeAndTenth(_ tenths: Int) -> (whole: Int, tenth: Int) {
        let whole = tenths / 10
        let t     = abs(tenths % 10)
        return (whole, t)
    }

    // lat/lon e7 → Decimal string (no binary float)
    static func decimalStringFromE7(_ e7: Int) -> String {
        // Use Decimal so we avoid Double entirely for formatting
        var dec = Decimal(e7)
        var scale = Decimal(1_000_0000) // 1e7
        var result = Decimal()
        NSDecimalDivide(&result, &dec, &scale, .plain)
        return NSDecimalNumber(decimal: result).stringValue
    }
}

// MARK: - Unit helpers (forward to MeasureHelpers to avoid duplication)
extension DatabaseManager {
    
    static func totalOz(lbs: Int, oz: Int) -> Int {
        MeasureHelpers.totalOz(lbs: lbs, oz: oz)
    }
    
    static func lbsOz(fromTotalOz total: Int) -> (lbs: Int, oz: Int) {
        MeasureHelpers.lbsOz(fromTotalOz: total)
    }
    
    static func poundsHundredth(whole: Int, hundredths: Int) -> Int {
        MeasureHelpers.poundsHundredth(whole: whole, hundredths: hundredths)
    }
    
    static func kgsHundredth(whole: Int, hundredths: Int) -> Int {
        MeasureHelpers.kgsHundredth(whole: whole, hundredths: hundredths)
    }
    
    static func quartersFromInches(whole: Int, quarter: Int) -> Int {
        MeasureHelpers.quartersFromInches(whole: whole, quarter: quarter)
    }
    
    static func tenthsCm(whole: Int, tenth: Int) -> Int {
        MeasureHelpers.tenthsCm(whole: whole, tenth: tenth)
    }

    // GPS degrees to E7 (int)
    static func e7(fromDegreesWhole whole: Int, millionths: Int) -> Int {
        // Optional helper if you ever take integer degrees + 1e-6 parts
        return whole &* 1_000_0000 &+ millionths
    }
}



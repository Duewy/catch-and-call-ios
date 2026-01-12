// =============================
// File: Database/Data/PhotoData.swift
// =============================

import Foundation
import SQLite3

extension DatabaseManager {
    @discardableResult
    func insertPhoto(_ p: PhotoRecord) throws -> String {
        try openIfNeeded()
        let sql = """
        INSERT INTO photos (
            photo_id, catch_id, local_path, mime_type, width, height, file_size, taken_at_sec, created_at_sec
        ) VALUES (?,?,?,?,?,?,?,?,?);
        """

        var thrown: Error?
        queue.sync {
            var stmt: OpaquePointer?
            defer { sqlite3_finalize(stmt) }

            guard let db = db,
                  sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK
            else { thrown = lastError(); return }

            bindText(stmt, 1, p.id)
            if let cid = p.catchId { bindInt64(stmt, 2, cid) } else { sqlite3_bind_null(stmt, 2) }
            bindText(stmt, 3, p.localPath)
            bindTextOrNull(stmt, 4, p.mimeType)
            if let w = p.width      { bindInt(stmt, 5, w) } else { sqlite3_bind_null(stmt, 5) }
            if let h = p.height     { bindInt(stmt, 6, h) } else { sqlite3_bind_null(stmt, 6) }
            if let fs = p.fileSize  { bindInt64(stmt, 7, fs) } else { sqlite3_bind_null(stmt, 7) }

            if let t = p.takenAt {
                let tSec = Int64(t.timeIntervalSince1970)
                bindInt64(stmt, 8, tSec)
            } else {
                sqlite3_bind_null(stmt, 8)
            }

            let nowSec = Int64(Date().timeIntervalSince1970)
            bindInt64(stmt, 9, nowSec)

            if sqlite3_step(stmt) != SQLITE_DONE { thrown = lastError() }
        }

        if let e = thrown { throw e }
        return p.id
    }

    func getPhotos(forCatch catchId: Int64) throws -> [PhotoRecord] {
        try openIfNeeded()
        let sql = "SELECT * FROM photos WHERE catch_id=? ORDER BY created_at_sec ASC;"

        var rows: [PhotoRecord] = []
        var thrown: Error?

        queue.sync {
            var stmt: OpaquePointer?
            defer { sqlite3_finalize(stmt) }

            guard let db = db,
                  sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK
            else { thrown = lastError(); return }

            bindInt64(stmt, 1, catchId)

            while sqlite3_step(stmt) == SQLITE_ROW, let s = stmt {
                rows.append(parsePhoto(s))
            }
        }

        if let e = thrown { throw e }
        return rows
    }
    
    
    
    // MARK: - Parsing (photos)
    func parsePhoto(_ s: OpaquePointer) -> PhotoRecord {
        // Column order matches CREATE TABLE photos:
        // 0 photo_id TEXT
        // 1 catch_id INTEGER
        // 2 local_path TEXT
        // 3 mime_type TEXT
        // 4 width INTEGER
        // 5 height INTEGER
        // 6 file_size INTEGER
        // 7 taken_at_sec INTEGER
        // 8 created_at_sec INTEGER

        let photoId   = stringColumn(s, 0) ?? UUID().uuidString
        let catchId   = int64Column(s, 1)
        let localPath = stringColumn(s, 2) ?? ""
        let mimeType  = stringColumn(s, 3)
        let width     = intColumn(s, 4)
        let height    = intColumn(s, 5)
        let fileSize  = int64Column(s, 6)
        let takenAt: Date? = {
            if let sec = int64Column(s, 7) { return Date(timeIntervalSince1970: TimeInterval(sec)) }
            return nil
        }()

        return PhotoRecord(
            id: photoId,
            catchId: catchId,
            localPath: localPath,
            mimeType: mimeType,
            width: width,
            height: height,
            fileSize: fileSize,
            takenAt: takenAt
        )
    }

    
}

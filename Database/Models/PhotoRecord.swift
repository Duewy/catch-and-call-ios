//
//  PhotoRecord.swift
//  CatchAndCall
//
//  Created by Dwayne Brame on 2025-10-28.
//

// =============================
// File: Database/Models/PhotoRecord.swift
// =============================

import Foundation

public struct PhotoRecord: Identifiable {
    public var id: String
    public var catchId: Int64?
    public var localPath: String
    public var mimeType: String?
    public var width: Int?
    public var height: Int?
    public var fileSize: Int64?
    public var takenAt: Date?

    public init(
        id: String = UUID().uuidString,
        catchId: Int64? = nil,
        localPath: String,
        mimeType: String? = nil,
        width: Int? = nil,
        height: Int? = nil,
        fileSize: Int64? = nil,
        takenAt: Date? = nil
    ) {
        self.id = id
        self.catchId = catchId
        self.localPath = localPath
        self.mimeType = mimeType
        self.width = width
        self.height = height
        self.fileSize = fileSize
        self.takenAt = takenAt
    }
}

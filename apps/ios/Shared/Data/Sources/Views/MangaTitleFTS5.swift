//
//  MangaTitleFTS5.swift
//  Data
//
//  Created by Angelo Carasig on 11/10/2025.
//

import GRDB

/// FTS5 virtual table for full-text search on manga titles.
/// Automatically synchronized with the manga table.
internal struct MangaTitleFTS5: ViewRecord {
    let rowid: Int64
    let title: String
}

// MARK: - ViewRecord

extension MangaTitleFTS5 {
    static var databaseTableName: String {
        "manga_title_fts"
    }
    
    static let dependsOn: [any DatabaseRecord.Type] = [
        MangaRecord.self
    ]
    
    static let introducedIn = DatabaseVersion(1, 0, 0)
    
    static var viewDefinition: SQLRequest<MangaTitleFTS5> {
        // FTS5 virtual tables don't use SQLRequest
        // They're created differently via createView
        SQLRequest(sql: "SELECT rowid, title FROM \(databaseTableName)")
    }
    
    static func createView(db: Database) throws {
        try db.create(virtualTable: databaseTableName, options: [.ifNotExists], using: FTS5()) { t in
            // unicode tokenizer with diacritic removal for better matching
            // e.g., "café" matches "cafe"
            t.tokenizer = .unicode61(diacritics: .remove)
            
            // automatically sync with manga table
            // inserts/updates/deletes in manga table will update this FTS table
            t.synchronize(withTable: MangaRecord.databaseTableName)
            
            // only index the title column for searching
            t.column(MangaRecord.Columns.title.name)
        }
    }
    
    static func rebuild(db: Database) throws {
        // FTS5 tables need special rebuild command
        try db.execute(sql: "INSERT INTO \(databaseTableName)(\(databaseTableName)) VALUES('rebuild')")
    }
    
    static func migrate(with migrator: inout GRDB.DatabaseMigrator, from version: DatabaseVersion) throws {
        switch version {
        case ..<DatabaseVersion(1, 0, 0):
            // virtual table created via createView, not migrations
            break
        default:
            break
        }
    }
}

//
//  AlternativeTitleRecord.swift
//  Data
//
//  Created by Angelo Carasig on 28/9/2025.
//

import Foundation
import GRDB
import Tagged

internal struct AlternativeTitleRecord: Codable, DatabaseRecord {
    typealias ID = Tagged<Self, Int64>
    private(set) var id: ID?
    
    var mangaId: MangaRecord.ID
    var title: String
}

// MARK: - DatabaseRecord

extension AlternativeTitleRecord {
    static var databaseTableName: String {
        "alternative_title"
    }
    
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let mangaId = Column(CodingKeys.mangaId)
        static let title = Column(CodingKeys.title)
    }
    
    static func createTable(db: Database) throws {
        try db.create(table: databaseTableName, options: [.ifNotExists]) { t in
            t.autoIncrementedPrimaryKey(Columns.id.name)
            
            t.belongsTo(MangaRecord.databaseTableName, onDelete: .cascade)
            
            t.column(Columns.title.name, .text)
                .notNull()
                .collate(.localizedCaseInsensitiveCompare)
        }
    }
    
    static func migrate(with migrator: inout GRDB.DatabaseMigrator, from version: DatabaseVersion) throws {
        switch version {
        case ..<DatabaseVersion(1, 0, 0):
            let migrationName = DatabaseVersion(1, 0, 0).createMigrationName(description: "alternative title initial indexes")
            migrator.registerMigration(migrationName) { db in
                try db.create(index: "idx_alternative_title_mangaId", on: databaseTableName, columns: [Columns.mangaId.name])
            }
        default:
            break
        }
    }
    
    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = ID(rawValue: inserted.rowID)
    }
}

// MARK: - Associations

extension AlternativeTitleRecord {
    static let manga = belongsTo(MangaRecord.self)
    
    var manga: QueryInterfaceRequest<MangaRecord> {
        request(for: AlternativeTitleRecord.manga)
    }
}

//
//  MangaTagRecord.swift
//  Data
//
//  Created by Angelo Carasig on 28/9/2025.
//

import GRDB
import Tagged

internal struct MangaTagRecord: Codable, DatabaseRecord {
    typealias ID = Tagged<Self, Int64>
    private(set) var id: ID?
    
    var mangaId: MangaRecord.ID
    var tagId: TagRecord.ID
}

// MARK: - DatabaseRecord

extension MangaTagRecord {
    static var databaseTableName: String {
        "manga_tag"
    }
    
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let mangaId = Column(CodingKeys.mangaId)
        static let tagId = Column(CodingKeys.tagId)
    }
    
    static func createTable(db: Database) throws {
        try db.create(table: databaseTableName, options: [.ifNotExists]) { t in
            t.autoIncrementedPrimaryKey(Columns.id.name)
            
            t.belongsTo(MangaRecord.databaseTableName, onDelete: .cascade)
            t.belongsTo(TagRecord.databaseTableName, onDelete: .cascade)
            
            t.uniqueKey([Columns.mangaId.name, Columns.tagId.name])
        }
    }
    
    static func migrate(with migrator: inout GRDB.DatabaseMigrator, from version: DatabaseVersion) throws {
        switch version {
        case ..<DatabaseVersion(1, 0, 0):
            // unique key already creates composite index
            break
        default:
            break
        }
    }
    
    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = ID(rawValue: inserted.rowID)
    }
}

// MARK: - Associations

extension MangaTagRecord {
    static let manga = belongsTo(MangaRecord.self)
    static let tag = belongsTo(TagRecord.self)
}

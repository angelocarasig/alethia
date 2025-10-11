//
//  MangaCollectionRecord.swift
//  Data
//
//  Created by Angelo Carasig on 28/9/2025.
//

import Foundation
import GRDB
import Tagged

internal struct MangaCollectionRecord: Codable, DatabaseRecord {
    typealias ID = Tagged<Self, Int64>
    private(set) var id: ID?
    
    var mangaId: MangaRecord.ID
    var collectionId: CollectionRecord.ID
    var order: Int = 0
    var addedAt: Date = .now
}

// MARK: - DatabaseRecord

extension MangaCollectionRecord {
    static var databaseTableName: String {
        "manga_collection"
    }
    
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let mangaId = Column(CodingKeys.mangaId)
        static let collectionId = Column(CodingKeys.collectionId)
        static let order = Column(CodingKeys.order)
        static let addedAt = Column(CodingKeys.addedAt)
    }
    
    static func createTable(db: Database) throws {
        try db.create(table: databaseTableName, options: [.ifNotExists]) { t in
            t.autoIncrementedPrimaryKey(Columns.id.name)
            
            t.belongsTo(MangaRecord.databaseTableName, onDelete: .cascade)
            t.belongsTo(CollectionRecord.databaseTableName, onDelete: .cascade)
            
            t.column(Columns.order.name, .integer).notNull()
            t.column(Columns.addedAt.name, .datetime).notNull()
            
            t.uniqueKey([Columns.mangaId.name, Columns.collectionId.name])
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

extension MangaCollectionRecord {
    static let manga = belongsTo(MangaRecord.self)
    static let collection = belongsTo(CollectionRecord.self)
}

//
//  CollectionRecord.swift
//  Data
//
//  Created by Angelo Carasig on 28/9/2025.
//

import Foundation
import GRDB
import Tagged

internal struct CollectionRecord: Codable, DatabaseRecord {
    typealias ID = Tagged<Self, Int64>
    private(set) var id: ID?
    
    var name: String
    var description: String?
    var isPrivate: Bool = false
    var createdAt: Date = .now
    var updatedAt: Date = .now
}

// MARK: - DatabaseRecord

extension CollectionRecord {
    static var databaseTableName: String {
        "collection"
    }
    
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let name = Column(CodingKeys.name)
        static let description = Column(CodingKeys.description)
        static let isPrivate = Column(CodingKeys.isPrivate)
        static let createdAt = Column(CodingKeys.createdAt)
        static let updatedAt = Column(CodingKeys.updatedAt)
    }
    
    static func createTable(db: Database) throws {
        try db.create(table: databaseTableName, options: [.ifNotExists]) { t in
            t.autoIncrementedPrimaryKey(Columns.id.name)
            
            t.column(Columns.name.name, .text)
                .notNull()
                .collate(.localizedCaseInsensitiveCompare)
            
            t.column(Columns.description.name, .text)
            t.column(Columns.isPrivate.name, .boolean).notNull().defaults(to: false)
            t.column(Columns.createdAt.name, .datetime).notNull()
            t.column(Columns.updatedAt.name, .datetime).notNull()
        }
    }
    
    static func migrate(with migrator: inout GRDB.DatabaseMigrator, from version: DatabaseVersion) throws {
        switch version {
        case ..<DatabaseVersion(1, 0, 0):
            // no additional indexes needed in initial schema
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

extension CollectionRecord {
    static let mangaCollections = hasMany(MangaCollectionRecord.self)
    
    static let manga = hasMany(
        MangaRecord.self,
        through: mangaCollections,
        using: MangaCollectionRecord.manga
    ).order(MangaCollectionRecord.Columns.order)
    
    var manga: QueryInterfaceRequest<MangaRecord> {
        request(for: CollectionRecord.manga)
    }
}

//
//  MangaAuthorRecord.swift
//  Data
//
//  Created by Angelo Carasig on 28/9/2025.
//

import GRDB
import Tagged

internal struct MangaAuthorRecord: Codable, DatabaseRecord {
    typealias ID = Tagged<Self, Int64>
    private(set) var id: ID?
    
    var mangaId: MangaRecord.ID
    var authorId: AuthorRecord.ID
}

// MARK: - DatabaseRecord

extension MangaAuthorRecord {
    static var databaseTableName: String {
        "manga_author"
    }
    
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let mangaId = Column(CodingKeys.mangaId)
        static let authorId = Column(CodingKeys.authorId)
    }
    
    static func createTable(db: Database) throws {
        try db.create(table: databaseTableName, options: [.ifNotExists]) { t in
            t.autoIncrementedPrimaryKey(Columns.id.name)
            
            t.belongsTo(MangaRecord.databaseTableName, onDelete: .cascade)
            t.belongsTo(AuthorRecord.databaseTableName, onDelete: .cascade)
            
            t.uniqueKey([Columns.mangaId.name, Columns.authorId.name])
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

extension MangaAuthorRecord {
    static let manga = belongsTo(MangaRecord.self)
    static let author = belongsTo(AuthorRecord.self)
}

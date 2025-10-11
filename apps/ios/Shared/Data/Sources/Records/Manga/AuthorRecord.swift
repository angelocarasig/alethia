//
//  AuthorRecord.swift
//  Data
//
//  Created by Angelo Carasig on 28/9/2025.
//

import Foundation
import GRDB
import Tagged
import Domain

internal struct AuthorRecord: Codable, DatabaseRecord {
    typealias ID = Tagged<Self, Int64>
    private(set) var id: ID?
    
    var name: String
}

// MARK: - DatabaseRecord

extension AuthorRecord {
    static var databaseTableName: String {
        "author"
    }
    
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let name = Column(CodingKeys.name)
    }
    
    static func createTable(db: Database) throws {
        try db.create(table: databaseTableName, options: [.ifNotExists]) { t in
            t.autoIncrementedPrimaryKey(Columns.id.name)
            
            t.column(Columns.name.name, .text)
                .notNull()
                .unique()
                .collate(.localizedCaseInsensitiveCompare)
        }
    }
    
    static func migrate(with migrator: inout GRDB.DatabaseMigrator, from version: DatabaseVersion) throws {
        switch version {
        case ..<DatabaseVersion(1, 0, 0):
            // unique constraint on name already creates an index
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

extension AuthorRecord {
    static let mangaAuthors = hasMany(MangaAuthorRecord.self)
    
    static let manga = hasMany(
        MangaRecord.self,
        through: mangaAuthors,
        using: MangaAuthorRecord.manga
    )
    
    var manga: QueryInterfaceRequest<MangaRecord> {
        request(for: AuthorRecord.manga)
    }
}

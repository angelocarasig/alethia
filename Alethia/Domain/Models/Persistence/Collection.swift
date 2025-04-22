//
//  Collection.swift
//  Alethia
//
//  Created by Angelo Carasig on 23/4/2025.
//

import Foundation
import GRDB

struct Collection: Codable, Identifiable, Equatable {
    var id: Int64?
    
    var name: String
}

extension Collection {
    static let mangaCollection = hasMany(MangaCollection.self)
    static let manga = hasMany(Manga.self, through: mangaCollection, using: MangaCollection.manga)
}

extension Collection: TableRecord {
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let name = Column(CodingKeys.name)
    }
}

extension Collection: FetchableRecord, PersistableRecord {}

extension Collection: DatabaseUnique {
    static func uniqueFilter(for instance: Collection) -> QueryInterfaceRequest<Collection> {
        filter(Columns.name == instance.name)
    }
}

extension Collection: DatabaseModel {
    static var version: Version = Version(1, 0, 0)
    
    static func createTable(db: Database) throws {
        try db.create(table: databaseTableName, body: { t in
            t.autoIncrementedPrimaryKey(Columns.id.name)
            
            t.column(Columns.name.name, .text)
                .notNull()
                .unique()
                .collate(.nocase)
                .indexed()
        })
    }
    
    static func migrate(with migrator: inout GRDB.DatabaseMigrator, from version: Version) throws {
        // Nothing for now
    }
}

//
//  MangaCollection.swift
//  Alethia
//
//  Created by Angelo Carasig on 23/4/2025.
//

import Foundation
import GRDB

struct MangaCollection: Codable {
    var mangaId: Int64
    var collectionId: Int64
}

extension MangaCollection {
    static let manga = belongsTo(Manga.self)
    static let collection = belongsTo(Collection.self)
}

extension MangaCollection: TableRecord {
    enum Columns {
        static let mangaId = Column(CodingKeys.mangaId)
        static let collectionId = Column(CodingKeys.collectionId)
    }
}

extension MangaCollection: FetchableRecord, PersistableRecord {}

extension MangaCollection: DatabaseModel {
    static var version = Version(1, 0, 0)
    
    static func createTable(db: Database) throws {
        try db.create(table: databaseTableName, body: { t in
            t.column(Columns.mangaId.name, .integer)
                .notNull()
                .indexed()
                .references(Manga.databaseTableName, onDelete: .setNull)
            
            t.column(Columns.collectionId.name, .integer)
                .notNull()
                .indexed()
                .references(Collection.databaseTableName, onDelete: .cascade)
        })
    }
    
    static func migrate(with migrator: inout DatabaseMigrator, from version: Version) throws {
        
    }
}

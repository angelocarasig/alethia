//
//  MangaTag.swift
//  Alethia
//
//  Created by Angelo Carasig on 10/4/2025.
//

import Foundation
import GRDB

struct MangaTag: Codable {
    var tagId: Int64
    var mangaId: Int64
}

extension MangaTag {
    static let tag = belongsTo(Tag.self)
    static let manga = belongsTo(Manga.self)
}

extension MangaTag: TableRecord {
    enum Columns {
        static let tagId = Column(CodingKeys.tagId)
        static let mangaId = Column(CodingKeys.mangaId)
    }
}

extension MangaTag: FetchableRecord {}
extension MangaTag: PersistableRecord {}

extension MangaTag: DatabaseModel {
    static var version: Version = Version(1, 0, 0)
    
    static func createTable(db: Database) throws {
        try db.create(table: databaseTableName, body: { t in
            t.column(Columns.tagId.name, .integer)
                .notNull()
                .indexed()
                .references(Tag.databaseTableName, onDelete: .cascade)
            
            t.column(Columns.mangaId.name, .integer)
                .notNull()
                .indexed()
                .references(Manga.databaseTableName, onDelete: .cascade)
            
            t.primaryKey([Columns.tagId.name, Columns.mangaId.name])
        })
    }
    
    static func migrate(with migrator: inout DatabaseMigrator, from version: Version) throws {
        // Nothing for now
    }
}

//
//  MangaAuthor.swift
//  Alethia
//
//  Created by Angelo Carasig on 10/4/2025.
//

import Foundation
import GRDB

struct MangaAuthor: Codable {
    var authorId: Int64
    var mangaId: Int64
}

extension MangaAuthor {
    static let author = belongsTo(Author.self)
    static let manga = belongsTo(Manga.self)
}

extension MangaAuthor: TableRecord {
    enum Columns {
        static let authorId = Column(CodingKeys.authorId)
        static let mangaId = Column(CodingKeys.mangaId)
    }
}

extension MangaAuthor: FetchableRecord {}
extension MangaAuthor: PersistableRecord {}

extension MangaAuthor: DatabaseModel {
    static func createTable(db: Database) throws {
        try db.create(table: databaseTableName, body: { t in
            t.column(Columns.authorId.name, .integer)
                .notNull()
                .indexed()
                .references(Author.databaseTableName, onDelete: .cascade)
            
            t.column(Columns.mangaId.name, .integer)
                .notNull()
                .indexed()
                .references(Manga.databaseTableName, onDelete: .cascade)
            
            t.primaryKey([Columns.authorId.name, Columns.mangaId.name])
        })
    }
    
    static func migrate(with migrator: inout DatabaseMigrator, from version: Version) throws {
        // Nothing for now
    }
}

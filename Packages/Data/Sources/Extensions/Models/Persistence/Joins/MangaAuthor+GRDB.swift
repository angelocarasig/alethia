//
//  MangaAuthor+GRDB.swift
//  Data
//
//  Created by Angelo Carasig on 15/6/2025.
//

import GRDB
import Domain


private typealias MangaAuthor = Domain.Models.Persistence.MangaAuthor
private typealias Manga = Domain.Models.Persistence.Manga
private typealias Author = Domain.Models.Persistence.Author

// MARK: - Database Conformance
extension MangaAuthor: @retroactive FetchableRecord {}

extension MangaAuthor: @retroactive PersistableRecord {}

extension MangaAuthor: @retroactive TableRecord {
    public enum Columns {
        public static let mangaId = Column(CodingKeys.mangaId)
        public static let authorId = Column(CodingKeys.authorId)
    }
}

// MARK: - Database Relations
extension MangaAuthor {
    // belongs to a particular manga
    static let manga = belongsTo(Domain.Models.Persistence.Manga.self)
    
    // belongs to a particular author
    static let author = belongsTo(Domain.Models.Persistence.Author.self)
}

// MARK: - Database Table Definition + Migrations
extension MangaAuthor: @retroactive Data.Infrastructure.DatabaseMigratable {
    public static func createTable(db: Database) throws {
        try db.create(table: databaseTableName, body: { t in
            // id - composite primary based on manga/author ids
            t.primaryKey([Columns.mangaId.name, Columns.authorId.name])
            
            t.column(Columns.mangaId.name, .integer)
                .notNull()
                .references(Domain.Models.Persistence.Manga.databaseTableName, onDelete: .cascade)
            
            t.column(Columns.authorId.name, .integer)
                .notNull()
                .references(Domain.Models.Persistence.Author.databaseTableName, onDelete: .cascade)
        })
    }
    
    public static func migrate(with migrator: inout DatabaseMigrator, from version: Data.Infrastructure.Version) throws {
        // nothing for now
    }
}

//
//  MangaTag+GRDB.swift
//  Data
//
//  Created by Angelo Carasig on 15/6/2025.
//

import GRDB
import Domain


private typealias MangaTag = Domain.Models.Persistence.MangaTag
private typealias Manga = Domain.Models.Persistence.Manga
private typealias Tag = Domain.Models.Persistence.Tag

// MARK: - Database Conformance
extension MangaTag: @retroactive FetchableRecord {}

extension MangaTag: @retroactive PersistableRecord {}

extension MangaTag: @retroactive TableRecord {
    public enum Columns {
        public static let mangaId = Column(CodingKeys.mangaId)
        public static let tagId = Column(CodingKeys.tagId)
    }
}

// MARK: - Database Relations
extension MangaTag {
    // belongs to a particular manga
    public static let manga = belongsTo(Domain.Models.Persistence.Manga.self)
    
    // belongs to a particular tag
    public static let tag = belongsTo(Domain.Models.Persistence.Tag.self)
}

// MARK: - Database Table Definition + Migrations
extension MangaTag: @retroactive Data.Infrastructure.DatabaseMigratable {
    public static func createTable(db: Database) throws {
        try db.create(table: databaseTableName, body: { t in
            // id - composite primary based on manga/tag ids
            t.primaryKey([Columns.mangaId.name, Columns.tagId.name], onConflict: .ignore)
            
            t.column(Columns.mangaId.name, .integer)
                .notNull()
                .references(Domain.Models.Persistence.Manga.databaseTableName, onDelete: .cascade)
            
            t.column(Columns.tagId.name, .integer)
                .notNull()
                .references(Domain.Models.Persistence.Tag.databaseTableName, onDelete: .cascade)
        })
    }
    
    public static func migrate(with migrator: inout DatabaseMigrator, from version: Data.Infrastructure.Version) throws {
        // nothing for now
    }
}

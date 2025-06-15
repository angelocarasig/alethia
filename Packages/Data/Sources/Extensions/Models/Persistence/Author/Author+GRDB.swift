//
//  Author+GRDB.swift
//  Data
//
//  Created by Angelo Carasig on 15/6/2025.
//

import Domain
import GRDB

private typealias Author = Domain.Models.Persistence.Author
private typealias MangaAuthor = Domain.Models.Persistence.MangaAuthor
private typealias Manga = Domain.Models.Persistence.Manga

// MARK: - Database Conformance
extension Author: @retroactive FetchableRecord {}

extension Author: @retroactive PersistableRecord {}

extension Author: @retroactive TableRecord {
    public enum Columns {
        public static let id = Column(CodingKeys.id)
        public static let name = Column(CodingKeys.name)
    }
}

extension Author: @retroactive Data.Infrastructure.DatabaseUnique {
    public static func uniqueFilter(for instance: Domain.Models.Persistence.Author) -> QueryInterfaceRequest<Domain.Models.Persistence.Author> {
        filter(Columns.name == instance.name)
    }
}

// MARK: - Database Relations
extension Author {
    // has many manga <-> manga has many authors
    static let mangaAuthors = hasMany(Domain.Models.Persistence.MangaAuthor.self)
    static let manga = hasMany(Domain.Models.Persistence.Manga.self, through: mangaAuthors, using: Domain.Models.Persistence.MangaAuthor.manga)
}

// MARK: - Database Table Definition + Migrations
extension Author: @retroactive Data.Infrastructure.DatabaseMigratable {
    public static func createTable(db: Database) throws {
        try db.create(table: databaseTableName, body: { t in
            // ids
            t.autoIncrementedPrimaryKey(Columns.id.name)
            
            // properties
            t.column(Columns.name.name, .text)
                .notNull()
                .unique()
                .collate(.nocase)
        })
    }
    
    public static func migrate(with migrator: inout DatabaseMigrator, from version: Data.Infrastructure.Version) throws {
        // nothing for now
    }
}

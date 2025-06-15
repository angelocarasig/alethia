//
//  Tag+GRDB.swift
//  Data
//
//  Created by Angelo Carasig on 15/6/2025.
//

import Domain
import GRDB


private typealias Tag = Domain.Models.Persistence.Tag
private typealias MangaTag = Domain.Models.Persistence.MangaTag
private typealias Manga = Domain.Models.Persistence.Manga

// MARK: - Database Conformance
extension Tag: @retroactive FetchableRecord {}

extension Tag: @retroactive PersistableRecord {}

extension Tag: @retroactive TableRecord {
    public enum Columns {
        public static let id = Column(CodingKeys.id)
        public static let name = Column(CodingKeys.name)
    }
}

extension Tag: @retroactive Data.Infrastructure.DatabaseUnique {
    public static func uniqueFilter(for instance: Domain.Models.Persistence.Tag) -> QueryInterfaceRequest<Domain.Models.Persistence.Tag> {
        filter(Columns.name == instance.name)
    }
}

// MARK: - Database Relations
extension Tag {
    // has many manga <-> manga has many tags
    public static let mangaTags = hasMany(Domain.Models.Persistence.MangaTag.self)
    public static let manga = hasMany(Domain.Models.Persistence.Manga.self, through: mangaTags, using: Domain.Models.Persistence.MangaTag.manga)
}

// MARK: - Database Table Definition + Migrations
extension Tag: @retroactive Data.Infrastructure.DatabaseMigratable {
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

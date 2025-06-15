//
//  Collection+GRDB.swift
//  Data
//
//  Created by Angelo Carasig on 15/6/2025.
//

import Foundation
import Domain
import GRDB


private typealias Collection = Domain.Models.Persistence.Collection
private typealias MangaCollection = Domain.Models.Persistence.MangaCollection
private typealias Manga = Domain.Models.Persistence.Manga

// MARK: - Database Conformance
extension Collection: @retroactive FetchableRecord {}

extension Collection: @retroactive PersistableRecord {}

extension Collection: @retroactive TableRecord {
    public enum Columns {
        public static let id = Column(CodingKeys.id)
        public static let name = Column(CodingKeys.name)
        public static let color = Column(CodingKeys.color)
        public static let icon = Column(CodingKeys.icon)
        public static let ordering = Column(CodingKeys.ordering)
    }
}

extension Collection: @retroactive Data.Infrastructure.DatabaseUnique {
    /// when performing a findOrCreate, uses this to determine whether to find/create the collection
    public static func uniqueFilter(for instance: Domain.Models.Persistence.Collection) -> QueryInterfaceRequest<Domain.Models.Persistence.Collection> {
        filter(Columns.name == instance.name)
    }
}

// MARK: - Database Relations
extension Collection {
    // has many manga <-> manga has many collections
    public static let mangaCollections = hasMany(Domain.Models.Persistence.MangaCollection.self)
    public static let manga = hasMany(Domain.Models.Persistence.Manga.self, through: mangaCollections, using: Domain.Models.Persistence.MangaCollection.manga)
}

// MARK: - Database Table Definition + Migrations
extension Collection: @retroactive Data.Infrastructure.DatabaseMigratable {
    public static func createTable(db: Database) throws {
        try db.create(table: databaseTableName, body: { t in
            // ids
            t.autoIncrementedPrimaryKey(Columns.id.name)
            
            // properties
            t.column(Columns.name.name, .text)
                .notNull()
                .unique()
                .collate(.nocase)
                .check { length($0) >= Collection.minimumNameLength && length($0) <= Collection.maximumNameLength }
            
            t.column(Columns.color.name, .text)
                .notNull()
                .defaults(to: "#007AFF") // iOS blue
                .check(sql: "color GLOB '#[0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f]'")
            
            t.column(Columns.icon.name, .text)
                .notNull()
                .defaults(to: "square.inset.filled")
                .check { length($0) > 0 }
            
            // control
            t.column(Columns.ordering.name, .integer)
                .notNull()
                .unique()
                .defaults(to: 0)
        })
    }
    
    public static func migrate(with migrator: inout DatabaseMigrator, from version: Data.Infrastructure.Version) throws {
        // nothing for now
    }
}

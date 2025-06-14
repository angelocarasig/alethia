//
//  Tag.swift
//  Domain
//
//  Created by Angelo Carasig on 14/6/2025.
//
import GRDB

internal typealias Tag = Domain.Models.Persistence.Tag

public extension Domain.Models.Persistence {
    /// represents a tag for a manga
    struct Tag: Identifiable, Codable {
        // MARK: - Properties
        
        /// unique database identifier
        public var id: Int64?
        
        /// name of the tag
        public var name: String
        
        init(
            id: Int64? = nil,
            name: String
        ) {
            self.id = id
            self.name = name
        }
    }
}

// MARK: - Database Conformance
extension Tag: FetchableRecord, PersistableRecord {}

extension Tag: TableRecord {
    public enum Columns {
        public static let id = Column(CodingKeys.id)
        public static let name = Column(CodingKeys.name)
    }
}

extension Tag: Domain.Models.Database.DatabaseUnique {
    public static func uniqueFilter(for instance: Domain.Models.Persistence.Tag) -> QueryInterfaceRequest<Domain.Models.Persistence.Tag> {
        filter(Columns.name == instance.name)
    }
}

// MARK: - Database Relations
extension Tag {
    // has many manga <-> manga has many tags
    static let mangaTags = hasMany(Domain.Models.Persistence.MangaTag.self)
    static let manga = hasMany(Domain.Models.Persistence.Manga.self, through: mangaTags, using: Domain.Models.Persistence.MangaTag.manga)
}

// MARK: - Database Table Definition + Migrations
extension Tag: Domain.Models.Database.DatabaseMigratable {
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
    
    public static func migrate(with migrator: inout DatabaseMigrator, from version: Domain.Models.Database.Version) throws {
        // nothing for now
    }
}

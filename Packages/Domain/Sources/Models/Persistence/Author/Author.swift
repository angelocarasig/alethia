//
//  Author.swift
//  Domain
//
//  Created by Angelo Carasig on 14/6/2025.
//

import GRDB

internal typealias Author = Domain.Models.Persistence.Author

public extension Domain.Models.Persistence {
    /// represents an author for a given manga
    ///
    /// note that an author is not exclusive to a writer, and instead includes both writers/artists/etc.
    struct Author: Identifiable, Codable {
        // MARK: - Properties
        
        /// unique database identifier
        public var id: Int64?
        
        /// name of the author
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
extension Author: FetchableRecord, PersistableRecord {}

extension Author: TableRecord {
    public enum Columns {
        public static let id = Column(CodingKeys.id)
        public static let name = Column(CodingKeys.name)
    }
}

extension Author: DatabaseUnique {
    static func uniqueFilter(for instance: Domain.Models.Persistence.Author) -> QueryInterfaceRequest<Domain.Models.Persistence.Author> {
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
extension Author: DatabaseMigratable {
    static func createTable(db: Database) throws {
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
    
    static func migrate(with migrator: inout DatabaseMigrator, from version: Version) throws {
        // nothing for now
    }
}

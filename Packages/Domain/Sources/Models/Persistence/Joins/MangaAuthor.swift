//
//  MangaAuthor.swift
//  Domain
//
//  Created by Angelo Carasig on 14/6/2025.
//
import GRDB

internal typealias MangaAuthor = Domain.Models.Persistence.MangaAuthor

public extension Domain.Models.Persistence {
    // a manga can have many authors
    // an author can have many manga
    struct MangaAuthor: Codable {
        // MARK: - Properties
        
        /// joiner to associated manga id
        public var mangaId: Int64
        
        /// joiner to associated author id
        public var authorId: Int64
        
        init(
            mangaId: Int64,
            authorId: Int64
        ) {
            self.mangaId = mangaId
            self.authorId = authorId
        }
    }
}

// MARK: - Database Conformance
extension MangaAuthor: FetchableRecord, PersistableRecord {}

extension MangaAuthor: TableRecord {
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
extension MangaAuthor: Domain.Models.Database.DatabaseMigratable {
    public static func createTable(db: Database) throws {
        try db.create(table: databaseTableName, body: { t in
            // id - composite primary based on manga/author ids
            t.primaryKey([Columns.mangaId.name, Columns.authorId.name])
            
            t.column(Columns.mangaId.name, .integer)
                .notNull()
                .references(Manga.databaseTableName, onDelete: .cascade)
            
            t.column(Columns.authorId.name, .integer)
                .notNull()
                .references(Author.databaseTableName, onDelete: .cascade)
        })
    }
    
    public static func migrate(with migrator: inout DatabaseMigrator, from version: Domain.Models.Database.Version) throws {
        // nothing for now
    }
}

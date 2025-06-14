//
//  MangaTag.swift
//  Domain
//
//  Created by Angelo Carasig on 14/6/2025.
//
import GRDB

internal typealias MangaTag = Domain.Models.Persistence.MangaTag

public extension Domain.Models.Persistence {
    /// a manga can have many tags
    /// a tag can have many manga
    struct MangaTag: Codable {
        // MARK: - Properties
        
        /// joiner to associated manga id
        public var mangaId: Int64
        
        /// joiner to associated tag id
        public var tagId: Int64
        
        init(
            mangaId: Int64,
            tagId: Int64
        ) {
            self.mangaId = mangaId
            self.tagId = tagId
        }
    }
}

// MARK: - Database Conformance
extension MangaTag: FetchableRecord, PersistableRecord {}

extension MangaTag: TableRecord {
    public enum Columns {
        public static let mangaId = Column(CodingKeys.mangaId)
        public static let tagId = Column(CodingKeys.tagId)
    }
}

// MARK: - Database Relations
extension MangaTag {
    // belongs to a particular manga
    static let manga = belongsTo(Domain.Models.Persistence.Manga.self)
    
    // belongs to a particular tag
    static let tag = belongsTo(Domain.Models.Persistence.Tag.self)
}

// MARK: - Database Table Definition + Migrations
extension MangaTag: DatabaseMigratable {
    static func createTable(db: Database) throws {
        try db.create(table: databaseTableName, body: { t in
            // id - composite primary based on manga/tag ids
            t.primaryKey([Columns.mangaId.name, Columns.tagId.name], onConflict: .ignore)
            
            t.column(Columns.mangaId.name, .integer)
                .notNull()
                .references(Manga.databaseTableName, onDelete: .cascade)
            
            t.column(Columns.tagId.name, .integer)
                .notNull()
                .references(Tag.databaseTableName, onDelete: .cascade)
        })
    }
    
    static func migrate(with migrator: inout DatabaseMigrator, from version: Version) throws {
        // nothing for now
    }
}

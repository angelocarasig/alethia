//
//  Manga.swift
//  Alethia
//
//  Created by Angelo Carasig on 9/4/2025.
//

import Foundation
import GRDB

struct Manga: Codable, Identifiable {
    var id: Int64?
    
    var title: String
    var synopsis: String
    
    var addedAt: Date = Date()
    var updatedAt: Date = Date()
    
    var inLibrary: Bool = false
    var orientation: Orientation = .LeftToRight
    var showAllChapters: Bool = false
    var showHalfChapters: Bool = true
    
    init(title: String, synopsis: String) {
        self.title = title
        self.synopsis = synopsis
    }
}

extension Manga {
    static let titles = hasMany(Title.self)
    static let covers = hasMany(Cover.self)
    static let origins = hasMany(Origin.self)
    
    static let mangaAuthor = hasMany(MangaAuthor.self)
    static let authors = hasMany(Author.self, through: mangaAuthor, using: MangaAuthor.author)
    
    static let mangaTag = hasMany(MangaTag.self)
    static let tags = hasMany(Tag.self, through: mangaTag, using: MangaTag.tag)
}

extension Manga {
    var titles: QueryInterfaceRequest<Title> {
        request(for: Manga.titles)
    }
    
    var covers: QueryInterfaceRequest<Cover> {
        request(for: Manga.covers)
    }
    
    var origins: QueryInterfaceRequest<Origin> {
        request(for: Manga.origins)
    }
    
    var authors: QueryInterfaceRequest<Author> {
        request(for: Manga.authors)
    }
    
    var tags: QueryInterfaceRequest<Tag> {
        request(for: Manga.tags)
    }
}

extension Manga: TableRecord {
    enum Columns {
        static let id = Column(Manga.CodingKeys.id)
        static let title = Column(Manga.CodingKeys.title)
        static let synopsis = Column(Manga.CodingKeys.synopsis)
        static let addedAt = Column(Manga.CodingKeys.addedAt)
        static let updatedAt = Column(Manga.CodingKeys.updatedAt)
        static let inLibrary = Column(Manga.CodingKeys.inLibrary)
        static let orientation = Column(Manga.CodingKeys.orientation)
        static let showAllChapters = Column(Manga.CodingKeys.showAllChapters)
        static let showHalfChapters = Column(Manga.CodingKeys.showHalfChapters)
    }
}

extension Manga: FetchableRecord { }

extension Manga: PersistableRecord { }

extension Manga {
    static func new() -> Manga {
        Manga(
            title: randomString(length: 10),
            synopsis: randomString(length: 10)
        )
    }
}

extension Manga: DatabaseModel {
    static var version: Version = Version(1, 0, 0)
    
    static func createTable(db: Database) throws {
        try db.create(table: databaseTableName, body: { t in
            // Persistence
            t.autoIncrementedPrimaryKey(Columns.id.name)
            t.column(Columns.title.name, .text)
                .notNull()
                .collate(.nocase)
            t.column(Columns.synopsis.name, .text).notNull()
            t.column(Columns.addedAt.name, .datetime).notNull()
            t.column(Columns.updatedAt.name, .datetime).notNull()
            
            // Global
            t.column(Columns.inLibrary.name, .boolean).notNull()
            t.column(Columns.orientation.name, .text).notNull()
            t.column(Columns.showAllChapters.name, .boolean).notNull()
            t.column(Columns.showHalfChapters.name, .boolean).notNull()
        })
    }
    
    static func migrate(with migrator: inout DatabaseMigrator, from version: Version) throws {
        if version <= Version(1, 0, 0) {
            /// Creates view for entry 1-1 bind to manga
            migrator.registerMigration("virtual entry view") { db in
                let sql = """
                    -- Create a view named `entry`
                    CREATE VIEW entry AS
                    SELECT
                    -- Select mangaId directly from Manga table
                    m.id AS mangaId,
                    
                    -- Select the sourceId from the Origin table with the lowest priority for the given mangaId
                    -- COALESCE ensures that if there is no sourceId, NULL is returned
                    COALESCE(
                        (
                            SELECT o.sourceId
                            FROM Origin o 
                            WHERE o.mangaId = m.id
                            ORDER BY o.priority ASC  -- Sort by priority to get the one with the lowest value
                            LIMIT 1  -- Limit to the first (lowest priority) sourceId found
                        ), 
                        NULL  -- If no sourceId is found, return NULL
                    ) AS sourceId,
                    
                    -- Select the title directly from the Manga table
                    m.title AS title,
                    
                    -- Select the cover URL from the Cover table where active = 1 (only the active cover)
                    -- LIMIT ensures that we only take one cover (since a manga can have multiple covers)
                    (SELECT c.url
                     FROM Cover c 
                     WHERE c.mangaId = m.id AND c.active = 1
                     LIMIT 1) AS cover
                
                -- fetchUrl mapped on client-side ('/' resolving becomes an issue)
                
                FROM Manga m;
                """
                
                try db.execute(sql: sql)
            }
        }
    }
}

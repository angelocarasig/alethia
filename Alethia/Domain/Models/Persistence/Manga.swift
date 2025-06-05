//
//  Manga.swift
//  Alethia
//
//  Created by Angelo Carasig on 9/4/2025.
//

import Foundation
import GRDB

struct Manga: Codable, Identifiable, QueueOperationIdentifiable {
    var id: Int64?
    
    var queueOperationId: String {
        "manga-\(id ?? -1)"
    }
    
    var title: String
    var synopsis: String
    
    var addedAt: Date = Date()
    var updatedAt: Date = Date()
    var lastReadAt: Date? = nil
    
    var inLibrary: Bool = false
    var orientation: Orientation = .Default
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
    
    static let mangaCollection = hasMany(MangaCollection.self)
    static let collections = hasMany(Collection.self, through: mangaCollection, using: MangaCollection.collection)
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
    
    var collections: QueryInterfaceRequest<Collection> {
        request(for: Manga.collections)
    }
}

extension Manga: TableRecord {
    enum Columns {
        static let id = Column(Manga.CodingKeys.id)
        static let title = Column(Manga.CodingKeys.title)
        static let synopsis = Column(Manga.CodingKeys.synopsis)
        static let addedAt = Column(Manga.CodingKeys.addedAt)
        static let updatedAt = Column(Manga.CodingKeys.updatedAt)
        static let lastReadAt = Column(Manga.CodingKeys.lastReadAt)
        static let inLibrary = Column(Manga.CodingKeys.inLibrary)
        static let orientation = Column(Manga.CodingKeys.orientation)
        static let showAllChapters = Column(Manga.CodingKeys.showAllChapters)
        static let showHalfChapters = Column(Manga.CodingKeys.showHalfChapters)
    }
}

extension Manga: FetchableRecord { }

extension Manga: PersistableRecord { }

extension Manga: DatabaseModel {
    static var version: Version = Version(1, 0, 3)
    
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
        if version < Version(1, 0, 1) {
            migrator.registerMigration("update manga updatedAt from chapters") { db in
                // Get all manga IDs
                let allMangaIds = try Int64.fetchAll(db, sql: "SELECT id FROM manga")
                
                for mangaId in allMangaIds {
                    let sql = """
                        UPDATE manga
                        SET updatedAt = COALESCE(
                            (SELECT MAX(c.date)
                             FROM chapter c
                             JOIN origin o ON c.originId = o.id
                             WHERE o.mangaId = ?),
                            updatedAt
                        )
                        WHERE id = ?
                    """
                    
                    try db.execute(sql: sql, arguments: [mangaId, mangaId])  // Use mangaId, not id
                }
            }
        }
        
        if version < Version(1, 0, 3) {
            migrator.registerMigration("add lastReadAt to manga") { db in
                try db.alter(table: databaseTableName) { t in
                    t.add(column: Columns.lastReadAt.name, .datetime)
                }
            }
        }
    }
}

extension Manga {
    // static version would return all entries anyway
    static var entry: QueryInterfaceRequest<Entry> {
        return Entry.all()
    }
    
    var entry: QueryInterfaceRequest<Entry> {
        guard let id = id else {
            return Entry.none()
        }
        
        return Entry.filter(Entry.Columns.mangaId == id)
    }
    
    var chapters: QueryInterfaceRequest<ChapterExtended> {
        guard let id = id else {
            fatalError("Manga ID is required to fetch chapters.")
        }
        
        // Define origins subquery to get all origins for this manga
        let origins = Origin
            .filter(Origin.Columns.mangaId == id)
            .order(Origin.Columns.priority.asc)
        
        // Start with filtering chapters by origins
        var query = Chapter
            .filter(origins.select(Origin.Columns.id).contains(Chapter.Columns.originId))
        
        // If showAllChapters is true, just return all chapters sorted
        if showAllChapters {
            return query
                .order(Chapter.Columns.number.desc)
                .including(required: Chapter.scanlator)
                .including(required: Chapter.origin.including(required: Origin.source))
                .asRequest(of: ChapterExtended.self)
        }
        
        // We need to get chapter numbers first, then for each chapter number,
        // select the chapter with the lowest origin priority, then the lowest scanlator priority
        
        // This is a modification of the approach using common table expressions,
        // but implemented with subqueries since GRDB doesn't directly support CTEs in the SQL builder
        
        // First, get the best chapter for each chapter number using window functions
        let bestChapterSQL = """
        WITH RankedChapters AS (
            SELECT 
                c.id,
                c.number,
                ROW_NUMBER() OVER (
                    PARTITION BY c.number 
                    ORDER BY o.priority ASC, s.priority ASC
                ) as rank
            FROM chapter c
            JOIN origin o ON c.originId = o.id
            JOIN scanlator s ON c.scanlatorId = s.id
            WHERE o.mangaId = ?
        )
        SELECT id FROM RankedChapters WHERE rank = 1
        """
        
        // Filter to only include chapters that are the best for their number
        query = query.filter(sql: "Chapter.id IN (\(bestChapterSQL))", arguments: [id])
        
        // If showHalfChapters is false, filter out non-integer chapter numbers
        if !showHalfChapters {
            query = query.filter(sql: "CAST(Chapter.number AS INTEGER) = Chapter.number")
        }
        
        // Return the filtered chapters with required associations
        return query
            .order(Chapter.Columns.number.desc)
            .including(required: Chapter.scanlator)
            .including(required: Chapter.origin.including(optional: Origin.source)) // optional for detached sources
            .asRequest(of: ChapterExtended.self)
    }
}

extension Manga {
    var originsExtended: QueryInterfaceRequest<OriginExtended> {
        guard let id = id else {
            fatalError("Manga ID is required to fetch extended origins.")
        }
        
        let chapterCountColumn = SQL("""
            (SELECT COUNT(*) FROM chapter WHERE chapter.originId = origin.id)
        """).forKey("chapterCount")
        
        let hostNameColumn = SQL("""
            COALESCE((SELECT host.name FROM host WHERE host.id = source.hostId), 'Unknown Host')
        """).forKey("hostName")
        
        let hostAuthorColumn = SQL("""
            COALESCE((SELECT host.author FROM host WHERE host.id = source.hostId), 'Unknown Author')
        """).forKey("hostAuthor")
        
        return Origin
            .filter(Origin.Columns.mangaId == id)
            .including(optional: Origin.source)
            .annotated(with: chapterCountColumn)
            .annotated(with: hostNameColumn)
            .annotated(with: hostAuthorColumn)
            .order(Origin.Columns.priority.asc)
            .asRequest(of: OriginExtended.self)
    }
}

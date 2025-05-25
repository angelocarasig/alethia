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
        static let inLibrary = Column(Manga.CodingKeys.inLibrary)
        static let orientation = Column(Manga.CodingKeys.orientation)
        static let showAllChapters = Column(Manga.CodingKeys.showAllChapters)
        static let showHalfChapters = Column(Manga.CodingKeys.showHalfChapters)
    }
}

extension Manga: FetchableRecord { }

extension Manga: PersistableRecord { }

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

extension Manga {
    static var entry: QueryInterfaceRequest<Entry> {
        // Get the source ID from the best origin
        let sourceId = SQL("""
            (SELECT o.sourceId 
             FROM origin o 
             WHERE o.mangaId = manga.id 
             ORDER BY o.priority ASC 
             LIMIT 1)
        """)
        
        // Construct the full URL by joining through source to host
        let fetchUrl = SQL("""
            (SELECT 
                RTRIM(h.baseUrl, '/') || '/' || 
                LTRIM(s.path, '/') || '/manga/' || 
                o.slug
             FROM origin o
             JOIN source s ON s.id = o.sourceId
             JOIN host h ON h.id = s.hostId
             WHERE o.mangaId = manga.id
             ORDER BY o.priority ASC
             LIMIT 1)
        """)
        
        // Get the active cover
        let cover = SQL("""
            (SELECT c.url 
             FROM cover c
             WHERE c.mangaId = manga.id
             AND c.active = 1
             ORDER BY c.id DESC
             LIMIT 1)
        """)
        
        // Calculate unread count
        let unreadCount = SQL("""
            IFNULL((SELECT COUNT(*) FROM (
                WITH RankedChapters AS (
                    SELECT 
                        c.id,
                        c.number,
                        c.progress,
                        ROW_NUMBER() OVER (
                            PARTITION BY c.number 
                            ORDER BY o.priority ASC, s.priority ASC
                        ) as rank
                    FROM chapter c
                    JOIN origin o ON c.originId = o.id
                    JOIN scanlator s ON c.scanlatorId = s.id
                    WHERE o.mangaId = manga.id
                    AND (manga.showHalfChapters = 1 OR CAST(c.number AS INTEGER) = c.number)
                )
                SELECT id FROM RankedChapters 
                WHERE rank = 1 AND (progress IS NULL OR progress < 1.0)
            )), 0)
        """)
        
        // Cast unread count as INTEGER
        let unreadCountCasted = SQL("CAST(\(unreadCount) AS INTEGER)")
        
        return Manga
            .select([
                Manga.Columns.id    .forKey("mangaId"),
                Manga.Columns.title .forKey("title"),
                sourceId            .forKey("sourceId"),
                fetchUrl            .forKey("fetchUrl"),  // Now contains the full URL
                cover               .forKey("cover"),
                unreadCountCasted   .forKey("unread")
            ])
            .asRequest(of: Entry.self)
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

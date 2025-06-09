//
//  Manga.swift
//  Alethia
//
//  Created by Angelo Carasig on 9/4/2025.
//

import Foundation
import GRDB

// MARK: - Manga Model

struct Manga: Codable, Identifiable {
    var id: Int64?
    
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

// MARK: - Static Associations

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

// MARK: - Instance Association Requests

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

// MARK: - GRDB TableRecord

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

// MARK: - GRDB Record Protocols

extension Manga: FetchableRecord { }
extension Manga: PersistableRecord { }

// MARK: - Database Migration

extension Manga: DatabaseModel {
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
            t.column(Columns.lastReadAt.name, .datetime) // Include from start
            
            // Global
            t.column(Columns.inLibrary.name, .boolean).notNull()
            t.column(Columns.orientation.name, .text).notNull()
            t.column(Columns.showAllChapters.name, .boolean).notNull()
            t.column(Columns.showHalfChapters.name, .boolean).notNull()
        })
        
        // For library filtering
        try db.create(index: "idx_manga_library_updated",
                      on: Manga.databaseTableName,
                      columns: [Columns.inLibrary.name, Columns.updatedAt.name])
        
        try db.create(index: "idx_manga_library_added",
                      on: Manga.databaseTableName,
                      columns: [Columns.inLibrary.name, Columns.addedAt.name])
        
        try db.create(index: "idx_manga_library_lastread",
                      on: Manga.databaseTableName,
                      columns: [Columns.inLibrary.name, Columns.lastReadAt.name])
    }
    
    static func migrate(with migrator: inout DatabaseMigrator, from version: Version) throws {
        // No migrations needed - current schema is baseline
    }
}

// MARK: - Entry View Requests

extension Manga {
    static var entry: QueryInterfaceRequest<Entry> {
        return Entry.all()
    }
    
    var entry: QueryInterfaceRequest<Entry> {
        guard let id = id else {
            return Entry.none()
        }
        
        return Entry.filter(Entry.Columns.mangaId == id)
    }
}

// MARK: - Query Requests

extension Manga {
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
        
        // First, get the best chapter for each chapter number using window functions
        let bestChapterSQL = """
        WITH RankedChapters AS (
            SELECT 
                c.id,
                c.number,
                ROW_NUMBER() OVER (
                    PARTITION BY c.number 
                    ORDER BY o.priority ASC, os.priority ASC
                ) as rank
            FROM chapter c
            JOIN origin o ON c.originId = o.id
            JOIN originScanlator os ON os.originId = o.id AND os.scanlatorId = c.scanlatorId
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
    
    var collectionsExtended: QueryInterfaceRequest<CollectionExtended> {
        guard let id = id else {
            fatalError("Manga ID is required to fetch collections.")
        }
        
        let itemCountColumn = SQL("""
            (SELECT COUNT(*) FROM mangaCollection mc2 WHERE mc2.collectionId = collection.id)
        """).forKey("itemCount")
        
        return Collection
            .joining(required: Collection.mangaCollection
                .filter(MangaCollection.Columns.mangaId == id)
            )
            .annotated(with: itemCountColumn)
            .order(Collection.Columns.name.asc)
            .asRequest(of: CollectionExtended.self)
    }
    
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
    
    var scanlatorsExtended: QueryInterfaceRequest<ScanlatorExtended> {
        guard let id = id else {
            fatalError("Manga ID is required to fetch extended scanlators.")
        }
        
        // Get all scanlators for this manga through OriginScanlator join table
        return OriginScanlator
            .joining(required: OriginScanlator.origin
                .filter(Origin.Columns.mangaId == id)
            )
            .joining(required: OriginScanlator.scanlator)
            .including(required: OriginScanlator.scanlator.forKey("scanlator"))
            .including(required: OriginScanlator.origin.forKey("underlyingOrigin")
                .including(optional: Origin.source.forKey("underlyingSource")
                    .including(optional: Source.host.forKey("underlyingHost"))
                )
            )
            .annotated(with: OriginScanlator.Columns.priority.forKey("priority"))
            .annotated(with: OriginScanlator.Columns.originId.forKey("originId"))
            .order(OriginScanlator.Columns.priority.asc)
            .asRequest(of: ScanlatorExtended.self)
    }
}

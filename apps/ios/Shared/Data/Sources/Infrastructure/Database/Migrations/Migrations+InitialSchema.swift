//
//  Migrations+InitialSchema.swift
//  Data
//
//  Created by Angelo Carasig on 2/10/2025.
//

import Foundation
import GRDB

extension Migrations {
    internal struct InitialSchema: Migration {
        
        static let identifier = "20251002_000000_initial_schema"
        
        static func migrate(_ db: Database) throws {
            try createHostAndSourceTables(db)
            try createMangaTables(db)
            try createChapterTables(db)
            try createSearchTables(db)
            
            // add performance indexes - ux optimized
            try createMangaChapterIndexes(db)
            try createChapterSortingIndexes(db)
            try createLibraryFilteringIndexes(db)
            try createHostFilteringIndexes(db)
            try createCoveringIndexes(db)
            try createPartialIndexes(db)
            try createExpressionIndexes(db)
        }
        
        private static func createHostAndSourceTables(_ db: Database) throws {
            // host table
            try db.create(table: "host") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("name", .text).notNull()
                t.column("author", .text).notNull()
                t.column("url", .text).notNull().unique(onConflict: .fail)
                t.column("repository", .text).notNull().unique(onConflict: .fail)
                t.column("official", .boolean).notNull().defaults(to: false)
            }
            
            // source table
            try db.create(table: "source") { t in
                t.autoIncrementedPrimaryKey("id")
                t.belongsTo("host", onDelete: .cascade)
                t.column("slug", .text).notNull()
                t.column("name", .text).notNull()
                t.column("icon", .text).notNull()
                t.column("pinned", .boolean).notNull().defaults(to: false)
                t.column("disabled", .boolean).notNull().defaults(to: false)
                t.column("authType", .text)
            }
        }
        
        private static func createMangaTables(_ db: Database) throws {
            // manga table
            try db.create(table: "manga") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("title", .text).notNull()
                t.column("synopsis", .text).notNull()
                t.column("inLibrary", .boolean).notNull().defaults(to: false)
                t.column("addedAt", .datetime).notNull()
                t.column("updatedAt", .datetime).notNull()
                t.column("lastFetchedAt", .datetime).notNull()
                t.column("lastReadAt", .datetime).notNull()
                t.column("orientation", .text).notNull()
                t.column("showAllChapters", .boolean).notNull().defaults(to: false)
                t.column("showHalfChapters", .boolean).notNull().defaults(to: false)
            }
            
            // author table
            try db.create(table: "author") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("name", .text).notNull().unique()
            }
            
            // tag table
            try db.create(table: "tag") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("normalizedName", .text).notNull()
                t.column("displayName", .text).notNull()
                t.column("canonicalId", .integer).references("tag", onDelete: .setNull)
            }
            
            // collection table
            try db.create(table: "collection") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("name", .text).notNull()
                t.column("description", .text)
                t.column("isPrivate", .boolean).notNull().defaults(to: false)
                t.column("createdAt", .datetime).notNull()
                t.column("updatedAt", .datetime).notNull()
            }
            
            // origin table
            try db.create(table: "origin") { t in
                t.autoIncrementedPrimaryKey("id")
                t.belongsTo("manga", onDelete: .cascade)
                t.column("sourceId", .integer).references("source", onDelete: .setNull)
                t.column("slug", .text).notNull()
                t.column("url", .text).notNull()
                t.column("priority", .integer).notNull().defaults(to: 0)
                t.column("classification", .text).notNull()
                t.column("status", .text).notNull()
            }
            
            // cover table
            try db.create(table: "cover") { t in
                t.autoIncrementedPrimaryKey("id")
                t.belongsTo("manga", onDelete: .cascade)
                t.column("isPrimary", .boolean).notNull().defaults(to: false)
                t.column("localPath", .text).notNull()
                t.column("remotePath", .text).notNull()
            }
            
            // alternative_title table
            try db.create(table: "alternative_title") { t in
                t.autoIncrementedPrimaryKey("id")
                t.belongsTo("manga", onDelete: .cascade)
                t.column("title", .text).notNull()
            }
            
            // manga_author junction table
            try db.create(table: "manga_author") { t in
                t.belongsTo("manga", onDelete: .cascade)
                t.belongsTo("author", onDelete: .cascade)
                t.primaryKey(["mangaId", "authorId"])
            }
            
            // manga_tag junction table
            try db.create(table: "manga_tag") { t in
                t.belongsTo("manga", onDelete: .cascade)
                t.belongsTo("tag", onDelete: .cascade)
                t.primaryKey(["mangaId", "tagId"])
            }
            
            // manga_collection junction table
            try db.create(table: "manga_collection") { t in
                t.belongsTo("manga", onDelete: .cascade)
                t.belongsTo("collection", onDelete: .cascade)
                t.column("order", .integer).notNull().defaults(to: 0)
                t.column("addedAt", .datetime).notNull()
                t.primaryKey(["mangaId", "collectionId"])
            }
        }
        
        private static func createChapterTables(_ db: Database) throws {
            // scanlator table
            try db.create(table: "scanlator") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("name", .text).notNull().unique()
            }
            
            // chapter table
            try db.create(table: "chapter") { t in
                t.autoIncrementedPrimaryKey("id")
                t.belongsTo("origin", onDelete: .cascade)
                t.belongsTo("scanlator", onDelete: .restrict)
                t.column("slug", .text).notNull()
                t.column("title", .text).notNull()
                t.column("number", .real).notNull()
                t.column("date", .datetime).notNull()
                t.column("url", .text).notNull()
                t.column("language", .text).notNull()
                t.column("progress", .real).notNull().defaults(to: 0)
                t.column("lastReadAt", .datetime)
            }
            
            // origin_scanlator_priority table
            try db.create(table: "origin_scanlator_priority") { t in
                t.autoIncrementedPrimaryKey("id")
                t.belongsTo("origin", onDelete: .cascade)
                t.belongsTo("scanlator", onDelete: .cascade)
                t.column("priority", .integer).notNull().defaults(to: 0)
                t.uniqueKey(["originId", "scanlatorId"])
            }
        }
        
        private static func createSearchTables(_ db: Database) throws {
            // search_config table
            try db.create(table: "search_config") { t in
                t.autoIncrementedPrimaryKey("id")
                t.belongsTo("source", onDelete: .cascade).unique()
                t.column("supportedSorts", .blob).notNull()
                t.column("supportedFilters", .blob).notNull()
            }
            
            // search_tag table
            try db.create(table: "search_tag") { t in
                t.autoIncrementedPrimaryKey("id")
                t.belongsTo("source", onDelete: .cascade)
                t.column("slug", .text).notNull()
                t.column("name", .text).notNull()
                t.column("nsfw", .boolean).notNull().defaults(to: false)
                t.uniqueKey(["sourceId", "slug"])
            }
            
            // search_preset table
            try db.create(table: "search_preset") { t in
                t.autoIncrementedPrimaryKey("id")
                t.belongsTo("source", onDelete: .cascade)
                t.column("name", .text).notNull()
                t.column("filters", .blob).notNull()
                t.column("sortOption", .text).notNull()
                t.column("sortDirection", .text).notNull()
                t.column("tagIds", .blob).notNull()
            }
        }
    }
}

// MARK: - Original Indexes
extension Migrations.InitialSchema {
    
    private static func createMangaChapterIndexes(_ db: Database) throws {
        // chapter number lookup for manga display preferences
        try db.create(
            index: "idx_chapter_origin_number",
            on: "chapter",
            columns: ["originId", "number"]
        )
        
        // origin priority lookup for chapter deduplication
        try db.create(
            index: "idx_origin_manga_priority",
            on: "origin",
            columns: ["mangaId", "priority"]
        )
        
        // scanlator priority lookup within an origin
        try db.create(
            index: "idx_origin_scanlator_priority_lookup",
            on: "origin_scanlator_priority",
            columns: ["originId", "scanlatorId", "priority"]
        )
        
        // chapter progress tracking
        try db.create(
            index: "idx_chapter_progress",
            on: "chapter",
            columns: ["originId", "progress", "number"]
        )
        
        // chapter date ordering
        try db.create(
            index: "idx_chapter_date",
            on: "chapter",
            columns: ["originId", "date"]
        )
        
        // manga library queries
        try db.create(
            index: "idx_manga_library",
            on: "manga",
            columns: ["inLibrary", "lastReadAt"]
        )
        
        // manga update tracking
        try db.create(
            index: "idx_manga_updates",
            on: "manga",
            columns: ["inLibrary", "lastFetchedAt"]
        )
    }
    
    private static func createChapterSortingIndexes(_ db: Database) throws {
        // chapter number ascending sort
        try db.create(
            index: "idx_chapter_number_asc",
            on: "chapter",
            columns: ["originId", "number", "id"]
        )
        
        // chapter number descending sort - using raw SQL for DESC
        try db.execute(sql: """
            CREATE INDEX idx_chapter_number_desc 
            ON chapter(originId, number DESC, id DESC)
        """)
        
        // chapter date ascending sort
        try db.create(
            index: "idx_chapter_date_asc",
            on: "chapter",
            columns: ["originId", "date", "number"]
        )
        
        // chapter date descending sort - using raw SQL for DESC
        try db.execute(sql: """
            CREATE INDEX idx_chapter_date_desc 
            ON chapter(originId, date DESC, number DESC)
        """)
        
        // combined sorting for deduplicated chapters
        try db.create(
            index: "idx_chapter_dedup_sort",
            on: "chapter",
            columns: ["number", "originId", "scanlatorId"]
        )
    }
    
    private static func createLibraryFilteringIndexes(_ db: Database) throws {
        // collection filtering
        try db.create(
            index: "idx_manga_collection_lookup",
            on: "manga_collection",
            columns: ["collectionId", "mangaId", "order"]
        )
        
        // tag filtering
        try db.create(
            index: "idx_manga_tag_lookup",
            on: "manga_tag",
            columns: ["tagId", "mangaId"]
        )
        
        // reverse lookup for exclude operations
        try db.create(
            index: "idx_manga_tag_reverse",
            on: "manga_tag",
            columns: ["mangaId", "tagId"]
        )
        
        // tag normalization for filtering
        try db.create(
            index: "idx_tag_normalized",
            on: "tag",
            columns: ["normalizedName", "id"]
        )
        
        // origin status/classification filtering
        try db.create(
            index: "idx_origin_status_class",
            on: "origin",
            columns: ["mangaId", "status", "classification", "priority"]
        )
        
        // source filtering via origin
        try db.create(
            index: "idx_origin_source",
            on: "origin",
            columns: ["sourceId", "mangaId", "priority"]
        )
        
        // chapter language filtering
        try db.create(
            index: "idx_chapter_language",
            on: "chapter",
            columns: ["language", "originId"]
        )
        
        // library sorting - added date
        try db.create(
            index: "idx_manga_library_added",
            on: "manga",
            columns: ["inLibrary", "addedAt"]
        )
        
        // library sorting - updated date
        try db.create(
            index: "idx_manga_library_updated",
            on: "manga",
            columns: ["inLibrary", "updatedAt"]
        )
        
        // compound index for common library query pattern
        try db.create(
            index: "idx_manga_library_compound",
            on: "manga",
            columns: ["inLibrary", "title", "id"]
        )
    }
    
    private static func createHostFilteringIndexes(_ db: Database) throws {
        // host name sorting
        try db.create(
            index: "idx_host_name",
            on: "host",
            columns: ["name", "author"]
        )
        
        // host author sorting
        try db.create(
            index: "idx_host_author_name",
            on: "host",
            columns: ["author", "name"]
        )
        
        // official hosts filtering
        try db.create(
            index: "idx_host_official",
            on: "host",
            columns: ["official", "name"]
        )
        
        // compound index for common host query patterns
        try db.create(
            index: "idx_host_official_compound",
            on: "host",
            columns: ["official", "author", "name", "id"]
        )
    }
}

// MARK: - UX Optimized: Covering Indexes
extension Migrations.InitialSchema {
    
    private static func createCoveringIndexes(_ db: Database) throws {
        // covering index for chapter list display
        // includes all fields shown in the chapter list ui
        try db.create(
            index: "idx_chapter_list_covering",
            on: "chapter",
            columns: ["originId", "number", "title", "date", "scanlatorId", "progress", "language", "id"]
        )
        
        // covering index for library card display
        // includes all data needed to render manga cards without additional lookups
        try db.create(
            index: "idx_manga_card_covering",
            on: "manga",
            columns: ["id", "title", "inLibrary", "lastReadAt", "updatedAt", "addedAt"]
        )
        
        // covering index for source list display
        try db.create(
            index: "idx_source_list_covering",
            on: "source",
            columns: ["id", "name", "icon", "pinned", "disabled", "hostId"]
        )
        
        // covering index for collection display with manga count
        try db.create(
            index: "idx_collection_display_covering",
            on: "collection",
            columns: ["id", "name", "description", "isPrivate", "updatedAt"]
        )
        
        // covering index for primary cover lookup
        // avoids additional query to get cover image
        try db.create(
            index: "idx_cover_primary_covering",
            on: "cover",
            columns: ["mangaId", "isPrimary", "localPath", "remotePath"]
        )
    }
}

// MARK: - UX Optimized: Partial Indexes
extension Migrations.InitialSchema {
    
    private static func createPartialIndexes(_ db: Database) throws {
        // partial index for unread chapters only
        // dramatically speeds up "show unread" filter
        try db.execute(sql: """
            CREATE INDEX idx_chapter_unread
            ON chapter(originId, number, date)
            WHERE progress < 1
        """)
        
        // partial index for in-library manga only
        // most queries only care about library manga
        try db.execute(sql: """
            CREATE INDEX idx_manga_in_library
            ON manga(lastReadAt DESC, title)
            WHERE inLibrary = 1
        """)
        
        // partial index for ongoing series in library
        // common filter combination
        try db.execute(sql: """
            CREATE INDEX idx_ongoing_library
            ON manga(id, title, lastReadAt)
            WHERE inLibrary = 1
        """)
        
        // partial index for pinned sources
        // quick access to favorite sources
        try db.execute(sql: """
            CREATE INDEX idx_source_pinned
            ON source(name, id)
            WHERE pinned = 1 AND disabled = 0
        """)
        
        // partial index for primary covers
        // speeds up cover image loading
        try db.execute(sql: """
            CREATE INDEX idx_cover_primary_only
            ON cover(mangaId, localPath, remotePath)
            WHERE isPrimary = 1
        """)
        
        // partial index for canonical tags only
        // excludes aliases from main tag queries
        try db.execute(sql: """
            CREATE INDEX idx_tag_canonical
            ON tag(normalizedName, displayName, id)
            WHERE canonicalId IS NULL
        """)
        
        // partial index for recent chapters
        // optimizes "new chapters" queries
        try db.execute(sql: """
            CREATE INDEX idx_chapter_recent
            ON chapter(date DESC, originId, number)
            WHERE date > datetime('now', '-30 days')
        """)
    }
}

// MARK: - UX Optimized: Expression & Computed Indexes
extension Migrations.InitialSchema {
    
    private static func createExpressionIndexes(_ db: Database) throws {
        // expression index for whole chapter numbers
        // speeds up filtering when showHalfChapters = false
        try db.execute(sql: """
            CREATE INDEX idx_chapter_whole_number
            ON chapter(originId, CAST(number AS INTEGER))
            WHERE number = CAST(number AS INTEGER)
        """)
        
        // expression index for case-insensitive title search
        // improves title-based filtering/sorting
        try db.execute(sql: """
            CREATE INDEX idx_manga_title_lower
            ON manga(LOWER(title), id)
        """)
        
        // expression index for author display format
        // speeds up "@author/name" formatted queries
        try db.execute(sql: """
            CREATE INDEX idx_host_display_name
            ON host(LOWER(author || '/' || name))
        """)
        
        // expression index for normalized tag lookup
        // speeds up case-insensitive tag matching
        try db.execute(sql: """
            CREATE INDEX idx_tag_normalized_lower
            ON tag(LOWER(normalizedName))
            WHERE canonicalId IS NULL
        """)
        
        // composite expression for common date ranges
        // optimizes "updated this week/month" queries
        try db.execute(sql: """
            CREATE INDEX idx_manga_recent_updates
            ON manga(
                inLibrary,
                (julianday('now') - julianday(updatedAt))
            )
            WHERE inLibrary = 1
        """)
        
        // sqlite doesn't support aggregate functions in index expressions
    }
}

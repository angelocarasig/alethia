//
//  Migrations+InitialSchema.swift
//  Data
//
//  Created by Angelo Carasig on 2/10/2025.
//

import Foundation
import GRDB
import Domain

extension Migrations {
    internal struct InitialSchema: Migration {
        
        static let identifier = "20251002_000000_initial_schema"
        
        static func migrate(_ db: Database) throws {
            try createHostAndSourceTables(db)
            try createMangaTables(db)
            try createChapterTables(db)
            try createSearchTables(db)
            try createEssentialIndexes(db)
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
                t.column("url", .text).notNull()
                t.column("pinned", .boolean).notNull().defaults(to: false)
                t.column("disabled", .boolean).notNull().defaults(to: false)
                t.column("authType", .text)
            }
        }
        
        private static func createMangaTables(_ db: Database) throws {
            // manga table
            try db.create(table: "manga") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("title", .text)
                    .notNull()
                    .collate(.localizedCaseInsensitiveCompare)
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
                t.column("name", .text)
                    .notNull()
                    .unique()
                    .collate(.localizedCaseInsensitiveCompare)
            }
            
            // tag table
            try db.create(table: "tag") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("normalizedName", .text)
                    .notNull()
                    .collate(.localizedCaseInsensitiveCompare)
                t.column("displayName", .text)
                    .notNull()
                    .collate(.caseInsensitiveCompare)
                t.column("canonicalId", .integer).references("tag", onDelete: .setNull)
            }
            
            // collection table
            try db.create(table: "collection") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("name", .text)
                    .notNull()
                    .collate(.localizedCaseInsensitiveCompare)
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
                t.column("title", .text)
                    .notNull()
                    .collate(.localizedCaseInsensitiveCompare)
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
                t.column("order", .integer).notNull()
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
                t.column("progress", .real).notNull()
                t.column("lastReadAt", .datetime)
            }
            
            // origin_scanlator_priority table
            try db.create(table: "origin_scanlator_priority") { t in
                t.autoIncrementedPrimaryKey("id")
                t.belongsTo("origin", onDelete: .cascade)
                t.belongsTo("scanlator", onDelete: .cascade)
                t.column("priority", .integer).notNull()
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
                t.column("description", .text).defaults(to: "")
                t.column("request", .blob).notNull()
            }
        }
        
        private static func createEssentialIndexes(_ db: Database) throws {
            // foreign key indexes
            try db.create(index: "idx_source_hostId", on: "source", columns: ["hostId"])
            try db.create(index: "idx_origin_mangaId", on: "origin", columns: ["mangaId"])
            try db.create(index: "idx_origin_sourceId", on: "origin", columns: ["sourceId"])
            try db.create(index: "idx_cover_mangaId", on: "cover", columns: ["mangaId"])
            try db.create(index: "idx_alternative_title_mangaId", on: "alternative_title", columns: ["mangaId"])
            try db.create(index: "idx_chapter_originId", on: "chapter", columns: ["originId"])
            try db.create(index: "idx_chapter_scanlatorId", on: "chapter", columns: ["scanlatorId"])
            try db.create(index: "idx_origin_scanlator_priority_originId", on: "origin_scanlator_priority", columns: ["originId"])
            try db.create(index: "idx_origin_scanlator_priority_scanlatorId", on: "origin_scanlator_priority", columns: ["scanlatorId"])
            try db.create(index: "idx_search_config_sourceId", on: "search_config", columns: ["sourceId"])
            try db.create(index: "idx_search_tag_sourceId", on: "search_tag", columns: ["sourceId"])
            try db.create(index: "idx_search_preset_sourceId", on: "search_preset", columns: ["sourceId"])
            
            // slug column indexes for api lookups
            try db.create(index: "idx_source_slug", on: "source", columns: ["slug"])
            try db.create(index: "idx_origin_slug", on: "origin", columns: ["slug"])
            try db.create(index: "idx_chapter_slug", on: "chapter", columns: ["slug"])
            try db.create(index: "idx_search_tag_slug", on: "search_tag", columns: ["slug"])
            
            // manga.chapters optimization indexes
            // composite index for the window function partition and order
            try db.create(index: "idx_chapter_dedup", on: "chapter", columns: ["originId", "number"])
            
            // composite index for origin priority lookup
            try db.create(index: "idx_origin_priority", on: "origin", columns: ["mangaId", "priority"])
            
            // composite index for scanlator priority within origin
            try db.create(index: "idx_osp_priority", on: "origin_scanlator_priority", columns: ["originId", "scanlatorId", "priority"])
        }
    }
}

//
//  Misc+Views+GRDB.swift
//  Data
//
//  Created by Claude on 15/6/2025.
//

import Foundation
import GRDB
import Domain


private typealias Misc = Domain.Models.Persistence.Misc
private typealias Chapter = Domain.Models.Persistence.Chapter
private typealias Origin = Domain.Models.Persistence.Origin
private typealias Channel = Domain.Models.Persistence.Channel
private typealias Manga = Domain.Models.Persistence.Manga

// MARK: - Database Table Definition + Migrations
extension Misc.Views: @retroactive Data.Infrastructure.DatabaseMigratable {
    public static func createTable(db: Database) throws {
        try db.create(view: BestChapter.databaseTableName, options: [ViewOptions.ifNotExists], as: BestChapter.asRequest)
    }
    
    public static func migrate(with migrator: inout DatabaseMigrator, from version: Data.Infrastructure.Version) throws {
        // nothing for now
    }
}

private struct BestChapter {
    static let databaseTableName: String = "best_chapter"
    
    static var asRequest: SQLRequest<Chapter> {
        /// Selects core chapter fields and manga display preferences.
        ///
        /// Retrieves all columns needed to construct a Chapter model instance,
        /// plus manga settings that control chapter visibility:
        /// - `showAllChapters`: Whether to show duplicate chapters from all sources
        /// - `showHalfChapters`: Whether to show non-integer chapters (e.g., 10.5)
        let select = """
           SELECT 
               c.id,
               c.originId,
               c.scanlatorId,
               c.title,
               c.slug,
               c.number,
               c.date,
               c.progress,
               c.localPath,
               
               o.mangaId,
               m.showAllChapters,
               m.showHalfChapters
       """
        
        /// Calculates priority-based ranking within dynamic partitions.
        ///
        /// Uses `ROW_NUMBER()` window function with conditional partitioning:
        ///
        /// **When `showAllChapters = 0` (default):**
        /// - Partitions by `(mangaId, number)` only
        /// - Multiple Chapter 10s compete within same partition
        /// - Only the highest priority version gets `rank = 1`
        ///
        /// **When `showAllChapters = 1`:**
        /// - Partitions by `(mangaId, number, originId, scanlatorId)`
        /// - Each chapter gets its own unique partition
        /// - All chapters receive `rank = 1` (no filtering occurs)
        ///
        /// Priority ordering within partitions:
        /// 1. Origin priority (ascending) - lower values win
        /// 2. Channel priority (ascending) - tiebreaker for same origin
        let ranking = """
           ROW_NUMBER() OVER (
               PARTITION BY 
                   o.mangaId,
                   c.number,
                   CASE WHEN m.showAllChapters = 1 THEN c.originId ELSE NULL END,
                   CASE WHEN m.showAllChapters = 1 THEN c.scanlatorId ELSE NULL END
               ORDER BY o.priority ASC, ch.priority ASC
           ) as rank
       """
        
        /// Base table containing all chapter records.
        let from = """
           FROM chapter c
       """
        
        /// Joins required tables for priority and preference data.
        ///
        /// - `origin`: Provides manga association and origin priority
        /// - `channel`: Provides scanlator priority for origin+scanlator pairs
        /// - `manga`: Provides user display preferences
        let joins = """
           JOIN origin o ON c.originId = o.id
           JOIN channel ch ON ch.originId = o.id AND ch.scanlatorId = c.scanlatorId
           JOIN manga m ON o.mangaId = m.id
       """
        
        /// Filters chapters based on half-chapter display preference.
        ///
        /// - When `showHalfChapters = 1`: All chapters pass through
        /// - When `showHalfChapters = 0`: Only integer chapters allowed (1.0, 2.0, not 1.5)
        ///
        /// Uses `CAST` comparison to detect decimal chapters.
        let options = """
           WHERE (m.showHalfChapters = 1 OR CAST(c.number AS INTEGER) = c.number)
       """
        
        let sql = [
            select + ",",
            ranking,
            from,
            joins,
            options
        ].joined(separator: "\n\n")
        
        return SQLRequest<Chapter>(sql: sql)
    }
}

//
//  BestChapterView.swift
//  Data
//
//  Created by Angelo Carasig on 11/10/2025.
//

import GRDB
import Tagged

/// Pre-calculates the "best" chapter for each chapter number per manga based on priority rules.
///
/// This view solves the deduplication problem where multiple sources/scanlators
/// provide the same chapter. It ranks chapters using:
/// 1. Origin priority (lower = better)
/// 2. Scanlator priority within that origin (lower = better)
///
/// Example:
/// - Manga X has Chapter 1 from:
///   - Origin A (priority: 0) with Scanlator Y (priority: 0) → rank = 1 ✓ BEST
///   - Origin A (priority: 0) with Scanlator Z (priority: 1) → rank = 2
///   - Origin B (priority: 1) with Scanlator Y (priority: 0) → rank = 3
internal struct BestChapterView: ViewRecord {
    let chapterId: Int64
    let number: Double
    let progress: Double
    let mangaId: Int64
    let showHalfChapters: Bool
    let rank: Int
}

// MARK: - ViewRecord

extension BestChapterView {
    static var databaseTableName: String {
        "best_chapter"
    }
    
    static let dependsOn: [any DatabaseRecord.Type] = [
        ChapterRecord.self,
        OriginRecord.self,
        OriginScanlatorPriorityRecord.self,
        MangaRecord.self
    ]
    
    static let introducedIn = DatabaseVersion(1, 0, 0)
    
    static var viewDefinition: SQLRequest<BestChapterView> {
        SQLRequest(sql: """
            SELECT 
                c.id as chapterId,
                c.number,
                c.progress,
                o.mangaId,
                m.showHalfChapters,
                -- rank chapters within each manga/number combination
                -- rank = 1 means this is the best source for this chapter number
                ROW_NUMBER() OVER (
                    PARTITION BY o.mangaId, c.number 
                    ORDER BY 
                        o.priority ASC,  -- first: origin priority (0 is best)
                        COALESCE(osp.priority, 999) ASC  -- then: scanlator priority (null treated as worst)
                ) as rank
            FROM \(ChapterRecord.databaseTableName) c
            JOIN \(OriginRecord.databaseTableName) o ON c.originId = o.id
            LEFT JOIN \(OriginScanlatorPriorityRecord.databaseTableName) osp 
                ON osp.originId = o.id 
                AND osp.scanlatorId = c.scanlatorId
            JOIN \(MangaRecord.databaseTableName) m ON o.mangaId = m.id
            """)
    }
    
    static func migrate(with migrator: inout GRDB.DatabaseMigrator, from version: DatabaseVersion) throws {
        switch version {
        case ..<DatabaseVersion(1, 0, 0):
            let migrationName = DatabaseVersion(1, 0, 0).createMigrationName(description: "best chapter view indexes")
            migrator.registerMigration(migrationName) { db in
                // optimize the window function partitioning and ordering
                try db.create(
                    index: "idx_chapter_origin_scanlator_priority",
                    on: ChapterRecord.databaseTableName,
                    columns: [
                        ChapterRecord.Columns.originId.name,
                        ChapterRecord.Columns.number.name,
                        ChapterRecord.Columns.progress.name
                    ]
                )
                
                // optimize the scanlator priority join
                try db.create(
                    index: "idx_origin_scanlator_priority_covering",
                    on: OriginScanlatorPriorityRecord.databaseTableName,
                    columns: [
                        OriginScanlatorPriorityRecord.Columns.originId.name,
                        OriginScanlatorPriorityRecord.Columns.scanlatorId.name,
                        OriginScanlatorPriorityRecord.Columns.priority.name
                    ]
                )
            }
        default:
            break
        }
    }
}

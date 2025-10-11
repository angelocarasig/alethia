//
//  EntryView.swift
//  Data
//
//  Created by Angelo Carasig on 11/10/2025.
//

import Foundation
import GRDB
import Tagged

/// Lightweight view for displaying manga entries in lists with unread counts.
/// Uses BestChapterView to efficiently calculate deduplicated chapter counts.
internal struct EntryView: ViewRecord {
    let mangaId: Int64
    let sourceId: Int64?
    let slug: String
    let title: String
    let cover: URL?
    let unreadCount: Int
    
    // date fields for sorting
    let addedAt: Date
    let updatedAt: Date
    let lastReadAt: Date
    let lastFetchedAt: Date
}

// MARK: - ViewRecord

extension EntryView {
    static var databaseTableName: String {
        "entry_view"
    }
    
    static let dependsOn: [any DatabaseRecord.Type] = [
        MangaRecord.self,
        OriginRecord.self,
        CoverRecord.self
    ]
    
    static let introducedIn = DatabaseVersion(1, 0, 0)
    
    static var viewDefinition: SQLRequest<EntryView> {
        SQLRequest(sql: """
            SELECT 
                m.id as mangaId,
                po.sourceId as sourceId,
                COALESCE(po.slug, '') as slug,
                m.title as title,
                pc.remotePath as cover,
                
                -- unread count from best chapters (rank = 1 only)
                -- respects showHalfChapters preference
                COALESCE(
                    (SELECT COUNT(*)
                     FROM \(BestChapterView.databaseTableName) bc
                     WHERE bc.mangaId = m.id
                       AND bc.rank = 1  -- only best version of each chapter
                       AND bc.progress < 1.0  -- unread
                       AND (bc.showHalfChapters = 1 OR bc.number = CAST(bc.number AS INTEGER))
                    ), 0
                ) as unreadCount,
                
                -- date fields for sorting
                m.addedAt,
                m.updatedAt,
                m.lastReadAt,
                m.lastFetchedAt
                
            FROM \(MangaRecord.databaseTableName) m
            
            -- get primary cover (isPrimary = true)
            LEFT JOIN \(CoverRecord.databaseTableName) pc 
                ON pc.mangaId = m.id 
                AND pc.isPrimary = 1
            
            -- get primary origin (lowest priority >= 0)
            LEFT JOIN \(OriginRecord.databaseTableName) po 
                ON po.mangaId = m.id 
                AND po.priority = (
                    SELECT MIN(priority) 
                    FROM \(OriginRecord.databaseTableName)
                    WHERE mangaId = m.id 
                      AND priority >= 0
                )
            """)
    }
    
    static func migrate(with migrator: inout GRDB.DatabaseMigrator, from version: DatabaseVersion) throws {
        switch version {
        case ..<DatabaseVersion(1, 0, 0):
            let migrationName = DatabaseVersion(1, 0, 0).createMigrationName(description: "entry view indexes")
            migrator.registerMigration(migrationName) { db in
                // index for primary cover lookup
                try db.create(
                    index: "idx_cover_primary",
                    on: CoverRecord.databaseTableName,
                    columns: [
                        CoverRecord.Columns.mangaId.name,
                        CoverRecord.Columns.isPrimary.name,
                        CoverRecord.Columns.remotePath.name
                    ]
                )
                
                // covering index for origin priority lookup
                try db.create(
                    index: "idx_origin_manga_priority_covering",
                    on: OriginRecord.databaseTableName,
                    columns: [
                        OriginRecord.Columns.mangaId.name,
                        OriginRecord.Columns.priority.name,
                        OriginRecord.Columns.sourceId.name,
                        OriginRecord.Columns.slug.name
                    ]
                )
            }
        default:
            break
        }
    }
}

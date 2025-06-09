//
//  Database+Views.swift
//  Alethia
//
//  Created by Angelo Carasig on 5/6/2025.
//

import Foundation
import GRDB

extension DatabaseProvider {
    func makeViews() throws {
        try writer.write { db in
            try createMangaEntryView(db)
        }
    }
    
    func createMangaEntryView(_ db: Database) throws {
        // Drop existing view if it exists
        try db.execute(sql: "DROP VIEW IF EXISTS entry")
        
        let sql = """
            CREATE VIEW entry AS
            SELECT
                m.id AS mangaId,
                m.title AS title,
                m.inLibrary AS inLibrary,
                m.addedAt AS addedAt,
                m.updatedAt AS updatedAt,
                m.lastReadAt AS lastReadAt,
                
                -- Get the source ID from the best origin
                (SELECT o.sourceId 
                 FROM origin o 
                 WHERE o.mangaId = m.id 
                 ORDER BY o.priority ASC 
                 LIMIT 1) AS sourceId,
                
                -- Construct the full URL by joining through source to host
                (SELECT 
                    RTRIM(h.baseUrl, '/') || '/' || 
                    LTRIM(s.path, '/') || '/manga/' || 
                    o.slug
                 FROM origin o
                 JOIN source s ON s.id = o.sourceId
                 JOIN host h ON h.id = s.hostId
                 WHERE o.mangaId = m.id
                 ORDER BY o.priority ASC
                 LIMIT 1) AS fetchUrl,
                
                -- Get the active cover
                (SELECT c.url 
                 FROM cover c
                 WHERE c.mangaId = m.id
                 AND c.active = 1
                 ORDER BY c.id DESC
                 LIMIT 1) AS cover,
                
                -- Optimized unread count calculation
                CAST(IFNULL((
                    SELECT COUNT(DISTINCT c.number)
                    FROM chapter c
                    JOIN origin o ON c.originId = o.id
                    JOIN originScanlator os ON os.originId = o.id AND os.scanlatorId = c.scanlatorId
                    WHERE o.mangaId = m.id
                    AND (c.progress IS NULL OR c.progress < 1.0)
                    AND (m.showHalfChapters = 1 OR CAST(c.number AS INTEGER) = c.number)
                    AND o.priority = (SELECT MIN(priority) FROM origin WHERE mangaId = m.id)
                    AND os.priority = (SELECT MIN(priority) FROM originScanlator WHERE originId = o.id)
                ), 0) AS INTEGER) AS unread
                
            FROM manga m
        """
        
        try db.execute(sql: sql)
        
        // Add strategic indexes for the optimized view
        try createEntryViewIndexes(db)
    }
    
    private func createEntryViewIndexes(_ db: Database) throws {
        // Index for chapter progress and unread calculations
        try db.execute(sql: """
            CREATE INDEX IF NOT EXISTS idx_chapter_progress_origin 
            ON chapter(originId, progress, number)
        """)
        
        // Covering index for origin priority lookups
        try db.execute(sql: """
            CREATE INDEX IF NOT EXISTS idx_origin_manga_priority_covering 
            ON origin(mangaId, priority, id, sourceId)
        """)
        
        // Covering index for originScanlator priority lookups
        try db.execute(sql: """
            CREATE INDEX IF NOT EXISTS idx_origin_scanlator_priority_covering
            ON originScanlator(originId, priority, scanlatorId)
        """)
        
        // Index for active cover lookups (already exists but ensuring it's here)
        try db.execute(sql: """
            CREATE INDEX IF NOT EXISTS idx_cover_active_manga 
            ON cover(mangaId, active, id, url) 
            WHERE active = 1
        """)
    }
}

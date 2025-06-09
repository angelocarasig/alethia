//
//  Database+Views.swift
//  Alethia
//
//  Created by Angelo Carasig on 5/6/2025.
//

import Foundation
import GRDB

extension DatabaseProvider {
    func makeViews(db: Database) throws {
        try createBestChapterView(db) // Helper view for performance
        try createMangaEntryView(db)
    }
    
    // Create a materialized helper view that pre-calculates the best chapter for each number
    func createBestChapterView(_ db: Database) throws {
        try db.execute(sql: "DROP VIEW IF EXISTS best_chapter")
        
        let sql = """
            CREATE VIEW best_chapter AS
            SELECT 
                c.id,
                c.number,
                c.progress,
                o.mangaId,
                m.showHalfChapters,
                -- Pre-calculate if this is the best chapter for this number
                ROW_NUMBER() OVER (
                    PARTITION BY o.mangaId, c.number 
                    ORDER BY o.priority ASC, os.priority ASC
                ) as rank
            FROM chapter c
            JOIN origin o ON c.originId = o.id
            JOIN originScanlator os ON os.originId = o.id AND os.scanlatorId = c.scanlatorId
            JOIN manga m ON o.mangaId = m.id
        """
        
        try db.execute(sql: sql)
    }
    
    func createMangaEntryView(_ db: Database) throws {
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
                best_origin.sourceId AS sourceId,
                best_origin.slug AS slug,
        
                -- Construct the full URL
                (RTRIM(h.baseUrl, '/') || '/' || 
                 LTRIM(s.path, '/') || '/manga/' || 
                 best_origin.slug) AS fetchUrl,
                
                -- Get the active cover
                active_cover.url AS cover,
                
                -- OPTIMIZED: Use the pre-calculated best_chapter view
                CAST(IFNULL(unread_stats.unread_count, 0) AS INTEGER) AS unread
                
            FROM manga m
            
            -- Join for best origin (single lookup instead of subquery)
            LEFT JOIN (
                SELECT o.mangaId, o.sourceId, o.slug
                FROM origin o
                WHERE o.priority = (
                    SELECT MIN(priority) 
                    FROM origin o2 
                    WHERE o2.mangaId = o.mangaId
                )
            ) best_origin ON best_origin.mangaId = m.id
            
            -- Join for source and host info
            LEFT JOIN source s ON s.id = best_origin.sourceId
            LEFT JOIN host h ON h.id = s.hostId
            
            -- Join for active cover (single lookup instead of subquery)
            LEFT JOIN (
                SELECT c.mangaId, c.url
                FROM cover c
                WHERE c.active = 1
            ) active_cover ON active_cover.mangaId = m.id
            
            -- Join for unread count using the optimized helper view
            LEFT JOIN (
                SELECT 
                    bc.mangaId,
                    COUNT(*) as unread_count
                FROM best_chapter bc
                WHERE bc.rank = 1  -- Only the best chapter for each number
                AND (bc.showHalfChapters = 1 OR CAST(bc.number AS INTEGER) = bc.number)
                AND (bc.progress IS NULL OR bc.progress < 1.0)
                GROUP BY bc.mangaId
            ) unread_stats ON unread_stats.mangaId = m.id
        """
        
        try db.execute(sql: sql)
        
        // Add strategic indexes for maximum performance
        try createEntryViewIndexes(db)
    }
    
    private func createEntryViewIndexes(_ db: Database) throws {
        // Core index for the best_chapter view performance
        try db.execute(sql: """
            CREATE INDEX IF NOT EXISTS idx_chapter_origin_scanlator_priority 
            ON chapter(originId, scanlatorId, number, progress)
        """)
        
        // Enhanced origin priority index with covering columns
        try db.execute(sql: """
            CREATE INDEX IF NOT EXISTS idx_origin_manga_priority_covering 
            ON origin(mangaId, priority, sourceId, slug)
        """)
        
        // OriginScanlator priority index
        try db.execute(sql: """
            CREATE INDEX IF NOT EXISTS idx_origin_scanlator_priority_covering
            ON originScanlator(originId, scanlatorId, priority)
        """)
        
        // Partial index for active covers only
        try db.execute(sql: """
            CREATE INDEX IF NOT EXISTS idx_cover_active_manga 
            ON cover(mangaId, url) 
            WHERE active = 1
        """)
        
        // Index for manga settings (showHalfChapters)
        try db.execute(sql: """
            CREATE INDEX IF NOT EXISTS idx_manga_settings 
            ON manga(id, showHalfChapters)
        """)
        
        // Index specifically for source-host joins
        try db.execute(sql: """
            CREATE INDEX IF NOT EXISTS idx_source_host_covering
            ON source(id, hostId, path)
        """)
        
        try db.execute(sql: """
            CREATE INDEX IF NOT EXISTS idx_host_baseurl
            ON host(id, baseUrl)
        """)
    }
}

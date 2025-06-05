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
}

// MARK: - Manga Entry
private extension DatabaseProvider {
    private func createMangaEntryView(_ db: Database) throws {
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
                
                -- Calculate unread count
                CAST(IFNULL((SELECT COUNT(*) FROM (
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
                        WHERE o.mangaId = m.id
                        AND (m.showHalfChapters = 1 OR CAST(c.number AS INTEGER) = c.number)
                    )
                    SELECT id FROM RankedChapters 
                    WHERE rank = 1 AND (progress IS NULL OR progress < 1.0)
                )), 0) AS INTEGER) AS unread
                
            FROM manga m
        """
        
        try db.execute(sql: sql)
    }
}

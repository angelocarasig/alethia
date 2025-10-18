//
//  LibraryLocalDataSource+Counting.swift
//  Data
//
//  Created by Angelo Carasig on 18/10/2025.
//

import Foundation
import Domain
import GRDB

// MARK: - Count Calculations

extension LibraryLocalDataSourceImpl {
    func calculateUnreadCount(mangaId: Int64, db: Database) throws -> Int {
        try Int.fetchOne(
            db,
            sql: """
                SELECT COUNT(1)
                FROM \(BestChapterView.databaseTableName) bc
                WHERE bc.mangaId = ?
                  AND bc.rank = 1
                  AND (bc.progress IS NULL OR bc.progress < 1)
                  AND (bc.showHalfChapters = 1 OR bc.number = CAST(bc.number AS INTEGER))
                """,
            arguments: [mangaId]
        ) ?? 0
    }
    
    func calculateChapterCount(mangaId: Int64, db: Database) throws -> Int {
        try Int.fetchOne(
            db,
            sql: """
                SELECT COUNT(1)
                FROM \(BestChapterView.databaseTableName) bc
                WHERE bc.mangaId = ?
                  AND bc.rank = 1
                  AND (bc.showHalfChapters = 1 OR bc.number = CAST(bc.number AS INTEGER))
                """,
            arguments: [mangaId]
        ) ?? 0
    }
    
    func buildUnreadCountSubquery() -> String {
        """
        COALESCE((
            SELECT COUNT(1)
            FROM \(BestChapterView.databaseTableName) bc
            WHERE bc.mangaId = manga.id
              AND bc.rank = 1
              AND (bc.progress IS NULL OR bc.progress < 1)
              AND (bc.showHalfChapters = 1 OR bc.number = CAST(bc.number AS INTEGER))
        ), 0)
        """
    }
    
    func buildChapterCountSubquery() -> String {
        """
        COALESCE((
            SELECT COUNT(1)
            FROM \(BestChapterView.databaseTableName) bc
            WHERE bc.mangaId = manga.id
              AND bc.rank = 1
              AND (bc.showHalfChapters = 1 OR bc.number = CAST(bc.number AS INTEGER))
        ), 0)
        """
    }
}

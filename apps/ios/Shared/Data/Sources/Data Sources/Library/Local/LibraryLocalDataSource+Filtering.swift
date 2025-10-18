//
//  LibraryLocalDataSource+Filtering.swift
//  Data
//
//  Created by Angelo Carasig on 18/10/2025.
//

import Foundation
import Domain
import GRDB

/// date filter apply to the query interface request
private extension DateFilter {
    func apply<T>(to request: QueryInterfaceRequest<T>, column: Column) -> QueryInterfaceRequest<T> {
        switch type {
        case .none:
            return request
        case .before(let date):
            return request.filter(column < date)
        case .after(let date):
            return request.filter(column > date)
        case .between(let start, let end):
            return request.filter(column >= start && column <= end)
        }
    }
}

// MARK: - Query Filtering

extension LibraryLocalDataSourceImpl {
    func applyFilters(
        _ request: QueryInterfaceRequest<MangaRecord>,
        filters: LibraryFilters,
        db: Database
    ) throws -> QueryInterfaceRequest<MangaRecord> {
        var result = request
        
        if let raw = filters.search, !raw.isEmpty {
            let pattern = FTS5Pattern(matchingAllPrefixesIn: raw)
            
            // if the input can't produce a valid pattern, return no rows
            guard let pattern else {
                return result.filter(sql: "0")
            }
            
            result = result.filter(sql: """
                id IN (
                    SELECT rowid
                    FROM \(MangaTitleFTS5.databaseTableName)
                    WHERE \(MangaTitleFTS5.databaseTableName) MATCH ?
                    UNION
                    SELECT mangaId
                    FROM \(MangaAltTitleFTS5.databaseTableName)
                    WHERE \(MangaAltTitleFTS5.databaseTableName) MATCH ?
                )
                """, arguments: [pattern, pattern])
        }
        
        if let collectionId = filters.collectionId {
            result = result.filter(sql: """
                id IN (
                    SELECT mc.mangaId
                    FROM \(MangaCollectionRecord.databaseTableName) mc
                    WHERE mc.collectionId = ?
                )
                """, arguments: [collectionId])
        }
        
        if !filters.sourceIds.isEmpty {
            let ids = Array(filters.sourceIds)
            let placeholders = Array(repeating: "?", count: ids.count).joined(separator: ", ")
            result = result.filter(
                sql: """
                EXISTS (
                    SELECT 1
                    FROM \(OriginRecord.databaseTableName) o
                    WHERE o.mangaId = manga.id
                      AND o.sourceId IN (\(placeholders))
                )
                """,
                arguments: StatementArguments(ids)
            )
        }
        
        if !filters.statuses.isEmpty {
            let statuses = Array(filters.statuses).map { $0.rawValue }
            let placeholders = Array(repeating: "?", count: statuses.count).joined(separator: ", ")
            result = result.filter(
                sql: """
                EXISTS (
                    SELECT 1
                    FROM \(OriginRecord.databaseTableName) o
                    WHERE o.mangaId = manga.id
                      AND o.status IN (\(placeholders))
                )
                """,
                arguments: StatementArguments(statuses)
            )
        }
        
        if !filters.classifications.isEmpty {
            let classifications = filters.classifications.map { $0.rawValue }
            let placeholders = Array(repeating: "?", count: classifications.count).joined(separator: ", ")
            result = result.filter(
                sql: """
                EXISTS (
                    SELECT 1
                    FROM \(OriginRecord.databaseTableName) o
                    WHERE o.mangaId = manga.id
                      AND o.classification IN (\(placeholders))
                )
                """,
                arguments: StatementArguments(classifications)
            )
        }
        
        if filters.addedDate.isActive {
            result = filters.addedDate.apply(to: result, column: MangaRecord.Columns.addedAt)
        }
        
        if filters.updatedDate.isActive {
            result = filters.updatedDate.apply(to: result, column: MangaRecord.Columns.updatedAt)
        }
        
        if filters.unreadOnly {
            result = result.filter(sql: """
                EXISTS (
                    SELECT 1
                    FROM \(BestChapterView.databaseTableName) bc
                    WHERE bc.mangaId = manga.id
                      AND bc.rank = 1
                      AND (bc.progress IS NULL OR bc.progress < 1)
                      AND (bc.showHalfChapters = 1 OR bc.number = CAST(bc.number AS INTEGER))
                )
                """)
        }
        
        if filters.downloadedOnly {
            // placeholder for future download tracking implementation
            result = result.filter(sql: """
                EXISTS (
                    SELECT 1
                    FROM \(OriginRecord.databaseTableName) o
                    JOIN \(ChapterRecord.databaseTableName) c ON c.originId = o.id
                    WHERE o.mangaId = manga.id
                      AND c.downloaded = 1
                )
                """)
        }
        
        return result
    }
    
    func applySorting(
        _ request: QueryInterfaceRequest<MangaRecord>,
        sort: LibrarySort
    ) -> QueryInterfaceRequest<MangaRecord> {
        let isDescending = sort.direction == .descending
        
        switch sort.field {
        case .alphabetical:
            // descending = A-Z (natural alphabetical order)
            return isDescending
            ? request.order(MangaRecord.Columns.title.asc, MangaRecord.Columns.id.asc)
            : request.order(MangaRecord.Columns.title.desc, MangaRecord.Columns.id.desc)
            
        case .lastRead:
            // descending = newest first
            return isDescending
            ? request.order(MangaRecord.Columns.lastReadAt.desc, MangaRecord.Columns.id.desc)
            : request.order(MangaRecord.Columns.lastReadAt.asc, MangaRecord.Columns.id.asc)
            
        case .lastUpdated:
            // descending = newest first
            return isDescending
            ? request.order(MangaRecord.Columns.updatedAt.desc, MangaRecord.Columns.id.desc)
            : request.order(MangaRecord.Columns.updatedAt.asc, MangaRecord.Columns.id.asc)
            
        case .dateAdded:
            // descending = newest first
            return isDescending
            ? request.order(MangaRecord.Columns.addedAt.desc, MangaRecord.Columns.id.desc)
            : request.order(MangaRecord.Columns.addedAt.asc, MangaRecord.Columns.id.asc)
            
        case .unreadCount:
            // descending = most unread first
            let expr = """
            COALESCE((
                SELECT COUNT(1)
                FROM \(BestChapterView.databaseTableName) bc
                WHERE bc.mangaId = manga.id
                  AND bc.rank = 1
                  AND (bc.progress IS NULL OR bc.progress < 1)
                  AND (bc.showHalfChapters = 1 OR bc.number = CAST(bc.number AS INTEGER))
            ), 0) \(isDescending ? "DESC" : "ASC"), manga.id \(isDescending ? "DESC" : "ASC")
            """
            return request.order(SQL(sql: expr).sqlExpression)
            
        case .chapterCount:
            // descending = most chapters first
            let expr = """
            COALESCE((
                SELECT COUNT(1)
                FROM \(BestChapterView.databaseTableName) bc
                WHERE bc.mangaId = manga.id
                  AND bc.rank = 1
                  AND (bc.showHalfChapters = 1 OR bc.number = CAST(bc.number AS INTEGER))
            ), 0) \(isDescending ? "DESC" : "ASC"), manga.id \(isDescending ? "DESC" : "ASC")
            """
            return request.order(SQL(sql: expr).sqlExpression)
        }
    }
    
    func applyKeysetPagination(
        _ request: QueryInterfaceRequest<MangaRecord>,
        afterId: Int64,
        sort: LibrarySort,
        db: Database
    ) throws -> QueryInterfaceRequest<MangaRecord> {
        var req = request
        
        guard let anchor = try MangaRecord
            .filter(MangaRecord.Columns.id == afterId)
            .fetchOne(db)
        else {
            // fallback to simple id comparison if anchor not found
            return sort.direction == .ascending
            ? req.filter(MangaRecord.Columns.id > afterId)
            : req.filter(MangaRecord.Columns.id < afterId)
        }
        
        switch sort.field {
        case .alphabetical:
            let key = anchor.title
            if sort.direction == .ascending {
                req = req.filter(
                    MangaRecord.Columns.title > key
                    || (MangaRecord.Columns.title == key && MangaRecord.Columns.id > afterId)
                )
            } else {
                req = req.filter(
                    MangaRecord.Columns.title < key
                    || (MangaRecord.Columns.title == key && MangaRecord.Columns.id < afterId)
                )
            }
            
        case .lastRead:
            let key = anchor.lastReadAt
            if sort.direction == .ascending {
                req = req.filter(
                    MangaRecord.Columns.lastReadAt > key
                    || (MangaRecord.Columns.lastReadAt == key && MangaRecord.Columns.id > afterId)
                )
            } else {
                req = req.filter(
                    MangaRecord.Columns.lastReadAt < key
                    || (MangaRecord.Columns.lastReadAt == key && MangaRecord.Columns.id < afterId)
                )
            }
            
        case .lastUpdated:
            let key = anchor.updatedAt
            if sort.direction == .ascending {
                req = req.filter(
                    MangaRecord.Columns.updatedAt > key
                    || (MangaRecord.Columns.updatedAt == key && MangaRecord.Columns.id > afterId)
                )
            } else {
                req = req.filter(
                    MangaRecord.Columns.updatedAt < key
                    || (MangaRecord.Columns.updatedAt == key && MangaRecord.Columns.id < afterId)
                )
            }
            
        case .dateAdded:
            let key = anchor.addedAt
            if sort.direction == .ascending {
                req = req.filter(
                    MangaRecord.Columns.addedAt > key
                    || (MangaRecord.Columns.addedAt == key && MangaRecord.Columns.id > afterId)
                )
            } else {
                req = req.filter(
                    MangaRecord.Columns.addedAt < key
                    || (MangaRecord.Columns.addedAt == key && MangaRecord.Columns.id < afterId)
                )
            }
            
        case .unreadCount:
            let anchorUnread = try calculateUnreadCount(mangaId: afterId, db: db)
            let sub = buildUnreadCountSubquery()
            if sort.direction == .ascending {
                req = req.filter(sql: "(\(sub)) > ? OR ((\(sub)) = ? AND manga.id > ?)",
                                 arguments: [anchorUnread, anchorUnread, afterId])
            } else {
                req = req.filter(sql: "(\(sub)) < ? OR ((\(sub)) = ? AND manga.id < ?)",
                                 arguments: [anchorUnread, anchorUnread, afterId])
            }
            
        case .chapterCount:
            let anchorChapters = try calculateChapterCount(mangaId: afterId, db: db)
            let sub = buildChapterCountSubquery()
            if sort.direction == .ascending {
                req = req.filter(sql: "(\(sub)) > ? OR ((\(sub)) = ? AND manga.id > ?)",
                                 arguments: [anchorChapters, anchorChapters, afterId])
            } else {
                req = req.filter(sql: "(\(sub)) < ? OR ((\(sub)) = ? AND manga.id < ?)",
                                 arguments: [anchorChapters, anchorChapters, afterId])
            }
        }
        
        return req
    }
}

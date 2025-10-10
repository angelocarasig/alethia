//
//  LibraryLocalDataSource.swift
//  Data
//
//  Created by Angelo Carasig on 11/10/2025.
//

import Foundation
import Domain
import GRDB

internal protocol LibraryLocalDataSource: Sendable {
    func getLibraryEntries(query: LibraryQuery) -> AsyncStream<Result<LibraryDataBundle, Error>>
}

internal struct LibraryDataBundle {
    let entries: [(manga: MangaRecord, cover: CoverRecord, unreadCount: Int, primaryOrigin: OriginRecord)]
    let totalCount: Int
    let hasMore: Bool
}

internal final class LibraryLocalDataSourceImpl: LibraryLocalDataSource {
    private let database: DatabaseConfiguration
    
    init(database: DatabaseConfiguration? = nil) {
        self.database = database ?? DatabaseConfiguration.shared
    }
    
    func getLibraryEntries(query: LibraryQuery) -> AsyncStream<Result<LibraryDataBundle, Error>> {
        AsyncStream { continuation in
            let observation = ValueObservation.tracking { [weak self] db -> LibraryDataBundle in
                guard let self = self else {
                    return LibraryDataBundle(entries: [], totalCount: 0, hasMore: false)
                }
                
                do {
                    // start with base query for library items
                    var request = MangaRecord
                        .filter(MangaRecord.Columns.inLibrary == false)
                    
                    // apply filters
                    request = try self.applyFilters(request, filters: query.filters, db: db)
                    
                    // get total count before pagination
                    let totalCount = try request.fetchCount(db)
                    
                    // apply sorting
                    request = self.applySorting(request, sort: query.sort)
                    
                    // apply cursor pagination
                    let (paginatedRequest, hasMore) = try self.applyCursor(
                        request,
                        cursor: query.cursor,
                        db: db
                    )
                    
                    // fetch the manga records
                    let mangaRecords = try paginatedRequest.fetchAll(db)
                    
                    // build entry tuples with related data
                    var entries: [(manga: MangaRecord, cover: CoverRecord, unreadCount: Int, primaryOrigin: OriginRecord)] = []
                    
                    for mangaRecord in mangaRecords {
                        guard let mangaId = mangaRecord.id else { continue }
                        
                        // fetch primary cover - skip if not found
                        guard let primaryCover = try mangaRecord.cover.fetchOne(db)
                                ?? mangaRecord.covers.limit(1).fetchOne(db) else {
                            continue // skip manga without any covers
                        }
                        
                        // fetch primary origin - skip if not found
                        guard let primaryOrigin = try mangaRecord.origin.fetchOne(db) else {
                            continue // skip manga without any origins
                        }
                        
                        // calculate unread count
                        let unreadCount = try self.calculateUnreadCount(
                            mangaId: mangaId.rawValue,
                            db: db
                        )
                        
                        entries.append((
                            manga: mangaRecord,
                            cover: primaryCover,
                            unreadCount: unreadCount,
                            primaryOrigin: primaryOrigin
                        ))
                    }
                    
                    return LibraryDataBundle(
                        entries: entries,
                        totalCount: totalCount,
                        hasMore: hasMore
                    )
                    
                } catch {
                    continuation.yield(.failure(error))
                    return LibraryDataBundle(entries: [], totalCount: 0, hasMore: false)
                }
            }
            
            let task = Task {
                do {
                    for try await bundle in observation.values(in: database.reader) {
                        if Task.isCancelled { break }
                        continuation.yield(.success(bundle))
                    }
                } catch {
                    continuation.yield(.failure(error))
                }
                continuation.finish()
            }
            
            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }
    
    // MARK: - Filter Application
    
    private func applyFilters(
        _ request: QueryInterfaceRequest<MangaRecord>,
        filters: LibraryFilters,
        db: Database
    ) throws -> QueryInterfaceRequest<MangaRecord> {
        var result = request
        
        // search filter
        if let search = filters.search, !search.isEmpty {
            result = result.filter(sql: """
                id IN (
                    SELECT rowid FROM manga_fts 
                    WHERE manga_fts MATCH ?
                )
                """, arguments: [search])
        }
        
        // collection filter
        if let collectionId = filters.collectionId {
            result = result.filter(sql: """
                id IN (
                    SELECT mangaId FROM manga_collection
                    WHERE collectionId = ?
                )
                """, arguments: [collectionId])
        }
        
        // source filter
        if !filters.sourceIds.isEmpty {
            result = result.filter(sql: """
                id IN (
                    SELECT DISTINCT mangaId FROM origin
                    WHERE sourceId IN \(filters.sourceIds.map { String($0) }.joined(separator: ","))
                )
                """)
        }
        
        // publication status filter
        if !filters.publicationStatus.isEmpty {
            let statusValues = filters.publicationStatus.map { $0.rawValue }
            result = result.filter(sql: """
                id IN (
                    SELECT DISTINCT o.mangaId
                    FROM origin o
                    WHERE o.status IN \(statusValues.map { "'\($0)'" }.joined(separator: ","))
                    AND o.priority = (
                        SELECT MIN(o2.priority)
                        FROM origin o2
                        WHERE o2.mangaId = o.mangaId
                    )
                )
                """)
        }
        
        // date filters
        if let addedDate = filters.addedDate {
            result = applyDateFilter(result, dateFilter: addedDate, column: MangaRecord.Columns.addedAt)
        }
        
        if let updatedDate = filters.updatedDate {
            result = applyDateFilter(result, dateFilter: updatedDate, column: MangaRecord.Columns.updatedAt)
        }
        
        // unread only filter
        if filters.unreadOnly {
            result = result.filter(sql: """
                id IN (
                    SELECT DISTINCT o.mangaId
                    FROM origin o
                    JOIN chapter c ON c.originId = o.id
                    WHERE c.progress < 1.0
                )
                """)
        }
        
        // downloaded only filter (for future implementation)
        if filters.downloadedOnly {
            // TODO: implement when download tracking is added
            // for now, just return the existing request
        }
        
        return result
    }
    
    private func applyDateFilter(
        _ request: QueryInterfaceRequest<MangaRecord>,
        dateFilter: DateFilter,
        column: Column
    ) -> QueryInterfaceRequest<MangaRecord> {
        switch dateFilter.type {
        case .before(let date):
            return request.filter(column < date)
        case .after(let date):
            return request.filter(column > date)
        case .between(let start, let end):
            return request.filter(column >= start && column <= end)
        }
    }
    
    // MARK: - Sorting
    
    private func applySorting(
        _ request: QueryInterfaceRequest<MangaRecord>,
        sort: LibrarySort
    ) -> QueryInterfaceRequest<MangaRecord> {
        let isAscending = sort.direction == .ascending
        
        switch sort.field {
        case .alphabetical:
            return isAscending
                ? request.order(MangaRecord.Columns.title.asc)
                : request.order(MangaRecord.Columns.title.desc)
                
        case .lastRead:
            return isAscending
                ? request.order(MangaRecord.Columns.lastReadAt.asc)
                : request.order(MangaRecord.Columns.lastReadAt.desc)
                
        case .lastUpdated:
            return isAscending
                ? request.order(MangaRecord.Columns.updatedAt.asc)
                : request.order(MangaRecord.Columns.updatedAt.desc)
                
        case .dateAdded:
            return isAscending
                ? request.order(MangaRecord.Columns.addedAt.asc)
                : request.order(MangaRecord.Columns.addedAt.desc)
                
        case .unreadCount:
            // this requires a subquery, handle separately
            return applyUnreadCountSort(request, direction: sort.direction)
            
        case .chapterCount:
            // this requires a subquery, handle separately
            return applyChapterCountSort(request, direction: sort.direction)
        }
    }
    
    private func applyUnreadCountSort(
        _ request: QueryInterfaceRequest<MangaRecord>,
        direction: SortDirection
    ) -> QueryInterfaceRequest<MangaRecord> {
        let sql = """
            LEFT JOIN (
                SELECT o.mangaId, COUNT(c.id) as unreadCount
                FROM origin o
                JOIN chapter c ON c.originId = o.id
                WHERE c.progress < 1.0
                GROUP BY o.mangaId
            ) AS unread ON manga.id = unread.mangaId
            """
        
        return request
            .annotated(with: SQL(sql: sql).sqlExpression)
            .order(SQL(sql: direction == .ascending
                ? "COALESCE(unread.unreadCount, 0) ASC"
                : "COALESCE(unread.unreadCount, 0) DESC").sqlExpression)
    }
    
    private func applyChapterCountSort(
        _ request: QueryInterfaceRequest<MangaRecord>,
        direction: SortDirection
    ) -> QueryInterfaceRequest<MangaRecord> {
        let sql = """
            LEFT JOIN (
                SELECT o.mangaId, COUNT(c.id) as chapterCount
                FROM origin o
                JOIN chapter c ON c.originId = o.id
                GROUP BY o.mangaId
            ) AS chapters ON manga.id = chapters.mangaId
            """
        
        return request
            .annotated(with: SQL(sql: sql).sqlExpression)
            .order(SQL(sql: direction == .ascending
                ? "COALESCE(chapters.chapterCount, 0) ASC"
                : "COALESCE(chapters.chapterCount, 0) DESC").sqlExpression)
    }
    
    // MARK: - Cursor Pagination
    
    private func applyCursor(
        _ request: QueryInterfaceRequest<MangaRecord>,
        cursor: LibraryCursor?,
        db: Database
    ) throws -> (request: QueryInterfaceRequest<MangaRecord>, hasMore: Bool) {
        let limit = cursor?.limit ?? 50
        var result = request
        
        if let afterId = cursor?.afterId {
            result = result.filter(MangaRecord.Columns.id > afterId)
        }
        
        // fetch one extra to determine if there are more
        let items = try result.limit(limit + 1).fetchAll(db)
        let hasMore = items.count > limit
        
        // return the limited request (without the extra item)
        let finalRequest = result.limit(limit)
        
        return (finalRequest, hasMore)
    }
    
    // MARK: - Helpers
    
    private func calculateUnreadCount(mangaId: Int64, db: Database) throws -> Int {
        let sql = """
            SELECT COUNT(*)
            FROM chapter c
            JOIN origin o ON c.originId = o.id
            WHERE o.mangaId = ?
            AND c.progress < 1.0
            """
        
        return try Int.fetchOne(db, sql: sql, arguments: [mangaId]) ?? 0
    }
}

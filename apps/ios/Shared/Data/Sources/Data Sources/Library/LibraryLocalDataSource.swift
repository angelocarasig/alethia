//
//  LibraryLocalDataSource.swift
//  Data
//
//  Created by Angelo Carasig on 11/10/2025.
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

internal protocol LibraryLocalDataSource: Sendable {
    func getLibraryEntries(query: LibraryQuery) -> AsyncStream<Result<LibraryDataBundle, Error>>
    func getLibraryCollections() -> AsyncStream<Result<[(CollectionRecord, Int)], Error>>
    func addMangaToLibrary(mangaId: Int64) async throws
    func removeMangaFromLibrary(mangaId: Int64) async throws
    func findMatches(for entries: [Entry]) async throws -> [Entry]
}

internal struct LibraryDataBundle: Sendable {
    let entries: [(manga: MangaRecord, cover: CoverRecord, unreadCount: Int, primaryOrigin: OriginRecord)]
    let totalCount: Int
    let hasMore: Bool
}

internal final class LibraryLocalDataSourceImpl: LibraryLocalDataSource {
    private let database: DatabaseConfiguration
    
    init(database: DatabaseConfiguration? = nil) {
        self.database = database ?? DatabaseConfiguration.shared
    }
    
    func getLibraryCollections() -> AsyncStream<Result<[(CollectionRecord, Int)], any Error>> {
        return AsyncStream { continuation in
            let observation = ValueObservation.tracking { db -> [(CollectionRecord, Int)] in
                let collections = try CollectionRecord
                    .order(CollectionRecord.Columns.name)
                    .fetchAll(db)
                
                return try collections.map { collection in
                    guard let collectionId = collection.id else {
                        throw StorageError.recordNotFound(table: "collection", id: "nil")
                    }
                    
                    let count = try MangaCollectionRecord
                        .filter(MangaCollectionRecord.Columns.collectionId == collectionId)
                        .fetchCount(db)
                    
                    return (collection, count)
                }
            }
            
            let task = Task {
                do {
                    for try await bundle in observation.values(in: database.reader) {
                        if Task.isCancelled { break }
                        continuation.yield(.success(bundle))
                    }
                } catch let dbError as DatabaseError {
                    continuation.yield(.failure(StorageError.from(grdbError: dbError, context: "getLibraryCollections")))
                } catch let error as StorageError {
                    continuation.yield(.failure(error))
                } catch {
                    continuation.yield(.failure(StorageError.queryFailed(sql: "getLibraryCollections", error: error)))
                }
                continuation.finish()
            }
            
            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }
    
    func addMangaToLibrary(mangaId: Int64) async throws {
        do {
            try await database.writer.write { db in
                guard var manga = try MangaRecord.fetchOne(db, key: MangaRecord.ID(rawValue: mangaId)) else {
                    throw StorageError.recordNotFound(table: "manga", id: String(mangaId))
                }
                
                manga.inLibrary = true
                manga.addedAt = Date()
                try manga.update(db)
            }
        } catch let dbError as DatabaseError {
            throw StorageError.from(grdbError: dbError, context: "addMangaToLibrary")
        } catch let error as StorageError {
            throw error
        } catch {
            throw StorageError.queryFailed(sql: "addMangaToLibrary", error: error)
        }
    }
    
    func removeMangaFromLibrary(mangaId: Int64) async throws {
        do {
            try await database.writer.write { db in
                guard var manga = try MangaRecord.fetchOne(db, key: MangaRecord.ID(rawValue: mangaId)) else {
                    throw StorageError.recordNotFound(table: "manga", id: String(mangaId))
                }
                
                manga.inLibrary = false
                manga.addedAt = .distantPast
                try manga.update(db)
            }
        } catch let dbError as DatabaseError {
            throw StorageError.from(grdbError: dbError, context: "removeMangaFromLibrary")
        } catch let error as StorageError {
            throw error
        } catch {
            throw StorageError.queryFailed(sql: "removeMangaFromLibrary", error: error)
        }
    }
    
    func findMatches(for entries: [Entry]) async throws -> [Entry] {
        do {
            return try await database.reader.read { db in
                var enrichedEntries: [Entry] = []
                enrichedEntries.reserveCapacity(entries.count)
                
                for entry in entries {
                    // note: findMatches does not calculate unread counts
                    // unread counts are only populated for library queries
                    let enriched = matchEntry(entry, in: db)
                    enrichedEntries.append(enriched)
                }
                
                return enrichedEntries
            }
        } catch let dbError as DatabaseError {
            throw StorageError.from(grdbError: dbError, context: "findMatches")
        } catch let error as StorageError {
            throw error
        } catch {
            throw StorageError.queryFailed(sql: "findMatches", error: error)
        }
    }
    
    func getLibraryEntries(query: LibraryQuery) -> AsyncStream<Result<LibraryDataBundle, Error>> {
        AsyncStream { continuation in
            let observation = ValueObservation.tracking { [weak self] db -> LibraryDataBundle in
                guard let self else {
                    return LibraryDataBundle(entries: [], totalCount: 0, hasMore: false)
                }
                
                do {
                    var request = MangaRecord
                        .filter(MangaRecord.Columns.inLibrary)
                    
                    request = try self.applyFilters(request, filters: query.filters, db: db)
                    
                    // exclude entries with null dates when sorting by those dates
                    switch query.sort.field {
                    case .lastRead:
                        request = request.filter(MangaRecord.Columns.lastReadAt != nil)
                    case .lastUpdated:
                        request = request.filter(MangaRecord.Columns.updatedAt != nil)
                    case .dateAdded:
                        request = request.filter(MangaRecord.Columns.addedAt != nil)
                    default:
                        break
                    }
                    
                    let totalCount = try request.fetchCount(db)
                    request = self.applySorting(request, sort: query.sort)
                    
                    if let afterId = query.cursor?.afterId {
                        request = try self.applyKeysetPagination(request, afterId: afterId, sort: query.sort, db: db)
                    }
                    
                    // fetch limit+1 rows to determine if more exist
                    let limit = query.cursor?.limit ?? 50
                    let limited = request.limit(limit + 1)
                    
                    var tuples: [(manga: MangaRecord, cover: CoverRecord, unreadCount: Int, primaryOrigin: OriginRecord)] = []
                    tuples.reserveCapacity(min(limit, 64))
                    var count = 0
                    var sawExtra = false
                    
                    let cursor = try MangaRecord.fetchCursor(db, limited)
                    while let manga = try cursor.next() {
                        count += 1
                        if count <= limit {
                            guard let mangaId = manga.id?.rawValue else { continue }
                            
                            guard let cover = try manga.cover.fetchOne(db) ?? manga.covers.limit(1).fetchOne(db) else {
                                continue
                            }
                            guard let origin = try manga.origin.fetchOne(db) else {
                                continue
                            }
                            
                            let unread = try self.calculateUnreadCount(mangaId: mangaId, db: db)
                            
                            tuples.append((manga: manga, cover: cover, unreadCount: unread, primaryOrigin: origin))
                        } else {
                            sawExtra = true
                            break
                        }
                    }
                    
                    return LibraryDataBundle(entries: tuples, totalCount: totalCount, hasMore: sawExtra)
                    
                } catch let dbError as DatabaseError {
                    throw StorageError.from(grdbError: dbError, context: "getLibraryEntries")
                } catch let error as StorageError {
                    throw error
                } catch {
                    throw StorageError.queryFailed(sql: "getLibraryEntries", error: error)
                }
            }
            
            let task = Task {
                do {
                    for try await bundle in observation.values(in: database.reader) {
                        if Task.isCancelled { break }
                        continuation.yield(.success(bundle))
                    }
                } catch let error as StorageError {
                    continuation.yield(.failure(error))
                } catch {
                    continuation.yield(.failure(StorageError.queryFailed(sql: "getLibraryEntries observation", error: error)))
                }
                continuation.finish()
            }
            
            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }
}

// MARK: - Find Matches Helpers

private extension LibraryLocalDataSourceImpl {
    func matchEntry(_ entry: Entry, in db: Database) -> Entry {
        do {
            // step 1: try slug matching (highest priority)
            let slugMatches = try findBySlug(entry.slug, in: db)
            
            if slugMatches.count == 1 {
                let manga = slugMatches[0]
                guard let mangaId = manga.id else {
                    throw StorageError.recordNotFound(table: "manga", id: "nil after slug match")
                }
                
                let origins = try manga.origins.fetchAll(db)
                let hasSameSource = origins.contains { $0.sourceId?.rawValue == entry.sourceId }
                
                if hasSameSource {
                    return Entry(
                        mangaId: mangaId.rawValue,
                        sourceId: entry.sourceId,
                        slug: entry.slug,
                        title: entry.title,
                        cover: entry.cover,
                        state: .exactMatch,
                        unread: 0
                    )
                } else {
                    return Entry(
                        mangaId: mangaId.rawValue,
                        sourceId: entry.sourceId,
                        slug: entry.slug,
                        title: entry.title,
                        cover: entry.cover,
                        state: .crossSourceMatch,
                        unread: 0
                    )
                }
            } else if slugMatches.count > 1 {
                // multiple slug matches - data corruption
                return Entry(
                    mangaId: nil,
                    sourceId: entry.sourceId,
                    slug: entry.slug,
                    title: entry.title,
                    cover: entry.cover,
                    state: .matchVerificationFailed,
                    unread: 0
                )
            }
            
            // step 2: try title matching (fallback)
            let titleMatches = try findByTitle(entry.title, in: db)
            
            if titleMatches.isEmpty {
                return Entry(
                    mangaId: nil,
                    sourceId: entry.sourceId,
                    slug: entry.slug,
                    title: entry.title,
                    cover: entry.cover,
                    state: .noMatch,
                    unread: 0
                )
            }
            
            // check which matches have same source
            var sameSourceMatches: [MangaRecord] = []
            for manga in titleMatches {
                let origins = try manga.origins.fetchAll(db)
                if origins.contains(where: { $0.sourceId?.rawValue == entry.sourceId }) {
                    sameSourceMatches.append(manga)
                }
            }
            
            if sameSourceMatches.count == 1 {
                guard let mangaId = sameSourceMatches[0].id else {
                    throw StorageError.recordNotFound(table: "manga", id: "nil after title match")
                }
                
                return Entry(
                    mangaId: mangaId.rawValue,
                    sourceId: entry.sourceId,
                    slug: entry.slug,
                    title: entry.title,
                    cover: entry.cover,
                    state: .titleMatchSameSource,
                    unread: 0
                )
            } else if sameSourceMatches.count > 1 {
                return Entry(
                    mangaId: nil,
                    sourceId: entry.sourceId,
                    slug: entry.slug,
                    title: entry.title,
                    cover: entry.cover,
                    state: .titleMatchSameSourceAmbiguous,
                    unread: 0
                )
            } else {
                // title matches but all from different sources
                return Entry(
                    mangaId: nil,
                    sourceId: entry.sourceId,
                    slug: entry.slug,
                    title: entry.title,
                    cover: entry.cover,
                    state: .titleMatchDifferentSource,
                    unread: 0
                )
            }
            
        } catch {
            // any error during matching
            return Entry(
                mangaId: nil,
                sourceId: entry.sourceId,
                slug: entry.slug,
                title: entry.title,
                cover: entry.cover,
                state: .matchVerificationFailed,
                unread: 0
            )
        }
    }
    
    func findBySlug(_ slug: String, in db: Database) throws -> [MangaRecord] {
        let sql = """
            SELECT DISTINCT manga.*
            FROM \(MangaRecord.databaseTableName) manga
            JOIN \(OriginRecord.databaseTableName) origin ON origin.mangaId = manga.id
            WHERE origin.slug = ?
            """
        
        return try MangaRecord.fetchAll(db, sql: sql, arguments: [slug])
    }
    
    func findByTitle(_ title: String, in db: Database) throws -> [MangaRecord] {
        // sanitize input for fts5 to avoid syntax errors
        let sanitizedTitle = sanitizeForFTS(title)
        
        // fallback to like query if sanitized title is empty
        guard !sanitizedTitle.isEmpty else {
            return try findByTitleWithLike(title, in: db)
        }
        
        let sql = """
            SELECT DISTINCT manga.*
            FROM \(MangaRecord.databaseTableName) manga
            WHERE manga.id IN (
                SELECT rowid as mangaId FROM \(MangaTitleFTS5.databaseTableName)
                WHERE \(MangaTitleFTS5.databaseTableName) MATCH ?
                
                UNION
                
                SELECT mangaId FROM \(MangaAltTitleFTS5.databaseTableName)
                WHERE \(MangaAltTitleFTS5.databaseTableName) MATCH ?
            )
            """
        
        do {
            return try MangaRecord.fetchAll(db, sql: sql, arguments: [sanitizedTitle, sanitizedTitle])
        } catch let dbError as DatabaseError {
            // if fts fails, fallback to like query
            #if DEBUG
            print("FTS query failed in findMatches, falling back to LIKE: \(dbError)")
            #endif
            return try findByTitleWithLike(title, in: db)
        }
    }
    
    func findByTitleWithLike(_ title: String, in db: Database) throws -> [MangaRecord] {
        let sql = """
            SELECT DISTINCT manga.*
            FROM \(MangaRecord.databaseTableName) manga
            WHERE manga.id IN (
                SELECT id as mangaId FROM \(MangaRecord.databaseTableName)
                WHERE title = ? COLLATE NOCASE
                
                UNION
                
                SELECT mangaId FROM \(AlternativeTitleRecord.databaseTableName)
                WHERE title = ? COLLATE NOCASE
            )
            """
        
        return try MangaRecord.fetchAll(db, sql: sql, arguments: [title, title])
    }
    
    // sanitize input for fts5 queries to avoid syntax errors
    func sanitizeForFTS(_ query: String) -> String {
        // remove fts5 special characters that act as operators
        let specialChars = CharacterSet(charactersIn: "!\"^*()+-")
        return query.components(separatedBy: specialChars)
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespaces)
    }
}

// MARK: - Query Building Helpers

private extension LibraryLocalDataSourceImpl {
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
}

// MARK: - Keyset Pagination Helpers

private extension LibraryLocalDataSourceImpl {
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

// MARK: - Count Calculation Helpers

private extension LibraryLocalDataSourceImpl {
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
}

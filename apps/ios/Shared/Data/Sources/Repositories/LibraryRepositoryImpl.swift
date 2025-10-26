//
//  LibraryRepositoryImpl.swift
//  Data
//
//  Created by Angelo Carasig on 11/10/2025.
//

import Foundation
import Domain
import GRDB

public final class LibraryRepositoryImpl: LibraryRepository {
    private let database: DatabaseConfiguration
    
    public init() {
        self.database = DatabaseConfiguration.shared
    }
    
    // MARK: - Library Operations
    
    public func update(mangaId: Int64, inLibrary: Bool, in db: Any) throws {
        guard let db = db as? Database else {
            throw StorageError.invalidCast(expected: "Database", actual: String(describing: type(of: db)))
        }
        
        guard var manga = try MangaRecord.fetchOne(db, key: MangaRecord.ID(rawValue: mangaId)) else {
            throw StorageError.recordNotFound(table: "manga", id: String(mangaId))
        }
        
        manga.inLibrary = inLibrary
        if inLibrary {
            manga.addedAt = Date()
        } else {
            manga.addedAt = .distantPast
        }
        try manga.update(db)
    }
    
    public func update(mangaId: Int64, addedDate: Date, in db: Any) throws {
        guard let db = db as? Database else {
            throw StorageError.invalidCast(expected: "Database", actual: String(describing: type(of: db)))
        }
        
        guard var manga = try MangaRecord.fetchOne(db, key: MangaRecord.ID(rawValue: mangaId)) else {
            throw StorageError.recordNotFound(table: "manga", id: String(mangaId))
        }
        
        manga.addedAt = addedDate
        try manga.update(db)
    }
    
    // MARK: - Collection Operations
    
    public func fetch(collectionId: Int64, in db: Any) throws -> Any? {
        guard let db = db as? Database else {
            throw StorageError.invalidCast(expected: "Database", actual: String(describing: type(of: db)))
        }
        
        return try CollectionRecord.fetchOne(db, key: CollectionRecord.ID(rawValue: collectionId))
    }
    
    public func fetchCollections(in db: Any) throws -> [(collection: Any, count: Int)] {
        guard let db = db as? Database else {
            throw StorageError.invalidCast(expected: "Database", actual: String(describing: type(of: db)))
        }
        
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
            
            return (collection: collection as Any, count: count)
        }
    }
    
    @discardableResult
    public func save(collection name: String, description: String?, in db: Any) throws -> Any {
        guard let db = db as? Database else {
            throw StorageError.invalidCast(expected: "Database", actual: String(describing: type(of: db)))
        }
        
        var collection = CollectionRecord(
            name: name,
            description: description
        )
        try collection.insert(db)
        return collection
    }
    
    public func update(collectionId: Int64, fields: CollectionUpdateFields, in db: Any) throws {
        guard let db = db as? Database else {
            throw StorageError.invalidCast(expected: "Database", actual: String(describing: type(of: db)))
        }
        
        guard var collection = try CollectionRecord.fetchOne(db, key: CollectionRecord.ID(rawValue: collectionId)) else {
            throw StorageError.recordNotFound(table: "collection", id: String(collectionId))
        }
        
        if let name = fields.name { collection.name = name }
        if let description = fields.description { collection.description = description }
        collection.updatedAt = Date()
        
        try collection.update(db)
    }
    
    public func delete(collectionId: Int64, in db: Any) throws {
        guard let db = db as? Database else {
            throw StorageError.invalidCast(expected: "Database", actual: String(describing: type(of: db)))
        }
        
        try CollectionRecord.filter(CollectionRecord.Columns.id == collectionId).deleteAll(db)
    }
    
    public func add(mangaId: Int64, toCollection collectionId: Int64, in db: Any) throws {
        guard let db = db as? Database else {
            throw StorageError.invalidCast(expected: "Database", actual: String(describing: type(of: db)))
        }
        
        var junction = MangaCollectionRecord(
            mangaId: MangaRecord.ID(rawValue: mangaId),
            collectionId: CollectionRecord.ID(rawValue: collectionId)
        )
        try junction.insert(db, onConflict: .ignore)
    }
    
    public func remove(mangaId: Int64, fromCollection collectionId: Int64, in db: Any) throws {
        guard let db = db as? Database else {
            throw StorageError.invalidCast(expected: "Database", actual: String(describing: type(of: db)))
        }
        
        try MangaCollectionRecord
            .filter(MangaCollectionRecord.Columns.mangaId == mangaId)
            .filter(MangaCollectionRecord.Columns.collectionId == collectionId)
            .deleteAll(db)
    }
    
    // MARK: - Query Construction
    
    public func createQuery(in db: Any) throws -> Any {
        guard let db = db as? Database else {
            throw StorageError.invalidCast(expected: "Database", actual: String(describing: type(of: db)))
        }
        
        // base query for library entries
        return MangaRecord.filter(MangaRecord.Columns.inLibrary == true)
    }
    
    // MARK: - Query Filtering
    
    public func apply(search: String, to query: Any, in db: Any) throws -> Any {
        guard let request = query as? QueryInterfaceRequest<MangaRecord>,
              let db = db as? Database else {
            throw StorageError.invalidCast(expected: "QueryInterfaceRequest<MangaRecord>", actual: String(describing: type(of: query)))
        }
        
        let pattern = FTS5Pattern(matchingAllPrefixesIn: search)
        guard let pattern else {
            return request.filter(sql: "0")
        }
        
        return request.filter(sql: """
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
    
    public func apply(collectionId: Int64, to query: Any, in db: Any) throws -> Any {
        guard let request = query as? QueryInterfaceRequest<MangaRecord> else {
            throw StorageError.invalidCast(expected: "QueryInterfaceRequest<MangaRecord>", actual: String(describing: type(of: query)))
        }
        
        return request.filter(sql: """
            id IN (
                SELECT mc.mangaId
                FROM \(MangaCollectionRecord.databaseTableName) mc
                WHERE mc.collectionId = ?
            )
            """, arguments: [collectionId])
    }
    
    public func apply(sourceIds: Set<Int64>, to query: Any, in db: Any) throws -> Any {
        guard let request = query as? QueryInterfaceRequest<MangaRecord> else {
            throw StorageError.invalidCast(expected: "QueryInterfaceRequest<MangaRecord>", actual: String(describing: type(of: query)))
        }
        
        let ids = Array(sourceIds)
        let placeholders = Array(repeating: "?", count: ids.count).joined(separator: ", ")
        
        return request.filter(
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
    
    public func apply(statuses: Set<Status>, to query: Any, in db: Any) throws -> Any {
        guard let request = query as? QueryInterfaceRequest<MangaRecord> else {
            throw StorageError.invalidCast(expected: "QueryInterfaceRequest<MangaRecord>", actual: String(describing: type(of: query)))
        }
        
        let statusValues = Array(statuses).map { $0.rawValue }
        let placeholders = Array(repeating: "?", count: statusValues.count).joined(separator: ", ")
        
        return request.filter(
            sql: """
            EXISTS (
                SELECT 1
                FROM \(OriginRecord.databaseTableName) o
                WHERE o.mangaId = manga.id
                  AND o.status IN (\(placeholders))
            )
            """,
            arguments: StatementArguments(statusValues)
        )
    }
    
    public func apply(classifications: Set<Classification>, to query: Any, in db: Any) throws -> Any {
        guard let request = query as? QueryInterfaceRequest<MangaRecord> else {
            throw StorageError.invalidCast(expected: "QueryInterfaceRequest<MangaRecord>", actual: String(describing: type(of: query)))
        }
        
        let classificationValues = classifications.map { $0.rawValue }
        let placeholders = Array(repeating: "?", count: classificationValues.count).joined(separator: ", ")
        
        return request.filter(
            sql: """
            EXISTS (
                SELECT 1
                FROM \(OriginRecord.databaseTableName) o
                WHERE o.mangaId = manga.id
                  AND o.classification IN (\(placeholders))
            )
            """,
            arguments: StatementArguments(classificationValues)
        )
    }
    
    public func apply(dateFilter: DateFilter, column: String, to query: Any, in db: Any) throws -> Any {
        guard let request = query as? QueryInterfaceRequest<MangaRecord> else {
            throw StorageError.invalidCast(expected: "QueryInterfaceRequest<MangaRecord>", actual: String(describing: type(of: query)))
        }
        
        let columnRef = Column(column)
        
        switch dateFilter.type {
        case .none:
            return request
        case .before(let date):
            return request.filter(columnRef < date)
        case .after(let date):
            return request.filter(columnRef > date)
        case .between(let start, let end):
            return request.filter(columnRef >= start && columnRef <= end)
        }
    }
    
    public func applyUnreadOnly(to query: Any, in db: Any) throws -> Any {
        guard let request = query as? QueryInterfaceRequest<MangaRecord> else {
            throw StorageError.invalidCast(expected: "QueryInterfaceRequest<MangaRecord>", actual: String(describing: type(of: query)))
        }
        
        return request.filter(sql: """
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
    
    public func applyDownloadedOnly(to query: Any, in db: Any) throws -> Any {
        guard let request = query as? QueryInterfaceRequest<MangaRecord> else {
            throw StorageError.invalidCast(expected: "QueryInterfaceRequest<MangaRecord>", actual: String(describing: type(of: query)))
        }
        
        // placeholder for future download tracking implementation
        return request.filter(sql: """
            EXISTS (
                SELECT 1
                FROM \(OriginRecord.databaseTableName) o
                JOIN \(ChapterRecord.databaseTableName) c ON c.originId = o.id
                WHERE o.mangaId = manga.id
                  AND c.downloaded = 1
            )
            """)
    }
    
    // MARK: - Query Sorting
    
    public func sort(byTitle query: Any, direction: SortDirection) throws -> Any {
        guard let request = query as? QueryInterfaceRequest<MangaRecord> else {
            throw StorageError.invalidCast(expected: "QueryInterfaceRequest<MangaRecord>", actual: String(describing: type(of: query)))
        }
        
        // for alphabetical, descending = A-Z (natural order)
        return direction == .descending
            ? request.order(MangaRecord.Columns.title.asc, MangaRecord.Columns.id.asc)
            : request.order(MangaRecord.Columns.title.desc, MangaRecord.Columns.id.desc)
    }
    
    public func sort(byLastRead query: Any, direction: SortDirection) throws -> Any {
        guard let request = query as? QueryInterfaceRequest<MangaRecord> else {
            throw StorageError.invalidCast(expected: "QueryInterfaceRequest<MangaRecord>", actual: String(describing: type(of: query)))
        }
        
        return direction == .descending
            ? request.order(MangaRecord.Columns.lastReadAt.desc, MangaRecord.Columns.id.desc)
            : request.order(MangaRecord.Columns.lastReadAt.asc, MangaRecord.Columns.id.asc)
    }
    
    public func sort(byLastUpdated query: Any, direction: SortDirection) throws -> Any {
        guard let request = query as? QueryInterfaceRequest<MangaRecord> else {
            throw StorageError.invalidCast(expected: "QueryInterfaceRequest<MangaRecord>", actual: String(describing: type(of: query)))
        }
        
        return direction == .descending
            ? request.order(MangaRecord.Columns.updatedAt.desc, MangaRecord.Columns.id.desc)
            : request.order(MangaRecord.Columns.updatedAt.asc, MangaRecord.Columns.id.asc)
    }
    
    public func sort(byDateAdded query: Any, direction: SortDirection) throws -> Any {
        guard let request = query as? QueryInterfaceRequest<MangaRecord> else {
            throw StorageError.invalidCast(expected: "QueryInterfaceRequest<MangaRecord>", actual: String(describing: type(of: query)))
        }
        
        return direction == .descending
            ? request.order(MangaRecord.Columns.addedAt.desc, MangaRecord.Columns.id.desc)
            : request.order(MangaRecord.Columns.addedAt.asc, MangaRecord.Columns.id.asc)
    }
    
    public func sort(byUnreadCount query: Any, direction: SortDirection, in db: Any) throws -> Any {
        guard let request = query as? QueryInterfaceRequest<MangaRecord> else {
            throw StorageError.invalidCast(expected: "QueryInterfaceRequest<MangaRecord>", actual: String(describing: type(of: query)))
        }
        
        let expr = """
        COALESCE((
            SELECT COUNT(1)
            FROM \(BestChapterView.databaseTableName) bc
            WHERE bc.mangaId = manga.id
              AND bc.rank = 1
              AND (bc.progress IS NULL OR bc.progress < 1)
              AND (bc.showHalfChapters = 1 OR bc.number = CAST(bc.number AS INTEGER))
        ), 0) \(direction == .descending ? "DESC" : "ASC"), manga.id \(direction == .descending ? "DESC" : "ASC")
        """
        
        return request.order(SQL(sql: expr).sqlExpression)
    }
    
    public func sort(byChapterCount query: Any, direction: SortDirection, in db: Any) throws -> Any {
        guard let request = query as? QueryInterfaceRequest<MangaRecord> else {
            throw StorageError.invalidCast(expected: "QueryInterfaceRequest<MangaRecord>", actual: String(describing: type(of: query)))
        }
        
        let expr = """
        COALESCE((
            SELECT COUNT(1)
            FROM \(BestChapterView.databaseTableName) bc
            WHERE bc.mangaId = manga.id
              AND bc.rank = 1
              AND (bc.showHalfChapters = 1 OR bc.number = CAST(bc.number AS INTEGER))
        ), 0) \(direction == .descending ? "DESC" : "ASC"), manga.id \(direction == .descending ? "DESC" : "ASC")
        """
        
        return request.order(SQL(sql: expr).sqlExpression)
    }
    
    // MARK: - Query Pagination
    
    public func apply(limit: Int, to query: Any) throws -> Any {
        guard let request = query as? QueryInterfaceRequest<MangaRecord> else {
            throw StorageError.invalidCast(expected: "QueryInterfaceRequest<MangaRecord>", actual: String(describing: type(of: query)))
        }
        
        return request.limit(limit)
    }
    
    public func apply(afterId: Int64, sort: LibrarySort, to query: Any, in db: Any) throws -> Any {
        guard let request = query as? QueryInterfaceRequest<MangaRecord>,
              let db = db as? Database else {
            throw StorageError.invalidCast(expected: "QueryInterfaceRequest<MangaRecord>", actual: String(describing: type(of: query)))
        }
        
        guard let anchor = try MangaRecord
            .filter(MangaRecord.Columns.id == afterId)
            .fetchOne(db)
        else {
            // fallback to simple id comparison if anchor not found
            return sort.direction == .ascending
                ? request.filter(MangaRecord.Columns.id > afterId)
                : request.filter(MangaRecord.Columns.id < afterId)
        }
        
        var req = request
        
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
            let anchorUnread = try countUnreadChapters(mangaId: afterId, in: db)
            let sub = buildUnreadCountSubquery()
            if sort.direction == .ascending {
                req = req.filter(sql: "(\(sub)) > ? OR ((\(sub)) = ? AND manga.id > ?)",
                                 arguments: [anchorUnread, anchorUnread, afterId])
            } else {
                req = req.filter(sql: "(\(sub)) < ? OR ((\(sub)) = ? AND manga.id < ?)",
                                 arguments: [anchorUnread, anchorUnread, afterId])
            }
            
        case .chapterCount:
            let anchorChapters = try countTotalChapters(mangaId: afterId, in: db)
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
    
    // MARK: - Manga Search Operations
    
    public func fetchManga(bySlug slug: String, in db: Any) throws -> [Any] {
        guard let db = db as? Database else {
            throw StorageError.invalidCast(expected: "Database", actual: String(describing: type(of: db)))
        }
        
        let sql = """
            SELECT DISTINCT manga.*
            FROM \(MangaRecord.databaseTableName) manga
            JOIN \(OriginRecord.databaseTableName) origin ON origin.mangaId = manga.id
            WHERE origin.slug = ?
              AND manga.inLibrary = 1
            """
        
        return try MangaRecord.fetchAll(db, sql: sql, arguments: [slug])
    }
    
    public func fetchManga(byTitle title: String, in db: Any) throws -> [Any] {
        guard let db = db as? Database else {
            throw StorageError.invalidCast(expected: "Database", actual: String(describing: type(of: db)))
        }
        
        let sql = """
            SELECT DISTINCT manga.*
            FROM \(MangaRecord.databaseTableName) manga
            WHERE manga.inLibrary = 1
              AND manga.id IN (
                SELECT id as mangaId FROM \(MangaRecord.databaseTableName)
                WHERE title = ? COLLATE NOCASE
                
                UNION
                
                SELECT mangaId FROM \(AlternativeTitleRecord.databaseTableName)
                WHERE title = ? COLLATE NOCASE
            )
            """
        
        return try MangaRecord.fetchAll(db, sql: sql, arguments: [title, title])
    }
    
    public func fetchOrigins(mangaId: Int64, in db: Any) throws -> [Any] {
        guard let db = db as? Database else {
            throw StorageError.invalidCast(expected: "Database", actual: String(describing: type(of: db)))
        }
        
        return try OriginRecord
            .filter(OriginRecord.Columns.mangaId == mangaId)
            .fetchAll(db)
    }
    
    // MARK: - Count Operations
    
    public func countUnreadChapters(mangaId: Int64, in db: Any) throws -> Int {
        guard let db = db as? Database else {
            throw StorageError.invalidCast(expected: "Database", actual: String(describing: type(of: db)))
        }
        
        return try Int.fetchOne(
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
    
    public func countTotalChapters(mangaId: Int64, in db: Any) throws -> Int {
        guard let db = db as? Database else {
            throw StorageError.invalidCast(expected: "Database", actual: String(describing: type(of: db)))
        }
        
        return try Int.fetchOne(
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
    
    public func count(results query: Any, in db: Any) throws -> Int {
        guard let request = query as? QueryInterfaceRequest<MangaRecord>,
              let db = db as? Database else {
            throw StorageError.invalidCast(expected: "QueryInterfaceRequest<MangaRecord>", actual: String(describing: type(of: query)))
        }
        
        return try request.fetchCount(db)
    }
    
    // MARK: - Fetch Operations
    
    public func createCursor(for query: Any, in db: Any) throws -> Any {
        guard let request = query as? QueryInterfaceRequest<MangaRecord>,
              let db = db as? Database else {
            throw StorageError.invalidCast(expected: "QueryInterfaceRequest<MangaRecord>", actual: String(describing: type(of: query)))
        }
        
        return try MangaRecord.fetchCursor(db, request)
    }
    
    public func fetchEntryData(manga: Any, in db: Any) throws -> LibraryEntryData? {
        guard let manga = manga as? MangaRecord,
              let db = db as? Database else {
            throw StorageError.invalidCast(expected: "MangaRecord", actual: String(describing: type(of: manga)))
        }
        
        guard let mangaId = manga.id?.rawValue else { return nil }
        
        guard let cover = try manga.cover.fetchOne(db) ?? manga.covers.limit(1).fetchOne(db) else {
            return nil
        }
        
        guard let origin = try manga.origin.fetchOne(db) else {
            return nil
        }
        
        let unread = try countUnreadChapters(mangaId: mangaId, in: db)
        
        return LibraryEntryData(
            manga: manga,
            cover: cover,
            unreadCount: unread,
            primaryOrigin: origin
        )
    }
    
    // MARK: - Private Helpers
    
    private func buildUnreadCountSubquery() -> String {
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
    
    private func buildChapterCountSubquery() -> String {
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

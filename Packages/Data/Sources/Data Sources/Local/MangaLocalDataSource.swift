//
//  MangaLocalDataSource.swift
//  Data
//
//  Created by Angelo Carasig on 14/6/2025.
//

import Foundation
import Domain
import Combine
import GRDB

internal typealias MangaLocalDataSource = Data.DataSources.MangaLocalDataSource
private typealias Details = Domain.Models.Virtual.Details
private typealias Entry = Domain.Models.Virtual.Entry

public extension Data.DataSources {
    final class MangaLocalDataSource: Sendable {
        private let database: DatabaseWriter
        
        internal init(database: DatabaseWriter = DatabaseProvider.shared.writer) {
            self.database = database
        }
    }
}

// MARK: - Library Operations

internal extension MangaLocalDataSource {
    /// Retrieves filtered and sorted library entries.
    ///
    /// Provides a reactive stream of manga entries that are marked as in the user's library,
    /// with support for complex filtering, searching, and sorting operations.
    ///
    /// ## Filtering
    /// - **Collection**: Optionally scope results to a specific collection
    /// - **Search**: Full-text search across main and alternative titles
    /// - **Dates**: Filter by when manga was added, updated, or last read
    /// - **Metadata**: Filter by publish status and content classification
    /// - **Tags**: Include/exclude manga based on tag associations (TODO)
    ///
    /// ## Sorting
    /// Results can be sorted by title, date added, last updated, or last read,
    /// in either ascending or descending order.
    ///
    /// - Parameters:
    ///   - filters: Comprehensive filter and sort preferences
    ///   - collectionId: Optional collection ID to scope results
    /// - Returns: Publisher emitting arrays of filtered entries, errors on database failures
    /// - Note: Uses FTS5 for efficient full-text search when search text is provided
    func getLibrary(
        filters: Domain.Models.Presentation.LibraryFilters,
        collectionId: Int64?
    ) -> AnyPublisher<[Domain.Models.Virtual.Entry], Error> {
        let search = filters.searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        return ValueObservation
            .tracking { [weak self] db -> [Domain.Models.Virtual.Entry] in
                guard let self = self else { return [] }
                
                // Start with entries that are in library
                var request = Domain.Models.Virtual.Entry
                    .filter(Domain.Models.Virtual.Entry.Columns.inLibrary == true)
                
                // Apply collection filter
                if let collectionId = collectionId {
                    request = try self.applyCollectionFilter(
                        to: request,
                        collectionId: collectionId,
                        db: db
                    )
                }
                
                // Apply date filters
                request = self.applyDateFilter(
                    to: request,
                    column: Domain.Models.Virtual.Entry.Columns.addedAt,
                    date: filters.addedAt
                )
                request = self.applyDateFilter(
                    to: request,
                    column: Domain.Models.Virtual.Entry.Columns.updatedAt,
                    date: filters.updatedAt
                )
                
                // Apply publish status filter
                if !filters.publishStatus.isEmpty {
                    request = self.applyPublishStatusFilter(
                        to: request,
                        statuses: filters.publishStatus
                    )
                }
                
                // Apply classification filter
                if !filters.classification.isEmpty {
                    request = self.applyClassificationFilter(
                        to: request,
                        classifications: filters.classification
                    )
                }
                
                // Apply search filter
                if !search.isEmpty {
                    request = try self.applySearchFilter(
                        to: request,
                        search: search,
                        db: db
                    )
                }
                
                // Apply sorting
                request = self.applySorting(
                    to: request,
                    type: filters.sortType,
                    direction: filters.sortDirection
                )
                
                return try request.fetchAll(db)
            }
            .publisher(
                in: database,
                scheduling: .async(onQueue: .global(qos: .userInitiated))
            )
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
}

// MARK: - Library Filtering Helpers

private extension MangaLocalDataSource {
    func applyCollectionFilter(
        to request: QueryInterfaceRequest<Domain.Models.Virtual.Entry>,
        collectionId: Int64,
        db: Database
    ) throws -> QueryInterfaceRequest<Domain.Models.Virtual.Entry> {
        // Validate collection exists
        guard try Domain.Models.Persistence.Collection.fetchOne(db, key: collectionId) != nil else {
            throw Domain.Models.Persistence.CollectionError.notFound(collectionId)
        }
        
        return request.filter(sql: """
            mangaId IN (
                SELECT mc.mangaId 
                FROM mangaCollection mc 
                WHERE mc.collectionId = ?
            )
        """, arguments: [collectionId])
    }
    
    func applyDateFilter(
        to request: QueryInterfaceRequest<Domain.Models.Virtual.Entry>,
        column: Column,
        date: Domain.Models.Presentation.LibraryDate
    ) -> QueryInterfaceRequest<Domain.Models.Virtual.Entry> {
        switch date {
        case .none:
            return request
        case .before(let date):
            return request.filter(column <= date)
        case .after(let date):
            return request.filter(column >= date)
        case .between(let start, let end):
            return request.filter(column >= start && column <= end)
        }
    }
    
    func applyPublishStatusFilter(
        to request: QueryInterfaceRequest<Domain.Models.Virtual.Entry>,
        statuses: [Domain.Models.Enums.PublishStatus]
    ) -> QueryInterfaceRequest<Domain.Models.Virtual.Entry> {
        guard !statuses.isEmpty else { return request }
        
        let statusValues = statuses.map { $0.rawValue }
        
        let sql: SQL = """
            mangaId IN (
                SELECT DISTINCT o.mangaId
                FROM origin o
                WHERE o.status IN \(statusValues)
                AND o.priority = (
                    SELECT MIN(o2.priority)
                    FROM origin o2
                    WHERE o2.mangaId = o.mangaId
                )
            )
        """
        
        return request.filter(sql)
    }
    
    func applyClassificationFilter(
        to request: QueryInterfaceRequest<Domain.Models.Virtual.Entry>,
        classifications: [Domain.Models.Enums.Classification]
    ) -> QueryInterfaceRequest<Domain.Models.Virtual.Entry> {
        guard !classifications.isEmpty else { return request }
        
        let classificationValues = classifications.map { $0.rawValue }
        
        let sql: SQL = """
            mangaId IN (
                SELECT DISTINCT o.mangaId
                FROM origin o
                WHERE o.classification IN \(classificationValues)
                AND o.priority = (
                    SELECT MIN(o2.priority)
                    FROM origin o2
                    WHERE o2.mangaId = o.mangaId
                )
            )
        """
        
        return request.filter(sql)
    }
    
    func applySearchFilter(
        to request: QueryInterfaceRequest<Domain.Models.Virtual.Entry>,
        search: String,
        db: Database
    ) throws -> QueryInterfaceRequest<Domain.Models.Virtual.Entry> {
        // Create FTS5 search pattern
        guard let pattern = FTS5Pattern(matchingAllPrefixesIn: search) else {
            // If pattern creation fails, return no results
            return request.filter(sql: "0 = 1")
        }
        
        // Search in both main titles and alternative titles
        return request.filter(sql: """
            mangaId IN (
                SELECT rowid FROM manga_title_fts WHERE manga_title_fts MATCH ?
                UNION
                SELECT DISTINCT mangaId FROM manga_alttitle_fts WHERE manga_alttitle_fts MATCH ?
            )
        """, arguments: [pattern, pattern])
    }
    
    func applySorting(
        to request: QueryInterfaceRequest<Domain.Models.Virtual.Entry>,
        type: Domain.Models.Presentation.LibrarySortType,
        direction: Domain.Models.Presentation.LibrarySortDirection
    ) -> QueryInterfaceRequest<Domain.Models.Virtual.Entry> {
        let isAscending = direction == .ascending
        
        switch type {
        case .title:
            // For title, reverse the typical order (descending = A-Z)
            return request.order(
                isAscending ?
                Domain.Models.Virtual.Entry.Columns.title.desc :
                    Domain.Models.Virtual.Entry.Columns.title.asc
            )
            
        case .added:
            return request.order(
                isAscending ?
                Domain.Models.Virtual.Entry.Columns.addedAt.asc :
                    Domain.Models.Virtual.Entry.Columns.addedAt.desc
            )
            
        case .updated:
            return request.order(
                isAscending ?
                Domain.Models.Virtual.Entry.Columns.updatedAt.asc :
                    Domain.Models.Virtual.Entry.Columns.updatedAt.desc
            )
            
        case .read:
            // Handle nullable lastReadAt - nulls should be last
            if isAscending {
                return request.order(
                    Domain.Models.Virtual.Entry.Columns.lastReadAt.ascNullsLast
                )
            } else {
                return request.order(
                    Domain.Models.Virtual.Entry.Columns.lastReadAt.desc
                )
            }
        }
    }
}

// MARK: - Tag Filtering (TODO)

private extension MangaLocalDataSource {
    // TODO: Implement tag filtering when LibraryTag support is added
    /*
     func applyTagFilter(
     to request: QueryInterfaceRequest<Domain.Models.Virtual.Entry>,
     tags: [Domain.Models.Presentation.LibraryTag]
     ) -> QueryInterfaceRequest<Domain.Models.Virtual.Entry> {
     guard !tags.isEmpty else { return request }
     
     let includeTags = tags.filter { $0.inclusionType == .include }
     let excludeTags = tags.filter { $0.inclusionType == .exclude }
     
     var result = request
     
     // Apply include filters
     if !includeTags.isEmpty {
     let tagIds = includeTags.map { $0.tag.id! }
     result = result.filter(sql: """
     mangaId IN (
     SELECT DISTINCT mt.mangaId
     FROM mangaTag mt
     WHERE mt.tagId IN \(tagIds)
     )
     """)
     }
     
     // Apply exclude filters
     if !excludeTags.isEmpty {
     let tagIds = excludeTags.map { $0.tag.id! }
     result = result.filter(sql: """
     mangaId NOT IN (
     SELECT DISTINCT mt.mangaId
     FROM mangaTag mt
     WHERE mt.tagId IN \(tagIds)
     )
     """)
     }
     
     return result
     }
     */
}

// MARK: - Manga Details

internal extension MangaLocalDataSource {
    /// Fetches detailed manga information for the given entry.
    ///
    /// Searches by manga ID first for exact matches, then falls back to title matching.
    /// Returns all matching manga with their complete details including:
    /// - Metadata (titles, authors, covers, tags)
    /// - Organization (collections, origins)
    /// - Content (chapters filtered by user preferences)
    ///
    /// - Parameter entry: The entry to fetch details for
    /// - Returns: Publisher emitting arrays of matching manga details
    /// NOTE - we return an array in case of duplicate matches (i.e. two of same title but different content)
    /// when this occurs it would be resolved in presentation layer
    func getMangaDetails(entry: Domain.Models.Virtual.Entry) -> AnyPublisher<[Domain.Models.Virtual.Details], Error> {
        return ValueObservation.tracking { [weak self] db -> [Details] in
            guard let self = self else { return [] }
            
            // try id match first
            if let mangaId = entry.mangaId,
               let manga = try Domain.Models.Persistence.Manga.fetchOne(db, key: mangaId),
               let detail = try self.buildDetail(for: manga, db: db) {
                return [detail]
            }
            
            // fallback to title matching
            return try self.findByTitle(entry.title, db: db)
                .compactMap { manga in
                    try self.buildDetail(for: manga, db: db)
                }
        }
        .publisher(in: database, scheduling: .async(onQueue: .main))
        .eraseToAnyPublisher()
    }
}

private extension MangaLocalDataSource {
    func findByTitle(_ title: String, db: Database) throws -> [Domain.Models.Persistence.Manga] {
        // create search pattern
        guard let pattern = FTS5Pattern(matchingAllPrefixesIn: title) else {
            return []
        }
        
        var foundIds = Set<Int64>()
        var results: [Domain.Models.Persistence.Manga] = []
        
        // search main titles using FTS5
        let mainTitleIds = try Int64.fetchAll(
            db,
            sql: """
                SELECT rowid 
                FROM \(MangaTitleFTS5.databaseTableName) 
                WHERE \(MangaTitleFTS5.databaseTableName) MATCH ?
            """,
            arguments: [pattern]
        )
        
        // fetch manga for main title matches
        if !mainTitleIds.isEmpty {
            let mainMatches = try Domain.Models.Persistence.Manga
                .filter(mainTitleIds.contains(Domain.Models.Persistence.Manga.Columns.id))
                .fetchAll(db)
            
            for manga in mainMatches {
                if let id = manga.id {
                    results.append(manga)
                    foundIds.insert(id)
                }
            }
        }
        
        // search alternative titles using FTS5
        let altTitleMangaIds = try Int64.fetchAll(
            db,
            sql: """
                SELECT DISTINCT mangaId 
                FROM \(MangaAltTitleFTS5.databaseTableName) 
                WHERE \(MangaAltTitleFTS5.databaseTableName) MATCH ?
            """,
            arguments: [pattern]
        )
        
        // fetch manga for alt title matches (excluding already found)
        if !altTitleMangaIds.isEmpty {
            let altMatches = try Domain.Models.Persistence.Manga
                .filter(altTitleMangaIds.contains(Domain.Models.Persistence.Manga.Columns.id))
                .filter(!foundIds.contains(Domain.Models.Persistence.Manga.Columns.id))
                .fetchAll(db)
            
            for manga in altMatches {
                if manga.id != nil {
                    results.append(manga)
                }
            }
        }
        
        return results
    }
    
    func buildDetail(for manga: Domain.Models.Persistence.Manga, db: Database) throws -> Details? {
        guard manga.id != nil else { return nil }
        
        // fetch all related data
        let titles = try manga.titles.fetchAll(db)
        let authors = try manga.authors.fetchAll(db)
        let covers = try manga.covers.fetchAll(db)
        let tags = try manga.tags.fetchAll(db)
        let collections = try manga.collections.fetchAll(db)
        
        // complex relations
        let sources = try buildSourceInfos(for: manga, db: db)
        let chapters = try buildChapterInfos(for: manga, db: db)
        
        return Details(
            manga: manga,
            titles: titles,
            authors: authors,
            covers: covers,
            tags: tags,
            collections: collections,
            sources: sources,
            chapters: chapters
        )
    }
    
    func buildSourceInfos(for manga: Domain.Models.Persistence.Manga, db: Database) throws -> [Details.SourceInfo] {
        let origins = try manga.origins
            .order(Domain.Models.Persistence.Origin.Columns.priority.asc)
            .fetchAll(db)
        
        return try origins.map { origin in
            let source = try origin.source.fetchOne(db)
            let host = try source?.host.fetchOne(db)
            let scanlators = try buildScanlatorInfos(for: origin, db: db)
            
            return Details.SourceInfo(
                origin: origin,
                source: source,
                host: host,
                scanlators: scanlators
            )
        }
    }
    
    func buildScanlatorInfos(for origin: Domain.Models.Persistence.Origin, db: Database) throws -> [Details.ScanlatorInfo] {
        guard let originId = origin.id else { return [] }
        
        let channels = try Domain.Models.Persistence.Channel
            .filter(Domain.Models.Persistence.Channel.Columns.originId == originId)
            .order(Domain.Models.Persistence.Channel.Columns.priority.asc)
            .fetchAll(db)
        
        return try channels.compactMap { channel -> Details.ScanlatorInfo? in
            guard let scanlator = try Domain.Models.Persistence.Scanlator
                .fetchOne(db, key: channel.scanlatorId) else { return nil }
            
            return Details.ScanlatorInfo(
                scanlator: scanlator,
                priority: channel.priority
            )
        }
    }
    
    func buildChapterInfos(for manga: Domain.Models.Persistence.Manga, db: Database) throws -> [Details.ChapterInfo] {
        // using best chapters view to get unified list
        let chapters = try manga.chapters.fetchAll(db)
        
        return try chapters.compactMap { chapter -> Details.ChapterInfo? in
            guard
                let origin = try Domain.Models.Persistence.Origin.fetchOne(db, key: chapter.originId),
                let scanlator = try Domain.Models.Persistence.Scanlator.fetchOne(db, key: chapter.scanlatorId)
            else { return nil }
            
            let source = try origin.source.fetchOne(db)
            let host = try source?.host.fetchOne(db)
            
            return Details.ChapterInfo(
                chapter: chapter,
                scanlator: scanlator,
                origin: origin,
                source: source,
                host: host
            )
        }
    }
}

// MARK: - Library Operations
// TODO: Add library operations here

// MARK: - Metadata Updates
// TODO: Add cover, orientation, collection updates here

// MARK: - Priority Management
// TODO: Add origin and scanlator priority updates here

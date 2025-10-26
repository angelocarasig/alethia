//
//  GetLibraryMangaUseCaseImpl.swift
//  Data
//
//  Created by Angelo Carasig on 11/10/2025.
//

import Foundation
import Domain
import GRDB

public final class GetLibraryMangaUseCaseImpl: GetLibraryMangaUseCase {
    private let repository: LibraryRepository
    private let database: DatabaseConfiguration
    
    public init(repository: LibraryRepository) {
        self.repository = repository
        self.database = DatabaseConfiguration.shared
    }
    
    public func execute(query: LibraryQuery) -> AsyncStream<Result<LibraryQueryResult, Error>> {
        AsyncStream { continuation in
            let observation = ValueObservation.tracking { [weak self] db -> LibraryQueryResult in
                guard let self else {
                    return LibraryQueryResult.empty()
                }
                
                do {
                    return try self.buildQueryResult(query, db: db)
                } catch let error as StorageError {
                    throw error
                } catch {
                    throw StorageError.queryFailed(sql: "getLibraryManga", error: error)
                }
            }
            
            let task = Task { [weak self] in
                guard let self else { return }
                
                do {
                    for try await result in observation.values(in: self.database.reader) {
                        if Task.isCancelled { break }
                        continuation.yield(.success(result))
                    }
                } catch {
                    continuation.yield(.failure(self.mapError(error)))
                }
                continuation.finish()
            }
            
            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }
    
    private func buildQueryResult(_ query: LibraryQuery, db: Database) throws -> LibraryQueryResult {
        // build base query for library entries (inLibrary = true)
        var request = try repository.createQuery(in: db)
        
        // apply filters
        request = try applyFilters(request, query: query, db: db)
        
        // get total count before sorting/pagination
        let totalCount = try repository.count(results: request, in: db)
        
        // exclude entries with null dates when sorting by those dates
        request = try excludeNullDatesForSort(request, sort: query.sort, db: db)
        
        // apply sorting
        request = try applySorting(request, sort: query.sort, db: db)
        
        // apply pagination
        if let cursor = query.cursor {
            if let afterId = cursor.afterId {
                request = try repository.apply(afterId: afterId, sort: query.sort, to: request, in: db)
            }
            // fetch limit+1 to determine if more exist
            request = try repository.apply(limit: cursor.limit + 1, to: request)
        } else {
            request = try repository.apply(limit: 51, to: request)
        }
        
        // fetch entries
        var entries: [Entry] = []
        var hasMore = false
        let limit = query.cursor?.limit ?? 50
        
        let cursor = try repository.createCursor(for: request, in: db)
        var count = 0
        
        // cast cursor to grdb cursor type
        guard let mangaCursor = cursor as? (any Cursor) else {
            throw StorageError.invalidCast(expected: "GRDB Cursor", actual: String(describing: type(of: cursor)))
        }
        
        // iterate through results
        while let manga = try mangaCursor.next() {
            count += 1
            if count <= limit {
                if let entryData = try repository.fetchEntryData(manga: manga, in: db) {
                    entries.append(try mapToEntry(entryData))
                }
            } else {
                hasMore = true
                break
            }
        }
        
        // calculate next cursor
        let nextCursor = hasMore ? LibraryCursor(
            afterId: entries.last?.mangaId,
            limit: limit
        ) : nil
        
        return LibraryQueryResult(
            entries: entries,
            hasMore: hasMore,
            nextCursor: nextCursor,
            totalCount: totalCount
        )
    }
    
    // MARK: - Filter Application
    
    private func applyFilters(_ request: Any, query: LibraryQuery, db: Database) throws -> Any {
        var result = request
        let filters = query.filters
        
        // apply text search
        if let search = filters.search, !search.isEmpty {
            result = try repository.apply(search: search, to: result, in: db)
        }
        
        // apply collection filter
        if let collectionId = filters.collectionId {
            result = try repository.apply(collectionId: collectionId, to: result, in: db)
        }
        
        // apply source filter
        if !filters.sourceIds.isEmpty {
            result = try repository.apply(sourceIds: filters.sourceIds, to: result, in: db)
        }
        
        // apply status filter
        if !filters.statuses.isEmpty {
            result = try repository.apply(statuses: filters.statuses, to: result, in: db)
        }
        
        // apply classification filter
        if !filters.classifications.isEmpty {
            result = try repository.apply(classifications: filters.classifications, to: result, in: db)
        }
        
        // apply date filters
        if filters.addedDate.isActive {
            result = try repository.apply(dateFilter: filters.addedDate, column: "addedAt", to: result, in: db)
        }
        
        if filters.updatedDate.isActive {
            result = try repository.apply(dateFilter: filters.updatedDate, column: "updatedAt", to: result, in: db)
        }
        
        // apply content filters
        if filters.unreadOnly {
            result = try repository.applyUnreadOnly(to: result, in: db)
        }
        
        if filters.downloadedOnly {
            result = try repository.applyDownloadedOnly(to: result, in: db)
        }
        
        return result
    }
    
    // MARK: - Date Null Exclusion
    
    private func excludeNullDatesForSort(_ request: Any, sort: LibrarySort, db: Database) throws -> Any {
        // exclude entries with null dates when sorting by those dates
        // this ensures consistent pagination behavior
        switch sort.field {
        case .lastRead:
            // filter out entries that have never been read
            return try repository.apply(
                dateFilter: DateFilter.after(.distantPast),
                column: "lastReadAt",
                to: request,
                in: db
            )
            
        case .lastUpdated:
            // filter out entries that have never been updated
            return try repository.apply(
                dateFilter: DateFilter.after(.distantPast),
                column: "updatedAt",
                to: request,
                in: db
            )
            
        case .dateAdded:
            // filter out entries that don't have a proper added date
            return try repository.apply(
                dateFilter: DateFilter.after(.distantPast),
                column: "addedAt",
                to: request,
                in: db
            )
            
        default:
            // no filtering needed for other sort types
            return request
        }
    }
    
    // MARK: - Sort Application
    
    private func applySorting(_ request: Any, sort: LibrarySort, db: Database) throws -> Any {
        switch sort.field {
        case .alphabetical:
            return try repository.sort(byTitle: request, direction: sort.direction)
            
        case .lastRead:
            return try repository.sort(byLastRead: request, direction: sort.direction)
            
        case .lastUpdated:
            return try repository.sort(byLastUpdated: request, direction: sort.direction)
            
        case .dateAdded:
            return try repository.sort(byDateAdded: request, direction: sort.direction)
            
        case .unreadCount:
            return try repository.sort(byUnreadCount: request, direction: sort.direction, in: db)
            
        case .chapterCount:
            return try repository.sort(byChapterCount: request, direction: sort.direction, in: db)
        }
    }
    
    // MARK: - Mapping
    
    private func mapToEntry(_ data: LibraryEntryData) throws -> Entry {
        // cast to concrete types
        guard let manga = data.manga as? MangaRecord else {
            throw SystemError.mappingFailed(reason: "Invalid manga record type")
        }
        
        guard let mangaId = manga.id else {
            throw SystemError.mappingFailed(reason: "Manga ID is nil")
        }
        
        guard let cover = data.cover as? CoverRecord else {
            throw SystemError.mappingFailed(reason: "Invalid cover record type")
        }
        
        guard let origin = data.primaryOrigin as? OriginRecord else {
            throw SystemError.mappingFailed(reason: "Invalid origin record type")
        }
        
        return Entry(
            mangaId: mangaId.rawValue,
            sourceId: origin.sourceId?.rawValue,
            slug: origin.slug,
            title: manga.title,
            cover: cover.remotePath,
            state: .exactMatch,  // library entries are always exact matches
            unread: data.unreadCount
        )
    }
    
    // MARK: - Error Mapping
    
    private func mapError(_ error: Error) -> Error {
        if let domainError = error as? DomainError {
            return domainError
        } else if let storageError = error as? StorageError {
            return storageError.toDomainError()
        } else if let dbError = error as? DatabaseError {
            return StorageError.from(grdbError: dbError, context: "getLibraryManga").toDomainError()
        } else {
            return DataAccessError.storageFailure(
                reason: "Failed to fetch library entries",
                underlying: error
            )
        }
    }
}

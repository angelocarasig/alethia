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
    private let local: LibraryLocalDataSource
    
    public init() {
        self.local = LibraryLocalDataSourceImpl()
    }
    
    // MARK: - Public Interface
    
    public func getCollections() -> AsyncStream<Result<[Collection], any Error>> {
        AsyncStream { continuation in
            let task = Task {
                for await result in local.getLibraryCollections() {
                    if Task.isCancelled { break }
                    
                    let mappedResult = self.handleCollectionsResult(result)
                    continuation.yield(mappedResult)
                }
                continuation.finish()
            }
            
            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }
    
    public func getLibraryManga(query: LibraryQuery) -> AsyncStream<Result<LibraryQueryResult, Error>> {
        AsyncStream { continuation in
            let task = Task {
                for await result in local.getLibraryEntries(query: query) {
                    if Task.isCancelled { break }
                    
                    let mappedResult = self.handleLibraryEntriesResult(result, query: query)
                    continuation.yield(mappedResult)
                }
                continuation.finish()
            }
            
            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }
    
    public func findMatches(for raw: [Entry]) -> AsyncStream<Result<[Entry], Error>> {
        AsyncStream { continuation in
            // TODO: implement find matches logic
            continuation.finish()
        }
    }
}

// MARK: - Result Handling

private extension LibraryRepositoryImpl {
    func handleCollectionsResult(
        _ result: Result<[(CollectionRecord, Int)], Error>
    ) -> Result<[Collection], Error> {
        switch result {
        case .success(let collections):
            do {
                let mapped = try collections.map(mapToCollection)
                return .success(mapped)
            } catch let error as RepositoryError {
                return .failure(error.toDomainError())
            } catch {
                return .failure(SystemError.mappingFailed(reason: "Failed to map collections"))
            }
            
        case .failure(let error):
            return .failure(mapStorageError(error, context: "fetch collections"))
        }
    }
    
    func handleLibraryEntriesResult(
        _ result: Result<LibraryDataBundle, Error>,
        query: LibraryQuery
    ) -> Result<LibraryQueryResult, Error> {
        switch result {
        case .success(let bundle):
            let queryResult = mapToQueryResult(bundle, query: query)
            return .success(queryResult)
            
        case .failure(let error):
            return .failure(mapStorageError(error, context: "fetch library entries"))
        }
    }
}

// MARK: - Error Mapping

private extension LibraryRepositoryImpl {
    func mapStorageError(_ error: Error, context: String) -> DomainError {
        if let dbError = error as? DatabaseError {
            return RepositoryError.fromGRDB(dbError, context: context).toDomainError()
        } else if let storageError = error as? StorageError {
            return storageError.toDomainError()
        } else {
            return DataAccessError.storageFailure(
                reason: "Failed to \(context)",
                underlying: error
            )
        }
    }
}

// MARK: - Query Result Mapping

private extension LibraryRepositoryImpl {
    func mapToQueryResult(_ bundle: LibraryDataBundle, query: LibraryQuery) -> LibraryQueryResult {
        let entries = bundle.entries.compactMap { tuple in
            mapToEntry(
                manga: tuple.manga,
                cover: tuple.cover,
                unreadCount: tuple.unreadCount,
                primaryOrigin: tuple.primaryOrigin
            )
        }
        
        let nextCursor = calculateNextCursor(
            hasMore: bundle.hasMore,
            entries: entries,
            currentCursor: query.cursor
        )
        
        return LibraryQueryResult(
            entries: entries,
            hasMore: bundle.hasMore,
            nextCursor: nextCursor,
            totalCount: bundle.totalCount
        )
    }
    
    func calculateNextCursor(
        hasMore: Bool,
        entries: [Entry],
        currentCursor: LibraryCursor?
    ) -> LibraryCursor? {
        guard hasMore else { return nil }
        
        let limit = currentCursor?.limit ?? 50
        return LibraryCursor(
            afterId: entries.last?.mangaId,
            limit: limit
        )
    }
}

// MARK: - Entity Mapping

private extension LibraryRepositoryImpl {
    func mapToEntry(
        manga: MangaRecord,
        cover: CoverRecord,
        unreadCount: Int,
        primaryOrigin: OriginRecord
    ) -> Entry? {
        guard let mangaId = manga.id else { return nil }
        
        return Entry(
            mangaId: mangaId.rawValue,
            sourceId: primaryOrigin.sourceId?.rawValue,
            slug: primaryOrigin.slug,
            title: manga.title,
            cover: cover.remotePath,
            state: .fullMatch,
            unread: unreadCount
        )
    }
    
    func mapToCollection(record: CollectionRecord, count: Int) throws -> Collection {
        guard let recordId = record.id else {
            throw RepositoryError.mappingFailed(reason: "Collection ID is nil")
        }
        
        return Collection(
            id: recordId.rawValue,
            name: record.name,
            description: record.description ?? "",
            count: count,
            createdAt: record.createdAt,
            updatedAt: record.updatedAt
        )
    }
}

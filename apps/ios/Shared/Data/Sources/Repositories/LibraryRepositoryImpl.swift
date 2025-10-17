//
//  LibraryRepositoryImpl.swift
//  Data
//
//  Created by Angelo Carasig on 11/10/2025.
//

import Foundation
import Domain

public final class LibraryRepositoryImpl: LibraryRepository {
    private let local: LibraryLocalDataSource
    
    public init() {
        self.local = LibraryLocalDataSourceImpl()
    }
    
    public func getCollections() -> AsyncStream<Result<[Collection], any Error>> {
        AsyncStream { continuation in
            let task = Task {
                for await result in local.getLibraryCollections() {
                    if Task.isCancelled { break }
                    
                    switch result {
                    case .success(let collections):
                        try continuation.yield(.success(collections.map(mapToCollection) ))
                    case .failure(let error):
                        continuation.yield(.failure(error))
                    }
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
                    
                    switch result {
                    case .success(let bundle):
                        let queryResult = self.mapToQueryResult(bundle, query: query)
                        continuation.yield(.success(queryResult))
                        
                    case .failure(let error):
                        continuation.yield(.failure(error))
                    }
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
            // TODO: Implement find matches logic
            continuation.finish()
        }
    }
    
    // MARK: - Private Mapping Methods
    
    private func mapToQueryResult(_ bundle: LibraryDataBundle, query: LibraryQuery) -> LibraryQueryResult {
        let entries = bundle.entries.compactMap { (manga, cover, unreadCount, primaryOrigin) in
            mapToEntry(manga: manga, cover: cover, unreadCount: unreadCount, primaryOrigin: primaryOrigin)
        }
        
        // calculate next cursor if there are more items
        let nextCursor: LibraryCursor? = bundle.hasMore ?
        LibraryCursor(
            afterId: entries.last.flatMap { entry in entry.mangaId },
            limit: query.cursor?.limit ?? 50
        ) : nil
        
        return LibraryQueryResult(
            entries: entries,
            hasMore: bundle.hasMore,
            nextCursor: nextCursor,
            totalCount: bundle.totalCount
        )
    }
    
    private func mapToEntry(
        manga: MangaRecord,
        cover: CoverRecord,
        unreadCount: Int,
        primaryOrigin: OriginRecord
    ) -> Entry? {
        guard let mangaId = manga.id else { return nil }
        
        // use primary origin's slug
        let slug = primaryOrigin.slug
        
        // use cover's remote path
        let coverURL = cover.remotePath
        
        // get source id from primary origin
        let sourceId = primaryOrigin.sourceId?.rawValue
        
        return Entry(
            mangaId: mangaId.rawValue,
            sourceId: sourceId,
            slug: slug,
            title: manga.title,
            cover: coverURL,
            state: .fullMatch, // library entries are always full matches
            unread: unreadCount
        )
    }
    
    private func mapToCollection(record: CollectionRecord) throws -> Collection {
        guard let recordId = record.id else {
            throw RepositoryError.mappingError(reason: "Could not map CollectionRecord to Collection")
        }
        
        return Collection(
            id: recordId.rawValue,
            name: record.name,
            description: record.description ?? "",
            // TODO: Add count field
            count: 0,
            createdAt: record.createdAt,
            updatedAt: record.updatedAt
        )
    }
}

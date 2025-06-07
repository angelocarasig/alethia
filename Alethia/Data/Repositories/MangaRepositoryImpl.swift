//
//  MangaRepositoryImpl.swift
//  Alethia
//
//  Created by Angelo Carasig on 10/4/2025.
//

import Foundation
import Combine
import UIKit.UIApplication

final class MangaRepositoryImpl {
    private let local: MangaLocalDataSource
    private let remote: MangaRemoteDataSource
    private let actor: QueueActor
    
    init(local: MangaLocalDataSource, remote: MangaRemoteDataSource, actor: QueueActor) {
        self.local = local
        self.remote = remote
        self.actor = actor
    }
}

extension MangaRepositoryImpl: MangaRepository {
    func getLibrary(filters: LibraryFilters, collection: Int64?) -> AnyPublisher<[Entry], Error> {
        return local.getLibrary(filters: filters, collection: collection)
    }
    
    func getMangaDetail(entry: Entry) -> AnyPublisher<[Detail], Error> {
        return local.getMangaDetail(entry: entry)
            .flatMap { localDetail -> AnyPublisher<[Detail], Error> in
                // Return local detail immediately if available
                if !localDetail.isEmpty {
                    return Just(localDetail)
                        .setFailureType(to: Error.self)
                        .receive(on: DispatchQueue.main)
                        .eraseToAnyPublisher()
                }
                
                // Fetch from remote and persist
                return self.fetchAndPersistRemoteDetail(entry: entry)
                    .map { [$0] } // need to map to array
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
    
    func refreshMetadata(mangaId: Int64) -> AsyncStream<QueueOperationState> {
        AsyncStream { continuation in
            Task {
                let backgroundTask = await UIApplication.shared.beginBackgroundTask {
                    continuation.yield(.failed(DownloadError.backgroundTimeExpired))
                }
                
                await actor.refreshMetadata(mangaId: mangaId, continuation: continuation)
                continuation.finish()
                
                await MainActor.run {
                    UIApplication.shared.endBackgroundTask(backgroundTask)
                }
            }
        }
    }
    
    func addMangaToLibrary(mangaId: Int64, collections: [Int64]) throws {
        try local.addMangaToLibrary(mangaId: mangaId, collections: collections)
    }
    
    func removeMangaFromLibrary(mangaId: Int64) throws {
        try local.removeMangaFromLibrary(mangaId: mangaId)
    }
    
    func updateMangaOrientation(mangaId: Int64, newValue: Orientation) throws {
        try local.updateMangaOrientation(mangaId: mangaId, newValue: newValue)
    }
    
    func addMangaOrigin(entry: Entry, mangaId: Int64) async throws {
        // First in remote get new origin payload
        let payload: DetailDTO = try await remote.fetchMangaDetail(entry: entry)
        
        try local.addMangaOrigin(payload: payload, mangaId: mangaId, sourceId: entry.sourceId)
    }
    
    func getMangaRecommendations(mangaId: Int64) throws -> RecommendedEntries {
        return try local.getMangaRecommendations(mangaId: mangaId)
    }
    
    func resolveMangaOrientation(detail: Detail) -> Orientation {
        return local.resolveMangaOrientation(detail: detail)
    }
    
    func updateMangaCover(mangaId: Int64, coverId: Int64) throws {
        try local.updateMangaCover(mangaId: mangaId, coverId: coverId)
    }
    
    func updateMangaCollections(mangaId: Int64, collectionIds: [Int64]) throws {
        try local.updateMangaCollections(mangaId: mangaId, collectionIds: collectionIds)
    }
}

// MARK: Helpers

private extension MangaRepositoryImpl {
    func fetchAndPersistRemoteDetail(entry: Entry) -> AnyPublisher<Detail, Error> {
        return Future<DetailDTO, Error> { [weak self] (promise: @escaping (Result<DetailDTO, Error>) -> Void) in
            guard let self = self else {
                promise(.failure(ApplicationError.operationCancelled))
                return
            }
            
            Task {
                do {
                    let dto = try await self.remote.fetchMangaDetail(entry: entry)
                    promise(.success(dto))
                } catch {
                    promise(.failure(error))
                }
            }
        }
        .flatMap { dto in
            self.local.saveNewManga(payload: dto, with: entry.sourceId)
                .receive(on: DispatchQueue.main)
        }
        .eraseToAnyPublisher()
    }
}

//
//  MangaRepositoryImpl.swift
//  Alethia
//
//  Created by Angelo Carasig on 10/4/2025.
//

import Foundation
import Combine

final class MangaRepositoryImpl {
    private let local: MangaLocalDataSource
    private let remote: MangaRemoteDataSource
    
    init(local: MangaLocalDataSource, remote: MangaRemoteDataSource) {
        self.local = local
        self.remote = remote
    }
}

extension MangaRepositoryImpl: MangaRepository {
    func getLibrary(filters: LibraryFilters) -> AnyPublisher<[Entry], Error> {
        return local.getLibrary(filters: filters)
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
    
    func toggleMangaInLibrary(mangaId: Int64, newValue: Bool) throws -> Void {
        try local.toggleMangaInLibrary(mangaId: mangaId, newValue: newValue)
    }
    
    func updateMangaOrientation(mangaId: Int64, newValue: Orientation) throws {
        try local.updateMangaOrientation(mangaId: mangaId, newValue: newValue)
    }
    
    func getMangaRecommendations(mangaId: Int64) throws -> RecommendedEntries {
        return try local.getMangaRecommendations(mangaId: mangaId)
    }
    
    func resolveMangaOrientation(detail: Detail) -> Orientation {
        return local.resolveMangaOrientation(detail: detail)
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

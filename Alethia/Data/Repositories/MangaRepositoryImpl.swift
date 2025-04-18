//
//  MangaRepositoryImpl.swift
//  Alethia
//
//  Created by Angelo Carasig on 10/4/2025.
//

import Foundation
import Combine

// @unchecked Sendable
final class MangaRepositoryImpl {
    private let local: MangaLocalDataSource
    private let remote: MangaRemoteDataSource
    
    init(local: MangaLocalDataSource, remote: MangaRemoteDataSource) {
        self.local = local
        self.remote = remote
    }
}

extension MangaRepositoryImpl: MangaRepository {
    func getMangaDetail(entry: Entry) -> AnyPublisher<Detail, Error> {
        return local.getMangaDetail(entry: entry)
            .flatMap { localDetail -> AnyPublisher<Detail, Error> in
                // Return local detail immediately if available
                if let localDetail = localDetail {
                    return Just(localDetail)
                        .setFailureType(to: Error.self)
                        .receive(on: DispatchQueue.main)
                        .eraseToAnyPublisher()
                }
                
                // Fetch from remote and persist
                return self.fetchAndPersistRemoteDetail(entry: entry)
            }
            .eraseToAnyPublisher()
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

//
//  MangaRepositoryImpl.swift
//  Data
//
//  Created by Angelo Carasig on 14/6/2025.
//

import Domain
import Combine

fileprivate typealias MangaRepository = Domain.Repositories.MangaRepository

public extension Data.Repositories {
    final class MangaRepositoryImpl: MangaRepository {
        private let local: MangaLocalDataSource
        private let remote: Data.DataSources.MangaRemoteDataSource
        
        public init(
            local: Data.DataSources.MangaLocalDataSource,
            remote: Data.DataSources.MangaRemoteDataSource
        ) {
            self.local = local
            self.remote = remote
        }
        
        public func getLibrary(filters: Domain.Models.Presentation.LibraryFilters, collectionId: Int64?) -> AnyPublisher<[Domain.Models.Virtual.Entry], any Error> {
            return local.getLibrary(filters: filters, collectionId: collectionId)
        }
        
        public func addMangaToLibrary(mangaId: Int64, collectionIds: [Int64]) throws {
            fatalError("Not Implemented")
        }
        
        public func removeMangaFromLibrary(mangaId: Int64) throws {
            fatalError("Not Implemented")
        }
        
        public func getMangaDetails(entry: Domain.Models.Virtual.Entry) -> AnyPublisher<[Domain.Models.Virtual.Details], Error> {
            return local.getMangaDetails(entry: entry)
        }
        
        public func getMangaRecommendations(mangaId: Int64) throws {
            fatalError("Not Implemented")
        }
        
        public func refreshMetadata(mangaId: Int64) {
            fatalError("Not Implemented")
        }
        
        public func updateMangaCover(mangaId: Int64, coverId: Int64) throws {
            fatalError("Not Implemented")
        }
        
        public func updateMangaOrientation(mangaId: Int64, newValue: Domain.Models.Enums.Orientation) throws {
            fatalError("Not Implemented")
        }
        
        public func resolveMangaOrientation(mangaId: Int64) -> Domain.Models.Enums.Orientation {
            fatalError("Not Implemented")
        }
        
        public func updateMangaSettings(mangaId: Int64, showAllChapters: Bool?, showHalfChapters: Bool?) throws {
            fatalError("Not Implemented")
        }
        
        public func updateMangaCollections(mangaId: Int64, collectionIds: [Int64]) throws {
            fatalError("Not Implemented")
        }
        
        public func addMangaOrigin(entry: Domain.Models.Virtual.Entry, mangaId: Int64) async throws {
            fatalError("Not Implemented")
        }
        
        public func updateOriginPriorities(mangaId: Int64, newPriorities: [(originId: Int64, priority: Int)]) throws {
            fatalError("Not Implemented")
        }
        
        public func updateScanlatorPriorities(originId: Int64, newPriorities: [(scanlatorId: Int64, priority: Int)]) throws {
            fatalError("Not Implemented")
        }
    }
}

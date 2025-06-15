//
//  File.swift
//  Data
//
//  Created by Angelo Carasig on 14/6/2025.
//

import Domain
import Combine

fileprivate typealias MangaRepository = Domain.Repositories.MangaRepository

public extension Data.Repositories {
    final class MangaRepositoryImplement: MangaRepository {
        private let local: MangaLocalDataSource
        private let remote: MangaRemoteDataSource
        
        init(local: MangaLocalDataSource, remote: MangaRemoteDataSource) {
            self.local = local
            self.remote = remote
        }
        
        public func getLibrary(filters: Domain.Models.Presentation.LibraryFilters, collectionId: Int64?) -> AnyPublisher<[Domain.Models.Virtual.Entry], any Error> {
            <#code#>
        }
        
        public func addMangaToLibrary(mangaId: Int64, collectionIds: [Int64]) throws {
            <#code#>
        }
        
        public func removeMangaFromLibrary(mangaId: Int64) throws {
            <#code#>
        }
        
        public func getMangaDetails(entry: Domain.Models.Virtual.Entry) -> AnyPublisher<[Domain.Models.Virtual.Details], Error> {
            return local.getMangaDetails(entry: entry)
        }
        
        public func getMangaRecommendations(mangaId: Int64) throws {
            <#code#>
        }
        
        public func refreshMetadata(mangaId: Int64) {
            <#code#>
        }
        
        public func updateMangaCover(mangaId: Int64, coverId: Int64) throws {
            <#code#>
        }
        
        public func updateMangaOrientation(mangaId: Int64, newValue: Domain.Models.Enums.Orientation) throws {
            <#code#>
        }
        
        public func resolveMangaOrientation(mangaId: Int64) -> Domain.Models.Enums.Orientation {
            <#code#>
        }
        
        public func updateMangaSettings(mangaId: Int64, showAllChapters: Bool?, showHalfChapters: Bool?) throws {
            <#code#>
        }
        
        public func updateMangaCollections(mangaId: Int64, collectionIds: [Int64]) throws {
            <#code#>
        }
        
        public func addMangaOrigin(entry: Domain.Models.Virtual.Entry, mangaId: Int64) async throws {
            <#code#>
        }
        
        public func updateOriginPriorities(mangaId: Int64, newPriorities: [(originId: Int64, priority: Int)]) throws {
            <#code#>
        }
        
        public func updateScanlatorPriorities(originId: Int64, newPriorities: [(scanlatorId: Int64, priority: Int)]) throws {
            <#code#>
        }
    }
}

//
//  MangaRepository.swift
//  Alethia
//
//  Created by Angelo Carasig on 10/4/2025.
//

import Foundation
import Combine

protocol MangaRepository {
    func getLibrary(filters: LibraryFilters, collection: Int64?) -> AnyPublisher<[Entry], Error>
    
    // Returns array for view to handle when multiple matches are found
    func getMangaDetail(entry: Entry) -> AnyPublisher<[Detail], Error>
    
    func refreshMetadata(mangaId: Int64) -> AsyncStream<QueueOperationState>
    
    func addMangaToLibrary(mangaId: Int64, collections: [Int64]) throws -> Void
    
    func removeMangaFromLibrary(mangaId: Int64) throws -> Void
    
    func updateMangaOrientation(mangaId: Int64, newValue: Orientation) throws -> Void
    
    func addMangaOrigin(entry: Entry, mangaId: Int64) async throws -> Void
    
    func updateMangaCover(mangaId: Int64, coverId: Int64) throws -> Void
    
    func getMangaRecommendations(mangaId: Int64) throws -> RecommendedEntries
    
    func resolveMangaOrientation(detail: Detail) -> Orientation
    
    func updateMangaCollections(mangaId: Int64, collectionIds: [Int64]) throws -> Void
    
    func updateOriginPriorities(mangaId: Int64, newPriorities: [(originId: Int64, priority: Int)]) throws -> Void
    func updateScanlatorPriorities(originId: Int64, newPriorities: [(scanlatorId: Int64, priority: Int)]) throws -> Void
    func updateMangaSettings(mangaId: Int64, showAllChapters: Bool?, showHalfChapters: Bool?) throws -> Void
}

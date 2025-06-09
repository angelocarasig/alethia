//
//  MangaRepository.swift
//  Alethia
//
//  Created by Angelo Carasig on 10/4/2025.
//

import Foundation
import Combine

protocol MangaRepository {
    // MARK: - Library Operations
    
    /// Fetches library entries with optional filters and collection
    func getLibrary(filters: LibraryFilters, collection: Int64?) -> AnyPublisher<[Entry], Error>
    
    /// Adds manga to the user's library with specified collections
    func addMangaToLibrary(mangaId: Int64, collections: [Int64]) throws -> Void
    
    /// Removes manga from the user's library
    func removeMangaFromLibrary(mangaId: Int64) throws -> Void
    
    // MARK: - Manga Details
    
    /// Fetches manga details - returns array for view to handle when multiple matches are found
    func getMangaDetail(entry: Entry) -> AnyPublisher<[Detail], Error>
    
    /// Gets manga recommendations based on the specified manga
    func getMangaRecommendations(mangaId: Int64) throws -> RecommendedEntries
    
    // MARK: - Metadata Operations
    
    /// Refreshes metadata for the specified manga
    func refreshMetadata(mangaId: Int64) -> AsyncStream<QueueOperationState>
    
    /// Updates the cover image for the specified manga
    func updateMangaCover(mangaId: Int64, coverId: Int64) throws -> Void
    
    // MARK: - Reading Settings
    
    /// Updates the reading orientation for the specified manga
    func updateMangaOrientation(mangaId: Int64, newValue: Orientation) throws -> Void
    
    /// Resolves the effective reading orientation for the given manga detail
    func resolveMangaOrientation(detail: Detail) -> Orientation
    
    /// Updates manga display settings (show all chapters, show half chapters)
    func updateMangaSettings(mangaId: Int64, showAllChapters: Bool?, showHalfChapters: Bool?) throws -> Void
    
    // MARK: - Collection Management
    
    /// Updates the collections associated with the specified manga
    func updateMangaCollections(mangaId: Int64, collectionIds: [Int64]) throws -> Void
    
    // MARK: - Origin & Scanlator Management
    
    /// Adds a new origin to the specified manga
    func addMangaOrigin(entry: Entry, mangaId: Int64) async throws -> Void
    
    /// Updates the priority order of origins for the specified manga
    func updateOriginPriorities(mangaId: Int64, newPriorities: [(originId: Int64, priority: Int)]) throws -> Void
    
    /// Updates the priority order of scanlators for the specified origin
    func updateScanlatorPriorities(originId: Int64, newPriorities: [(scanlatorId: Int64, priority: Int)]) throws -> Void
}

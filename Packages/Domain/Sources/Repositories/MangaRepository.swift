//
//  MangaRepository.swift
//  Domain
//
//  Created by Angelo Carasig on 14/6/2025.
//

import Foundation
import Combine

public extension Domain.Repositories {
    /// Repository interface for manga-related data operations.
    ///
    /// Central repository for managing manga entities, their metadata, relationships,
    /// and user preferences. Handles both library management and content aggregation
    /// from multiple sources.
    ///
    /// ## Topics
    ///
    /// ### Library Management
    /// - ``getLibrary(filters:collectionId:)``
    /// - ``addMangaToLibrary(mangaId:collectionIds:)``
    /// - ``removeMangaFromLibrary(mangaId:)``
    ///
    /// ### Content & Metadata
    /// - ``getMangaDetail(entry:)``
    /// - ``updateMangaCover(mangaId:coverId:)``
    ///
    /// ### Reading Preferences
    /// - ``updateMangaOrientation(mangaId:newValue:)``
    /// - ``resolveMangaOrientation(mangaId:)``
    /// - ``updateMangaSettings(mangaId:showAllChapters:showHalfChapters:)``
    ///
    /// ### Organization
    /// - ``updateMangaCollections(mangaId:collectionIds:)``
    /// - ``updateOriginPriorities(mangaId:newPriorities:)``
    /// - ``updateScanlatorPriorities(originId:newPriorities:)``
    protocol MangaRepository {
        // MARK: - Library Operations
        
        /// Observes library entries with applied filters.
        ///
        /// Provides a reactive stream of library manga filtered by user preferences
        /// and optionally scoped to a specific collection.
        ///
        /// - Parameters:
        ///   - filters: Display and search filters to apply
        ///   - collectionId: Optional collection to scope results to
        /// - Returns: Publisher emitting filtered library entries, errors on database failures
        /// - Note: Emits updates when library contents change
        func getLibrary(filters: Domain.Models.Presentation.LibraryFilters, collectionId: Int64?) -> AnyPublisher<[Domain.Models.Virtual.Entry], Error>
        
        /// Adds a manga to the user's library.
        ///
        /// Sets the manga's `inLibrary` flag and associates it with specified collections
        /// in a single transaction.
        ///
        /// - Parameters:
        ///   - mangaId: The ID of the manga to add
        ///   - collectionIds: Array of collection IDs to add the manga to
        /// - Throws: Database error if manga doesn't exist or transaction fails
        /// - Important: Updates the manga's `addedAt` timestamp
        func addMangaToLibrary(mangaId: Int64, collectionIds: [Int64]) throws -> Void
        
        /// Removes a manga from the user's library.
        ///
        /// Clears the `inLibrary` flag and removes all collection associations.
        /// Downloaded chapters and reading progress are preserved.
        ///
        /// - Parameter mangaId: The ID of the manga to remove
        /// - Throws: Database error if manga doesn't exist
        /// - Note: Does not delete the manga, only removes from library
        func removeMangaFromLibrary(mangaId: Int64) throws -> Void
        
        // MARK: - Manga Details
        
        /// Fetches detailed information for a manga entry.
        ///
        /// Returns an array to handle cases where multiple manga match the entry
        /// (e.g., same title from different sources that aren't linked).
        ///
        /// - Parameter entry: The entry to fetch details for
        /// - Returns: Publisher emitting manga details array, typically contains one item
        /// - Note: Includes all related data: titles, authors, covers, origins, chapters
        func getMangaDetail(entry: Domain.Models.Virtual.Entry) -> AnyPublisher<[Domain.Models.Virtual.Details], Error>
        
        /// Gets personalized manga recommendations.
        ///
        /// - Parameter mangaId: The manga to base recommendations on
        /// - Returns: Recommendations grouped by similarity type
        /// - Warning: TODO - Not yet implemented
        func getMangaRecommendations(mangaId: Int64) throws -> Void
        
        // MARK: - Metadata Operations
        
        /// Refreshes metadata for a manga from its sources.
        ///
        /// Updates titles, authors, tags, covers, and chapter lists from
        /// all active origins.
        ///
        /// - Parameter mangaId: The ID of the manga to refresh
        /// - Returns: Stream of operation states for progress tracking
        /// - Warning: TODO - Requires queue operation implementation
        func refreshMetadata(mangaId: Int64) -> Void
        
        /// Sets the active cover for a manga.
        ///
        /// Deactivates the current cover and activates the specified one.
        /// Only one cover can be active at a time.
        ///
        /// - Parameters:
        ///   - mangaId: The ID of the manga
        ///   - coverId: The ID of the cover to activate
        /// - Throws: `CoverError.notFound` if cover doesn't belong to manga
        func updateMangaCover(mangaId: Int64, coverId: Int64) throws -> Void
        
        // MARK: - Reading Settings
        
        /// Updates the reading orientation preference.
        ///
        /// Changes how chapters are displayed in the reader.
        ///
        /// - Parameters:
        ///   - mangaId: The ID of the manga
        ///   - newValue: The orientation to set
        /// - Throws: Database error if update fails
        /// - Note: Use `.Default` to let the system infer orientation from tags
        func updateMangaOrientation(mangaId: Int64, newValue: Domain.Models.Enums.Orientation) throws -> Void
        
        /// Determines the effective reading orientation.
        ///
        /// Resolves `.Default` orientation to actual display mode based on
        /// manga tags (e.g., "Long Strip" → `.Vertical`).
        ///
        /// - Parameter mangaId: The ID of the manga
        /// - Returns: Resolved orientation for reader display
        func resolveMangaOrientation(mangaId: Int64) -> Domain.Models.Enums.Orientation
        
        /// Updates chapter display preferences.
        ///
        /// Controls which chapters appear in the unified chapter list.
        ///
        /// - Parameters:
        ///   - mangaId: The ID of the manga
        ///   - showAllChapters: When `true`, shows all chapters from all scanlators
        ///   - showHalfChapters: When `true`, includes non-integer chapters (e.g., 10.5)
        /// - Throws: Database error if update fails
        /// - Note: Pass `nil` to keep current value unchanged
        func updateMangaSettings(mangaId: Int64, showAllChapters: Bool?, showHalfChapters: Bool?) throws -> Void
        
        // MARK: - Collection Management
        
        /// Updates collection associations for a manga.
        ///
        /// Replaces all current collection associations with the provided set.
        ///
        /// - Parameters:
        ///   - mangaId: The ID of the manga
        ///   - collectionIds: Array of collection IDs (empty to remove from all)
        /// - Throws: Database error if collections don't exist
        func updateMangaCollections(mangaId: Int64, collectionIds: [Int64]) throws -> Void
        
        // MARK: - Origin & Scanlator Management
        
        /// Links a new source origin to an existing manga.
        ///
        /// Fetches metadata from the entry's source and creates an origin
        /// with the lowest priority (added last).
        ///
        /// - Parameters:
        ///   - entry: The source entry to link
        ///   - mangaId: The ID of the manga to link to
        /// - Throws: `OriginError.duplicate` if already linked
        /// - Note: Triggers metadata refresh for the new origin
        func addMangaOrigin(entry: Domain.Models.Virtual.Entry, mangaId: Int64) async throws -> Void
        
        /// Reorders origin priorities for chapter selection.
        ///
        /// Lower priority values take precedence when selecting chapters.
        /// Priorities must be unique within a manga.
        ///
        /// - Parameters:
        ///   - mangaId: The ID of the manga
        ///   - newPriorities: Array of origin ID and new priority pairs
        /// - Throws: Database error if priorities conflict
        /// - Example: `[(originId: 1, priority: 0), (originId: 2, priority: 1)]`
        func updateOriginPriorities(mangaId: Int64, newPriorities: [(originId: Int64, priority: Int)]) throws -> Void
        
        /// Reorders scanlator priorities for a specific origin.
        ///
        /// Controls which scanlator's version is preferred when multiple
        /// groups have the same chapter.
        ///
        /// - Parameters:
        ///   - originId: The ID of the origin
        ///   - newPriorities: Array of scanlator ID and new priority pairs
        /// - Throws: Database error if priorities conflict
        /// - Note: Only affects chapter selection within this origin
        func updateScanlatorPriorities(originId: Int64, newPriorities: [(scanlatorId: Int64, priority: Int)]) throws -> Void
    }
}

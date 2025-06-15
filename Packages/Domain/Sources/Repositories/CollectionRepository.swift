//
//  CollectionRepository.swift
//  Domain
//
//  Created by Angelo Carasig on 14/6/2025.
//

import Combine

public extension Domain.Repositories {
    /// Repository interface for collection management operations.
    ///
    /// Handles CRUD operations for collections and their relationships with manga.
    /// Collections allow users to organize their library with custom groups beyond
    /// simple addition/removal.
    ///
    /// ## Overview
    ///
    /// Collections support:
    /// - Custom names, colors, and icons
    /// - Many-to-many relationships with manga
    /// - User-defined ordering
    /// - Real-time updates via Combine publishers
    protocol CollectionRepository {
        
        /// Observes collections associated with a specific manga.
        ///
        /// Emits updates when collections are added/removed from the manga.
        ///
        /// - Parameter mangaId: The ID of the manga to observe collections for
        /// - Returns: Publisher emitting arrays of collections, errors on database failures
        func getCollections(mangaId: Int64) -> AnyPublisher<[Domain.Models.Persistence.Collection], Error>
        
        /// Observes all collections with their manga counts.
        ///
        /// Provides a live view of all collections including metadata like
        /// item counts for display in collection management screens.
        ///
        /// - Returns: Publisher emitting collection summaries, never fails
        func getAllCollections() -> AnyPublisher<[Domain.Models.Presentation.LibraryCollection], Never>
        
        /// Creates a new collection with the specified properties.
        ///
        /// Validates name uniqueness and length constraints before creation.
        ///
        /// - Parameters:
        ///   - name: Display name (must be unique, 3-20 characters)
        ///   - color: Hex color string (e.g., "#FF0000")
        ///   - icon: SF Symbol name for visual representation
        /// - Throws: `CollectionError.badName` if name is reserved,
        ///           `CollectionError.minimumLengthNotReached` if name too short,
        ///           `CollectionError.maximumLengthReached` if name too long
        func addCollection(name: String, color: String, icon: String) throws -> Void
        
        /// Updates an existing collection's properties.
        ///
        /// Allows modification of display properties while maintaining
        /// manga associations and ordering.
        ///
        /// - Parameters:
        ///   - collectionId: The ID of the collection to update
        ///   - newName: Updated display name (must remain unique)
        ///   - newIcon: Updated SF Symbol name
        ///   - newColor: Updated hex color string
        /// - Throws: `CollectionError.notFound` if collection doesn't exist,
        ///           validation errors for invalid properties
        func updateCollection(collectionId: Int64, newName: String, newIcon: String, newColor: String) throws -> Void
        
        /// Permanently removes a collection.
        ///
        /// Deletes the collection and all manga associations. This operation
        /// cannot be undone.
        ///
        /// - Parameter collectionId: The ID of the collection to delete
        /// - Throws: `CollectionError.notFound` if collection doesn't exist
        /// - Important: All manga remain in library but lose this collection association
        func deleteCollection(collectionId: Int64) throws -> Void
        
        /// Updates the display order for multiple collections.
        ///
        /// Allows reordering collections for custom arrangement in the UI.
        /// The ordering values must be unique across all collections.
        ///
        /// - Parameter collections: Dictionary mapping collection IDs to their new ordering values
        /// - Throws: Database error if unique ordering constraint is violated
        /// - Note: Use sequential integers (0, 1, 2...) for best results
        func updateCollectionOrder(collections: Dictionary<Int64, Int>) throws -> Void
    }
}

//
//  SourceRepository.swift
//  Domain
//
//  Created by Angelo Carasig on 14/6/2025.
//

import Combine

public extension Domain.Repositories {
    /// Repository interface for source and host management operations.
    ///
    /// Manages external content providers (hosts) and their sources, including
    /// discovery, configuration, and content fetching. Handles both administrative
    /// tasks (host management) and user-facing features (browsing, searching).
    ///
    /// ## Topics
    ///
    /// ### Host Management
    /// - ``getHosts()``
    /// - ``testHostUseCase(url:)``
    /// - ``createHost(payload:)``
    /// - ``deleteHost(hostId:)``
    ///
    /// ### Source Configuration
    /// - ``getSources()``
    /// - ``toggleSourcePinned(sourceId:newValue:)``
    /// - ``toggleSourceDisabled(sourceId:newValue:)``
    ///
    /// ### Content Discovery
    /// - ``searchSource(source:query:page:)``
    /// - ``getSourceRouteContent(sourceRouteId:page:)``
    /// - ``observeMatchEntries(entries:)``
    protocol SourceRepository {
        
        // MARK: - Host Management
        
        /// Observes all configured hosts in the system.
        ///
        /// Provides a live view of content provider configurations.
        ///
        /// - Returns: Publisher emitting host arrays, never fails
        /// - Note: Emits updates when hosts are added, modified, or removed
        func getHosts() -> AnyPublisher<[Domain.Models.Persistence.Host], Never>
        
        /// Tests a URL to discover host capabilities.
        ///
        /// Validates the URL points to a compatible API and extracts
        /// host metadata and available sources.
        ///
        /// - Parameter url: The base URL to test (e.g., "https://api.mangadex.org")
        /// - Returns: Payload containing discovered host information
        /// - Throws: `NetworkError.invalidURL` if URL is malformed,
        ///           `HostError.incompatible` if API version mismatch
        func testHostUseCase(url: String) async throws -> Domain.Models.Presentation.NewHostPayload
        
        /// Creates a new host with its sources.
        ///
        /// Validates the host configuration and persists all related
        /// sources and routes in a single transaction.
        ///
        /// - Parameter payload: Host configuration with sources
        /// - Throws: `HostError.duplicate` if baseUrl already exists,
        ///           validation errors for invalid data
        /// - Important: Enables all sources by default
        func createHost(payload: Domain.Models.Presentation.NewHostPayload) async throws -> Void
        
        /// Permanently removes a host and all its sources.
        ///
        /// Cascades deletion to all sources, routes, and origins.
        /// Manga remains but loses source associations.
        ///
        /// - Parameter hostId: The ID of the host to delete
        /// - Throws: `HostError.notFound` if host doesn't exist
        /// - Warning: This operation cannot be undone
        func deleteHost(hostId: Int64) throws -> Void
        
        // MARK: - Source Configuration
        
        /// Observes all sources organized by host.
        ///
        /// Provides hierarchical view of hosts → sources → routes
        /// for source management UI.
        ///
        /// - Returns: Publisher emitting source panel data, never fails
        /// - Note: Includes disabled sources for management purposes
        func getSources() -> AnyPublisher<[Domain.Models.Presentation.SourcePanel], Never>
        
        /// Toggles the pinned status of a source.
        ///
        /// Pinned sources appear at the top of source lists for
        /// quick access to frequently used sources.
        ///
        /// - Parameters:
        ///   - sourceId: The ID of the source to update
        ///   - newValue: `true` to pin, `false` to unpin
        /// - Throws: Database error if source doesn't exist
        func toggleSourcePinned(sourceId: Int64, newValue: Bool) throws -> Void
        
        /// Toggles the disabled status of a source.
        ///
        /// Disabled sources are hidden from browsing/search and their
        /// chapters don't appear in manga details.
        ///
        /// - Parameters:
        ///   - sourceId: The ID of the source to update
        ///   - newValue: `true` to disable, `false` to enable
        /// - Throws: Database error if source doesn't exist
        /// - Note: Existing manga/chapters remain but become inaccessible
        func toggleSourceDisabled(sourceId: Int64, newValue: Bool) throws -> Void
        
        // MARK: - Content Discovery
        
        /// Searches for manga on a specific source.
        ///
        /// Queries the source's search API with pagination support.
        ///
        /// - Parameters:
        ///   - source: The source to search
        ///   - query: Search terms (title, author, etc.)
        ///   - page: Page number for pagination (1-based)
        /// - Returns: Array of entries matching the search
        /// - Throws: `NetworkError` for connection issues,
        ///           `SourceError.disabled` if source is disabled
        func searchSource(source: Domain.Models.Persistence.Source, query: String, page: Int) async throws -> [Domain.Models.Virtual.Entry]
        
        /// Fetches content from a source route.
        ///
        /// Routes represent categories like "Latest", "Popular", etc.
        ///
        /// - Parameters:
        ///   - sourceRouteId: The ID of the route to fetch
        ///   - page: Page number for pagination (1-based)
        /// - Returns: Array of entries from the route
        /// - Throws: `NetworkError` for connection issues,
        ///           `SourceError.routeNotFound` if route deleted
        func getSourceRouteContent(sourceRouteId: Int64, page: Int) async throws -> [Domain.Models.Virtual.Entry]
        
        /// Observes library match state for entries.
        ///
        /// Updates entry match states (none/partial/exact) based on
        /// current library contents. Essential for paginated views to
        /// maintain correct states across all loaded pages.
        ///
        /// - Parameter entries: Entries to observe match states for
        /// - Returns: Publisher emitting entries with updated match states
        /// - Important: See inline documentation for pagination rationale
        ///
        /// ## Pagination Considerations
        ///
        /// While the repository pattern combines fetching and observation for simple cases,
        /// paginated views need to observe ALL loaded entries together, not just the current page.
        ///
        /// For example, if we load 3 pages of 15 entries each:
        /// - Page 1: Observe entries 1-15
        /// - Page 2: Need to observe entries 1-30 (not just 16-30)
        /// - Page 3: Need to observe entries 1-45 (not just 31-45)
        ///
        /// The repository's combined approach only observes the current page's entries,
        /// which would miss match state changes for previously loaded entries.
        /// By separating observation into its own method, paginated views can:
        /// 1. Accumulate entries across multiple pages
        /// 2. Re-observe the entire collection when new pages are added
        /// 3. Ensure all visible entries update when library changes occur
        ///
        /// This separation of concerns also makes the code clearer:
        /// - Fetching is about getting remote data
        /// - Observation is about reacting to local database changes
        func observeMatchEntries(entries: [Domain.Models.Virtual.Entry]) -> AnyPublisher<[Domain.Models.Virtual.Entry], Never>
    }
}

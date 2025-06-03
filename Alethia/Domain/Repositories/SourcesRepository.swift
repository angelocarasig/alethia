//
//  SourcesRepository.swift
//  Alethia
//
//  Created by Angelo Carasig on 18/4/2025.
//

import Foundation
import Combine

protocol SourcesRepository {
    func getHosts() -> AnyPublisher<[Host], Never>
    
    func getSources() -> AnyPublisher<[SourceMetadata], Never>
    
    func testHostUseCase(url: String) async throws -> NewHostPayload
    
    func createHost(payload: NewHostPayload) async throws -> Void
    
    func deleteHost(host: Host) throws -> Void
    
    func toggleSourcePinned(sourceId: Int64, newValue: Bool) throws -> Void
    
    func toggleSourceDisabled(sourceId: Int64, newValue: Bool) throws -> Void
    
    func searchSource(source: Source, query: String, page: Int) async throws -> [Entry]
    
    func getSourceRouteContent(sourceRouteId: Int64, page: Int) async throws -> [Entry]
    
    // Reason why we need a separate use-case just for observation:
    //
    // While the repository pattern combines fetching and observation for simple cases,
    // paginated views need to observe ALL loaded entries together, not just the current page.
    //
    // For example, if we load 3 pages of 15 entries each:
    // - Page 1: Observe entries 1-15
    // - Page 2: Need to observe entries 1-30 (not just 16-30)
    // - Page 3: Need to observe entries 1-45 (not just 31-45)
    //
    // The repository's combined approach only observes the current page's entries,
    // which would miss match state changes for previously loaded entries.
    // By separating observation into its own use case, paginated views can:
    // 1. Accumulate entries across multiple pages
    // 2. Re-observe the entire collection when new pages are added
    // 3. Ensure all visible entries update when library changes occur
    //
    // This separation of concerns also makes the code clearer:
    // - Fetching is about getting remote data
    // - Observation is about reacting to local database changes
    func observeMatchEntries(entries: [Entry]) -> AnyPublisher<[Entry], Never>
}

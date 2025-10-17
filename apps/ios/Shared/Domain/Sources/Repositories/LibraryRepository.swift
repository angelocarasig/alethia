//
//  LibraryRepository.swift
//  Domain
//
//  Created by Angelo Carasig on 5/10/2025.
//

public protocol LibraryRepository: Sendable {
    /// Fetches all collections
    func getCollections() -> AsyncStream<Result<[Collection], Error>>
    
    /// Fetches all entries in the user's library
    func getLibraryManga(query: LibraryQuery) -> AsyncStream<Result<LibraryQueryResult, Error>>
    
    /// From an array of Entries return a stream of enriched entries based on match values
    func findMatches(for raw: [Entry]) -> AsyncStream<Result<[Entry], Error>>
}

//
//  SearchWithPresetUseCase.swift
//  Domain
//
//  Created by Angelo Carasig on 5/10/2025.
//

import Foundation

public protocol SearchWithPresetUseCase: Sendable {
    /// perform a search using a search preset
    /// - parameters:
    ///   - source: the source to search
    ///   - preset: the preset configuration to use
    ///   - page: page number (default: 1)
    ///   - limit: results per page (default: constants.search.defaultpagesize)
    /// - returns: search query result with entries and pagination info
    func execute(
        source: Source,
        preset: SearchPreset,
        page: Int,
        limit: Int
    ) async throws -> SearchQueryResult
}

// MARK: - Default Parameter Convenience

public extension SearchWithPresetUseCase {
    /// perform a simple search with default pagination
    func execute(
        source: Source,
        preset: SearchPreset
    ) async throws -> [Entry] {
        let result = try await execute(
            source: source,
            preset: preset,
            page: 1,
            limit: Constants.Search.defaultPageSize
        )
        return result.entries
    }
}

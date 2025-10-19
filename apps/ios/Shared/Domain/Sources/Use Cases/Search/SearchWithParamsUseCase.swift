//
//  SearchWithParamsUseCase.swift
//  Domain
//
//  Created by Angelo Carasig on 19/10/2025.
//

import Foundation

public protocol SearchWithParamsUseCase: Sendable {
    /// perform a search with custom parameters
    /// - parameters:
    ///   - source: the source to search
    ///   - query: search query text
    ///   - sort: sort option
    ///   - direction: sort direction
    ///   - filters: optional filters to apply
    ///   - page: page number
    ///   - limit: results per page
    /// - returns: search query result with entries and pagination info
    func execute(
        source: Source,
        query: String,
        sort: Search.Options.Sort,
        direction: SortDirection,
        filters: [Search.Options.Filter: Search.Options.FilterValue]?,
        page: Int,
        limit: Int
    ) async throws -> SearchQueryResult
}

// MARK: - Default Parameter Convenience

public extension SearchWithParamsUseCase {
    /// perform a search with minimal parameters
    func execute(
        source: Source,
        query: String,
        sort: Search.Options.Sort,
        direction: SortDirection
    ) async throws -> [Entry] {
        let result = try await execute(
            source: source,
            query: query,
            sort: sort,
            direction: direction,
            filters: nil,
            page: 1,
            limit: Constants.Search.defaultPageSize
        )
        return result.entries
    }
}

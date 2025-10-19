//
//  SearchWithParamsUseCaseImpl.swift
//  Data
//
//  Created by Angelo Carasig on 19/10/2025.
//

import Foundation
import Domain

public final class SearchWithParamsUseCaseImpl: SearchWithParamsUseCase {
    private let repository: SearchRepository
    
    public init(repository: SearchRepository) {
        self.repository = repository
    }
    
    public func execute(
        source: Source,
        query: String,
        sort: Search.Options.Sort,
        direction: SortDirection,
        filters: [Search.Options.Filter: Search.Options.FilterValue]?,
        page: Int,
        limit: Int
    ) async throws -> SearchQueryResult {
        // validate pagination parameters
        guard page > 0 else {
            throw BusinessError.invalidInput(reason: "Page must be greater than 0")
        }
        
        guard limit > 0 && limit <= Constants.Search.maxResults else {
            throw BusinessError.invalidInput(reason: "Limit must be between 1 and \(Constants.Search.maxResults)")
        }
        
        // build search request dto from parameters
        let request = SearchRequestDTO(
            query: query,
            page: page,
            limit: limit,
            sort: sort,
            direction: direction,
            filters: filters
        )
        
        return try await repository.search(
            source: source,
            request: request
        )
    }
}

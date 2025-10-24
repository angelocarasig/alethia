//
//  SearchWithPresetUseCaseImpl.swift
//  Data
//
//  Created by Angelo Carasig on 5/10/2025.
//

import Foundation
import Domain

public final class SearchWithPresetUseCaseImpl: SearchWithPresetUseCase {
    private let repository: SearchRepository
    
    public init(repository: SearchRepository) {
        self.repository = repository
    }
    
    public func execute(
        source: Source,
        preset: SearchPreset,
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
        
        return try await repository.searchWithPreset(
            source: source,
            preset: preset,
            page: page,
            limit: limit
        )
    }
}

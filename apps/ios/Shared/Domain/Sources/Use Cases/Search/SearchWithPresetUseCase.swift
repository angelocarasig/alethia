//
//  SearchWithPresetUseCase.swift
//  Domain
//
//  Created by Angelo Carasig on 5/10/2025.
//

import Foundation

public protocol SearchWithPresetUseCase: Sendable {
    /// Perform a search using a search preset to return an array of raw entries
    func execute(source: Source, preset: SearchPreset) async throws -> [Entry]
    
    /// Perform a paginated search using a search preset
    func execute(source: Source, preset: SearchPreset, page: Int, limit: Int) async throws -> SearchQueryResult
}

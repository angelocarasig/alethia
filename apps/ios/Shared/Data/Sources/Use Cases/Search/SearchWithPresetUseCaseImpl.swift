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
    
    public func execute(source: Source, preset: SearchPreset) async throws -> [Entry] {
        try await repository.searchWithPreset(source: source, preset: preset)
    }
}

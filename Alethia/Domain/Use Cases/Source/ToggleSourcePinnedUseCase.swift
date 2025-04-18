//
//  ToggleSourcePinnedUseCase.swift
//  Alethia
//
//  Created by Angelo Carasig on 18/4/2025.
//

import Foundation

protocol ToggleSourcePinnedUseCase {
    func execute(sourceId: Int64, newValue: Bool) throws -> Void
}

final class ToggleSourcePinnedUseCaseImpl: ToggleSourcePinnedUseCase {
    private var repository: SourcesRepository
    
    init(repository: SourcesRepository) {
        self.repository = repository
    }
    
    func execute(sourceId: Int64, newValue: Bool) throws -> Void {
        try repository.toggleSourcePinned(sourceId: sourceId, newValue: newValue)
    }
}

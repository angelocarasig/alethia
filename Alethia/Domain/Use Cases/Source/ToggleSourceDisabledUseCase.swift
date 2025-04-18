//
//  ToggleSourceDisabledUseCase.swift
//  Alethia
//
//  Created by Angelo Carasig on 18/4/2025.
//

import Foundation

protocol ToggleSourceDisabledUseCase {
    func execute(sourceId: Int64, newValue: Bool) throws -> Void
}

final class ToggleSourceDisabledUseCaseImpl: ToggleSourceDisabledUseCase {
    private var repository: SourcesRepository
    
    init(repository: SourcesRepository) {
        self.repository = repository
    }
    
    func execute(sourceId: Int64, newValue: Bool) throws -> Void {
        try repository.toggleSourceDisabled(sourceId: sourceId, newValue: newValue)
    }
}

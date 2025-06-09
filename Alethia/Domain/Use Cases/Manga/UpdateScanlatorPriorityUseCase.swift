//
//  UpdateScanlatorPriorityUseCase.swift
//  Alethia
//
//  Created by Angelo Carasig on 9/6/2025.
//

import Foundation

protocol UpdateScanlatorPriorityUseCase {
    func execute(originId: Int64, newPriorities: [(scanlatorId: Int64, priority: Int)]) throws -> Void
}

final class UpdateScanlatorPriorityUseCaseImpl: UpdateScanlatorPriorityUseCase {
    private let repository: MangaRepository
    
    init(repository: MangaRepository) {
        self.repository = repository
    }
    
    func execute(originId: Int64, newPriorities: [(scanlatorId: Int64, priority: Int)]) throws {
        try repository.updateScanlatorPriorities(originId: originId, newPriorities: newPriorities)
    }
}

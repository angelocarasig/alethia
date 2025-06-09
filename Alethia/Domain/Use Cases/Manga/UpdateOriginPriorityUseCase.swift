//
//  UpdateOriginPriorityUseCase.swift
//  Alethia
//
//  Created by Angelo Carasig on 9/6/2025.
//

import Foundation

protocol UpdateOriginPriorityUseCase {
    func execute(mangaId: Int64, newPriorities: [(originId: Int64, priority: Int)]) throws -> Void
}

final class UpdateOriginPriorityUseCaseImpl: UpdateOriginPriorityUseCase {
    private let repository: MangaRepository
    
    init(repository: MangaRepository) {
        self.repository = repository
    }
    
    func execute(mangaId: Int64, newPriorities: [(originId: Int64, priority: Int)]) throws {
        try repository.updateOriginPriorities(mangaId: mangaId, newPriorities: newPriorities)
    }
}

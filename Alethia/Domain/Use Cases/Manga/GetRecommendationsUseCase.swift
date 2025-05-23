//
//  GetRecommendationsUseCase.swift
//  Alethia
//
//  Created by Angelo Carasig on 24/5/2025.
//

import Foundation

protocol GetRecommendationsUseCase {
    func execute(mangaId: Int64) throws -> RecommendedEntries
}

final class GetRecommendationsUseCaseImpl: GetRecommendationsUseCase {
    private let repository: MangaRepository
    
    init(repository: MangaRepository) {
        self.repository = repository
    }
    
    func execute(mangaId: Int64) throws -> RecommendedEntries {
        return try repository.getMangaRecommendations(mangaId: mangaId)
    }
}

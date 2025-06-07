//
//  UpdateMangaCollectionsUseCase.swift
//  Alethia
//
//  Created by Angelo Carasig on 6/6/2025.
//

import Foundation

protocol UpdateMangaCollectionsUseCase {
    func execute(mangaId: Int64, collectionIds: [Int64]) throws -> Void
}

final class UpdateMangaCollectionsUseCaseImpl: UpdateMangaCollectionsUseCase {
    private let repository: MangaRepository
    
    init(repository: MangaRepository) {
        self.repository = repository
    }
    
    func execute(mangaId: Int64, collectionIds: [Int64]) throws {
        try repository.updateMangaCollections(mangaId: mangaId, collectionIds: collectionIds)
    }
}

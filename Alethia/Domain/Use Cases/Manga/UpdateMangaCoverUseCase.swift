//
//  UpdateMangaCoverUseCase.swift
//  Alethia
//
//  Created by Angelo Carasig on 30/5/2025.
//

import Foundation

protocol UpdateMangaCoverUseCase {
    func execute(mangaId: Int64, coverId: Int64) throws -> Void
}

final class UpdateMangaCoverUseCaseImpl: UpdateMangaCoverUseCase {
    private let repository: MangaRepository
    
    init(repository: MangaRepository) {
        self.repository = repository
    }
    
    func execute(mangaId: Int64, coverId: Int64) throws -> Void {
        try repository.updateMangaCover(mangaId: mangaId, coverId: coverId)
    }
}

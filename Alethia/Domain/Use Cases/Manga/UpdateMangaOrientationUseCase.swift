//
//  UpdateMangaOrientationUseCase.swift
//  Alethia
//
//  Created by Angelo Carasig on 25/5/2025.
//

import Foundation

protocol UpdateMangaOrientationUseCase {
    func execute(mangaId: Int64, orientation: Orientation) throws -> Void
}

final class UpdateMangaOrientationUseCaseImpl: UpdateMangaOrientationUseCase {
    private let repository: MangaRepository
    
    init(repository: MangaRepository) {
        self.repository = repository
    }
    
    func execute(mangaId: Int64, orientation: Orientation) throws -> Void {
        try repository.updateMangaOrientation(mangaId: mangaId, newValue: orientation)
    }
}

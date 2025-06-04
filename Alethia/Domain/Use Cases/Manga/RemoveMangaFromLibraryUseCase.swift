//
//  RemoveMangaFromLibraryUseCase.swift
//  Alethia
//
//  Created by Angelo Carasig on 4/6/2025.
//

import Foundation

protocol RemoveMangaFromLibraryUseCase {
    func execute(mangaId: Int64) throws -> Void
}

final class RemoveMangaFromLibraryUseCaseImpl: RemoveMangaFromLibraryUseCase {
    private let repository: MangaRepository
    
    init(repository: MangaRepository) {
        self.repository = repository
    }
    
    func execute(mangaId: Int64) throws {
        try repository.removeMangaFromLibrary(mangaId: mangaId)
    }
}

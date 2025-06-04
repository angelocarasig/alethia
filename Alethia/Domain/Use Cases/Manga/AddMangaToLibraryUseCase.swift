//
//  AddMangaToLibraryUseCase.swift
//  Alethia
//
//  Created by Angelo Carasig on 4/6/2025.
//

import Foundation

protocol AddMangaToLibraryUseCase {
    func execute(mangaId: Int64, collections: [Int64]) throws -> Void
}

final class AddMangaToLibraryUseCaseImpl: AddMangaToLibraryUseCase {
    private let repository: MangaRepository
    
    init(repository: MangaRepository) {
        self.repository = repository
    }
    
    func execute(mangaId: Int64, collections: [Int64]) throws {
        try repository.addMangaToLibrary(mangaId: mangaId, collections: collections)
    }
}

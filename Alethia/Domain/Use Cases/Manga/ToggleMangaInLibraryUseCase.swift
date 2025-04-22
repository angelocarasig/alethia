//
//  ToggleMangaInLibraryUseCase.swift
//  Alethia
//
//  Created by Angelo Carasig on 23/4/2025.
//

import Foundation

protocol ToggleMangaInLibraryUseCase {
    func execute(mangaId: Int64, newValue: Bool) throws -> Void
}

final class ToggleMangaInLibraryUserCaseImpl: ToggleMangaInLibraryUseCase {
    private var repository: MangaRepository
    
    init(repository: MangaRepository) {
        self.repository = repository
    }
    
    func execute(mangaId: Int64, newValue: Bool) throws -> Void {
        try self.repository.toggleMangaInLibrary(mangaId: mangaId, newValue: newValue)
    }
}

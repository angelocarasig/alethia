//
//  AddMangaOriginUseCase.swift
//  Alethia
//
//  Created by Angelo Carasig on 25/5/2025.
//

import Foundation

protocol AddMangaOriginUseCase {
    func execute(entry: Entry, mangaId: Int64) async throws
}

final class AddMangaOriginUseCaseImpl: AddMangaOriginUseCase {
    private let repository: MangaRepository
    
    init(repository: MangaRepository) {
        self.repository = repository
    }
    
    func execute(entry: Entry, mangaId: Int64) async throws {
        try await repository.addMangaOrigin(entry: entry, mangaId: mangaId)
    }
}

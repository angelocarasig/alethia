//
//  AddMangaToLibraryUseCaseImpl.swift
//  Data
//
//  Created by Angelo Carasig on 18/10/2025.
//

import Domain

public final class AddMangaToLibraryUseCaseImpl: AddMangaToLibraryUseCase {
    private let repository: LibraryRepository
    
    public init(repository: LibraryRepository) {
        self.repository = repository
    }
    
    public func execute(mangaId: Int64) async throws {
        try await repository.addMangaToLibrary(mangaId: mangaId)
    }
}

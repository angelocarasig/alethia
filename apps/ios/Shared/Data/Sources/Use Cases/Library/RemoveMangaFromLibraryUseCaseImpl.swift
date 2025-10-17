//
//  RemoveMangaFromLibraryUseCaseImpl.swift
//  Data
//
//  Created by Angelo Carasig on 18/10/2025.
//

import Domain

public final class RemoveMangaFromLibraryUseCaseImpl: RemoveMangaFromLibraryUseCase {
    private let repository: LibraryRepository
    
    public init(repository: LibraryRepository) {
        self.repository = repository
    }
    
    public func execute(mangaId: Int64) async throws {
        try await repository.removeMangaFromLibrary(mangaId: mangaId)
    }
}

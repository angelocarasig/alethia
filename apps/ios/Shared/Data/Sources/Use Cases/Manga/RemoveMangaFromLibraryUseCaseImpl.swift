//
//  RemoveMangaFromLibraryUseCaseImpl.swift
//  Data
//
//  Created by Angelo Carasig on 18/10/2025.
//

import Domain

public final class RemoveMangaFromLibraryUseCaseImpl: RemoveMangaFromLibraryUseCase {
    private let repository: MangaRepository
    private let database: DatabaseConfiguration
    
    public init(repository: MangaRepository) {
        self.repository = repository
        self.database = DatabaseConfiguration.shared
    }
    
    public func execute(mangaId: Int64) async throws {
        try await database.writer.write { db in
            let fields: MangaUpdateFields = .init(inLibrary: false)
            
            try repository.update(mangaId: mangaId, fields: fields, in: db)
        }
    }
}

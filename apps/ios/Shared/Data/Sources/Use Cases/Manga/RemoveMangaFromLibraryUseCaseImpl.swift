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
        #warning("Update in mange repository impl")
        try await DatabaseConfiguration.shared.writer.write { db in
            let record = try MangaRecord.fetchOne(db, key: MangaRecord.ID(rawValue: mangaId))
            
            if var record = record {
                record.inLibrary = false
                record.addedAt = .distantPast
                
                try record.save(db)
            }
        }
    }
}

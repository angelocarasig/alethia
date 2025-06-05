//
//  RefreshMetadataUseCase.swift
//  Alethia
//
//  Created by Angelo Carasig on 5/6/2025.
//

import Foundation

protocol RefreshMetadataUseCase {
    func execute(mangaId: Int64) -> AsyncStream<QueueOperationState>
}

final class RefreshMetadataUseCaseImpl: RefreshMetadataUseCase {
    private let repository: MangaRepository
    
    init(repository: MangaRepository) {
        self.repository = repository
    }
    
    func execute(mangaId: Int64) -> AsyncStream<QueueOperationState> {
        return repository.refreshMetadata(mangaId: mangaId)
    }
}

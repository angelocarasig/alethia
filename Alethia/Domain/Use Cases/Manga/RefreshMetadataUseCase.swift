//
//  RefreshMetadataUseCase.swift
//  Alethia
//
//  Created by Angelo Carasig on 5/6/2025.
//

import Foundation

protocol RefreshMetadataUseCase {
    func execute(manga: Manga) -> AsyncStream<QueueOperationState>
}

final class RefreshMetadataUseCaseImpl: RefreshMetadataUseCase {
    private let repository: MangaRepository
    
    init(repository: MangaRepository) {
        self.repository = repository
    }
    
    func execute(manga: Manga) -> AsyncStream<QueueOperationState> {
        return repository.refreshMetadata(manga: manga)
    }
}

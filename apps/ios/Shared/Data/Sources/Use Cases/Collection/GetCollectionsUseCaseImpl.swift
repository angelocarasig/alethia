//
//  GetCollectionsUseCaseImpl.swift
//  Data
//
//  Created by Angelo Carasig on 17/10/2025.
//

import Domain

public final class GetCollectionsUseCaseImpl: GetCollectionsUseCase {
    private let repository: LibraryRepository
    
    public init(repository: LibraryRepository) {
        self.repository = repository
    }
    
    public func execute() -> AsyncStream<Result<[Domain.Collection], any Error>> {
        return repository.getCollections()
    }
}

//
//  DeleteCollectionUseCase.swift
//  Alethia
//
//  Created by Angelo Carasig on 9/6/2025.
//

import Foundation

protocol DeleteCollectionUseCase {
    func execute(collectionId: Int64) throws -> Void
}

final class DeleteCollectionUseCaseImpl: DeleteCollectionUseCase {
    let repository: CollectionRepository
    
    init(repository: CollectionRepository) {
        self.repository = repository
    }
    
    func execute(collectionId: Int64) throws {
        try repository.deleteCollection(collectionId: collectionId)
    }
}

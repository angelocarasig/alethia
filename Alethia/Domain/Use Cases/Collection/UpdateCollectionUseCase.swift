//
//  UpdateCollectionUseCase.swift
//  Alethia
//
//  Created by Angelo Carasig on 9/6/2025.
//

import Foundation

protocol UpdateCollectionUseCase {
    func execute(collectionId: Int64, newName: String, newIcon: String, newColor: String) throws -> Void
}

final class UpdateCollectionUseCaseImpl: UpdateCollectionUseCase {
    private let repository: CollectionRepository
    
    init(repository: CollectionRepository) {
        self.repository = repository
    }
    
    func execute(collectionId: Int64, newName: String, newIcon: String, newColor: String) throws {
        try repository.updateCollection(collectionId: collectionId, newName: newName, newIcon: newIcon, newColor: newColor)
    }
}

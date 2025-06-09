//
//  UpdateCollectionOrderUseCase.swift
//  Alethia
//
//  Created by Angelo Carasig on 9/6/2025.
//

import Foundation

protocol UpdateCollectionOrderUseCase {
    func execute(collections: [Int64: Int]) throws -> Void
}

final class UpdateCollectionOrderUseCaseImpl: UpdateCollectionOrderUseCase {
    private let repository: CollectionRepository
    
    init(repository: CollectionRepository) {
        self.repository = repository
    }
    
    func execute(collections: [Int64: Int]) throws -> Void {
        try repository.updateCollectionOrder(collections: collections)
    }
}

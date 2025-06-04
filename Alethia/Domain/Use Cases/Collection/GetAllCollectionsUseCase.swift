//
//  GetAllCollections.swift
//  Alethia
//
//  Created by Angelo Carasig on 4/6/2025.
//

import Foundation
import Combine

protocol GetAllCollectionsUseCase {
    func execute() -> AnyPublisher<[CollectionExtended], Never>
}

final class GetAllCollectionsUseCaseImpl: GetAllCollectionsUseCase {
    private let repository: CollectionRepository
    
    init(repository: CollectionRepository) {
        self.repository = repository
    }
    
    func execute() -> AnyPublisher<[CollectionExtended], Never> {
        return repository.getAllCollections()
    }
}

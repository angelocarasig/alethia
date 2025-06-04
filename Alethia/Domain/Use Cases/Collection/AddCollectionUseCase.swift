//
//  AddCollectionUseCase.swift
//  Alethia
//
//  Created by Angelo Carasig on 4/6/2025.
//

import Foundation

protocol AddCollectionUseCase {
    func execute(name: String, color: String, icon: String) throws -> Void
}

final class AddCollectionUseCaseImpl: AddCollectionUseCase {
    private let repository: CollectionRepository
    
    init(repository: CollectionRepository) {
        self.repository = repository
    }
    
    func execute(name: String, color: String, icon: String) throws -> Void {
        try repository.addCollection(name: name, color: color, icon: icon)
    }
}

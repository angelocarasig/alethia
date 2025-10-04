//
//  UseCaseFactory.swift
//  Composition
//
//  Created by Angelo Carasig on 4/10/2025.
//

import Foundation
import Domain
import Data

/// Factory for creating use case instances
internal final class UseCaseFactory {
    private let repositoryFactory: RepositoryFactory
    
    init(repositoryFactory: RepositoryFactory) {
        self.repositoryFactory = repositoryFactory
    }
}

// MARK: - Hosts Use Cases
extension UseCaseFactory {
    func makeValidateHostURLUseCase() -> ValidateHostURLUseCase {
        ValidateHostURLUseCaseImpl(repository: repositoryFactory.hostRepository)
    }
    
    func makeSaveHostUseCase() -> SaveHostUseCase {
        SaveHostUseCaseImpl(repository: repositoryFactory.hostRepository)
    }
}

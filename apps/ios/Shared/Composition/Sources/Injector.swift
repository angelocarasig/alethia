//
//  Injector.swift
//  Composition
//
//  Created by Angelo Carasig on 4/10/2025.
//

import Foundation
import Domain
import Data

public enum Injector {
    nonisolated(unsafe) private static let repositoryFactory: RepositoryFactory = {
        let database = DatabaseConfiguration.shared
        return RepositoryFactory(database: database)
    }()
    
    nonisolated(unsafe) private static let useCaseFactory: UseCaseFactory = {
        UseCaseFactory(repositoryFactory: repositoryFactory)
    }()
}

// MARK: Host Use-Cases
public extension Injector {
    static func makeValidateHostURLUseCase() -> ValidateHostURLUseCase {
        useCaseFactory.makeValidateHostURLUseCase()
    }
    
    static func makeSaveHostUseCase() -> SaveHostUseCase {
        useCaseFactory.makeSaveHostUseCase()
    }
    
    static func makeGetAllHostsUseCase() -> GetAllHostsUseCase {
        useCaseFactory.makeGetAllhostsUseCase()
    }
}

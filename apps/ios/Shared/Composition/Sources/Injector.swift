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

// MARK: Search Use-Cases
public extension Injector {
    static func makeSearchWithPresetUseCase() -> SearchWithPresetUseCase {
        useCaseFactory.makeSearchWithPresetUseCase()
    }
}

// MARK: Library Use-Cases
public extension Injector {
    static func makeFindMatchesUseCase() -> FindMatchesUseCase {
        useCaseFactory.makeFindMatchesUseCase()
    }
    
    static func makeGetLibraryMangaUseCase() -> GetLibraryMangaUseCase {
        useCaseFactory.makeGetLibraryMangaUseCase()
    }
    
    static func makeGetCollectionsUseCase() -> GetCollectionsUseCase {
        useCaseFactory.makeGetCollectionsUseCase()
    }
}

// MARK: Manga Use-Cases
public extension Injector {
    static func makeGetMangaDetailsUseCase() -> GetMangaDetailsUseCase {
        useCaseFactory.makeGetMangaDetailsUseCase()
    }
}

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
    
    func makeGetAllhostsUseCase() -> GetAllHostsUseCase {
        GetAllHostsUseCaseImpl(repository: repositoryFactory.hostRepository)
    }
}

// MARK: - Search Use Cases
extension UseCaseFactory {
    func makeSearchWithPresetUseCase() -> SearchWithPresetUseCase {
        SearchWithPresetUseCaseImpl(repository: repositoryFactory.searchRepository)
    }
}

// MARK: - Library Use Cases
extension UseCaseFactory {
    func makeFindMatchesUseCase() -> FindMatchesUseCase {
        FindMatchesUseCaseImpl(repository: repositoryFactory.libraryRepository)
    }
    
    func makeGetLibraryMangaUseCase() -> GetLibraryMangaUseCase {
        GetLibraryMangaUseCaseImpl(repository: repositoryFactory.libraryRepository)
    }
}

// MARK: - Manga Use Cases
extension UseCaseFactory {
    func makeGetMangaDetailsUseCase() -> GetMangaDetailsUseCase {
        GetMangaDetailsUseCaseImpl(repository: repositoryFactory.mangaRepository)
    }
}

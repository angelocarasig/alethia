//
//  UseCaseFactory.swift
//  Composition
//
//  Created by Angelo Carasig on 14/6/2025.
//

import Foundation
import Domain

// MARK: - Use Case Factory
public extension Composition.Factory {
    /// Creates use case instances with injected repository dependencies
    final class UseCase {
        private init() {}
    }
}


// MARK: - Library Use Cases
public extension Composition.Factory.UseCase {
    static func makeGetLibraryUseCase() -> GetLibraryUseCase {
        let repository = Composition.Factory.Repository.makeMangaRepository()
        return GetLibraryUseCaseImpl(repository: repository)
    }
}

// MARK: - Manga Details Use Cases
public extension Composition.Factory.UseCase {
    static func makeGetMangaDetailsUseCase() -> GetMangaDetailsUseCase {
        let repository = Composition.Factory.Repository.makeMangaRepository()
        return GetMangaDetailsUseCaseImpl(repository: repository)
    }
}

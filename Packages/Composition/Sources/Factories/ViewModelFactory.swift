//
//  ViewModelFactory.swift
//  Composition
//
//  Created by Angelo Carasig on 14/6/2025.
//

import Domain
import Combine
import SwiftUI

// MARK: - View Model Factory
public extension Composition.Factory {
    /// Creates view model instances with injected use case dependencies
    final class ViewModel {
        private init() {}
    }
}

// MARK: - Library View Models
public extension Composition.Factory.ViewModel {
    static func makeLibraryViewModel() -> some LibraryViewModel {
        let getLibraryUseCase = Composition.Factory.UseCase.makeGetLibraryUseCase()
        return LibraryViewModelImpl(getLibraryUseCase: getLibraryUseCase)
    }
}

// MARK: - Manga Details View Models
public extension Composition.Factory.ViewModel {
    static func makeMangaDetailsViewModel(entry: Domain.Models.Virtual.Entry) -> some MangaDetailsViewModel {
        let getMangaDetailsUseCase = Composition.Factory.UseCase.makeGetMangaDetailsUseCase()
        
        return MangaDetailsViewModelImpl(
            entry: entry,
            getMangaDetailsUseCase: getMangaDetailsUseCase
        )
    }
}

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
    // MARK: - Database
    
    private static let database: DatabaseConfiguration = {
        DatabaseConfiguration.shared
    }()
    
    // MARK: - Repositories
    
    private static let hostRepository: HostRepository = {
        HostRepositoryImpl()
    }()
    
    private static let libraryRepository: LibraryRepository = {
        LibraryRepositoryImpl()
    }()
    
    private static let searchRepository: SearchRepository = {
        SearchRepositoryImpl()
    }()
    
    private static let mangaRepository: MangaRepository = {
        MangaRepositoryImpl()
    }()
    
    private static let chapterRepository: ChapterRepository = {
        ChapterRepositoryImpl()
    }()
}

// MARK: - Host Use Cases

public extension Injector {
    static func makeValidateHostURLUseCase() -> ValidateHostURLUseCase {
        ValidateHostURLUseCaseImpl(repository: hostRepository)
    }
    
    static func makeSaveHostUseCase() -> SaveHostUseCase {
        SaveHostUseCaseImpl(repository: hostRepository)
    }
    
    static func makeGetAllHostsUseCase() -> GetAllHostsUseCase {
        GetAllHostsUseCaseImpl(repository: hostRepository)
    }
}

// MARK: - Search Use Cases

public extension Injector {
    static func makeSearchWithPresetUseCase() -> SearchWithPresetUseCase {
        SearchWithPresetUseCaseImpl(repository: searchRepository)
    }
    
    static func makeSearchWithParamsUseCase() -> SearchWithParamsUseCase {
        SearchWithParamsUseCaseImpl(repository: searchRepository)
    }
}

// MARK: - Library Use Cases

public extension Injector {
    static func makeFindMatchesUseCase() -> FindMatchesUseCase {
        FindMatchesUseCaseImpl(repository: libraryRepository)
    }
    
    static func makeGetLibraryMangaUseCase() -> GetLibraryMangaUseCase {
        GetLibraryMangaUseCaseImpl(repository: libraryRepository)
    }
    
    static func makeGetCollectionsUseCase() -> GetCollectionsUseCase {
        GetCollectionsUseCaseImpl(repository: libraryRepository)
    }
    
    static func makeAddMangaToLibraryUseCase() -> AddMangaToLibraryUseCase {
        AddMangaToLibraryUseCaseImpl(repository: libraryRepository)
    }
    
    static func makeRemoveMangaFromLibraryUseCase() -> RemoveMangaFromLibraryUseCase {
        RemoveMangaFromLibraryUseCaseImpl(repository: libraryRepository)
    }
}

// MARK: - Manga Use Cases

public extension Injector {
    static func makeGetMangaDetailsUseCase() -> GetMangaDetailsUseCase {
        GetMangaDetailsUseCaseImpl(repository: mangaRepository)
    }
}

// MARK: - Chapter Use Cases

public extension Injector {
    static func makeGetChapterContentsUseCase() -> GetChapterContentsUseCase {
        GetChapterContentsUseCaseImpl(repository: chapterRepository)
    }
}

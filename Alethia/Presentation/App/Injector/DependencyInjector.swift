//
//  DependencyInjector.swift
//  Alethia
//
//  Created by Angelo Carasig on 11/4/2025.
//

import Foundation

final class DependencyInjector {
    static let shared: DependencyInjector = DependencyInjector()
    
    private init() {}
    
    private lazy var mangaRepository: MangaRepository = {
        let local = MangaLocalDataSource()
        let remote = MangaRemoteDataSource()
        
        return MangaRepositoryImpl(local: local, remote: remote)
    }()
    
    private lazy var sourcesRepository: SourcesRepository = {
        let local = SourceLocalDataSource()
        let remote = SourceRemoteDataSource()
        
        return SourcesRepositoryImpl(local: local, remote: remote)
    }()
}

// MARK: Manga

extension DependencyInjector {
    func makeGetMangaDetailUseCase() -> GetMangaDetailUseCase {
        return GetMangaDetailUseCaseImpl(repository: mangaRepository)
    }
}

// MARK: Sources

extension DependencyInjector {
    func makeGetSourcesUseCase() -> GetSourcesUseCase {
        return GetSourcesUseCaseImpl(repository: sourcesRepository)
    }
    
    func makeTestHostUrlUseCase() -> TestHostUseCase {
        return TestHostUseCaseImpl(repository: sourcesRepository)
    }
    
    func makeCreateHostUseCase() -> CreateHostUseCase {
        return CreateHostUseCaseImpl(repository: sourcesRepository)
    }
    
    func makeToggleSourcePinnedUseCase() -> ToggleSourcePinnedUseCase {
        return ToggleSourcePinnedUseCaseImpl(repository: sourcesRepository)
    }
    
    func makeToggleSourceDisabledUseCase() -> ToggleSourceDisabledUseCase {
        return ToggleSourceDisabledUseCaseImpl(repository: sourcesRepository)
    }
}

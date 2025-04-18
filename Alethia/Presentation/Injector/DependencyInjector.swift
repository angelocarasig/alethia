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
}

extension DependencyInjector {
    func makeGetMangaDetailUseCase() -> GetMangaDetailUseCase {
        return GetMangaDetailUseCaseImpl(repository: mangaRepository)
    }
}

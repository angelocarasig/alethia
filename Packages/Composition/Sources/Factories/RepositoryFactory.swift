//
//  RepositoryFactory.swift
//  Composition
//
//  Created by Angelo Carasig on 14/6/2025.
//

import Foundation
import Domain
import Data

// MARK: - Repository Factory
public extension Composition.Factory {
    /// Creates repository instances with properly configured data sources
    final class Repository {
        private init() {}
    }
}

// MARK: - Manga Repository
public extension Composition.Factory.Repository {
    static func makeMangaRepository() -> Domain.Repositories.MangaRepository {
        let local = Data.DataSources.MangaLocalDataSource()
        let remote = Data.DataSources.MangaRemoteDataSource()
        
        return Data.Repositories.MangaRepositoryImpl(
            local: local,
            remote: remote
        )
    }
}

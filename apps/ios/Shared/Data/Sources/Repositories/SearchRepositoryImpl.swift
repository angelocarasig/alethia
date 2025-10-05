//
//  SearchRepositoryImpl.swift
//  Data
//
//  Created by Angelo Carasig on 5/10/2025.
//

import Foundation
import Domain

public final class SearchRepositoryImpl: SearchRepository {
    private let remote: SearchRemoteDataSource
    private let local: SearchLocalDataSource
    
    public init(
        remote: SearchRemoteDataSource? = nil,
        local: SearchLocalDataSource? = nil
    ) {
        self.remote = remote ?? SearchRemoteDataSource()
        self.local = local ?? SearchLocalDataSource()
    }
    
    public func searchWithPreset(source: Source, preset: SearchPreset) async throws -> [Entry] {
        guard let host = try await local.getHostForSource(source.id) else {
            throw RepositoryError.hostNotFound
        }
        
        let entries = try await remote.searchWithPreset(
            sourceSlug: source.slug,
            host: host.url,
            preset: preset
        )
        
        return entries
    }
}

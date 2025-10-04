//
//  HostRepositoryImpl.swift
//  Data
//
//  Created by Angelo Carasig on 4/10/2025.
//

import Foundation
import Domain
import GRDB

public final class HostRepositoryImpl: HostRepository {
    private let remoteDataSource: HostRemoteDataSource
    private let localDataSource: HostLocalDataSource
    
    public init(
        remoteDataSource: HostRemoteDataSource? = nil,
        localDataSource: HostLocalDataSource? = nil
    ) {
        self.remoteDataSource = remoteDataSource ?? HostRemoteDataSource()
        self.localDataSource = localDataSource ?? HostLocalDataSource()
    }
    
    public func validateHost(url: URL) async throws -> HostManifest {
        // fetch manifest from remote
        let manifest = try await remoteDataSource.fetchManifest(from: url.trailingSlash(.remove))
        
        // check if host already exists by repository url
        if let (existingId, existingURL) = try await localDataSource.hostExists(with: manifest.repository) {
            throw RepositoryError.hostAlreadyExists(id: existingId, url: existingURL)
        }
        
        // repository handles validation of the fetched data
        guard !manifest.name.isEmpty else {
            throw RepositoryError.invalidManifest(reason: "Host name is empty")
        }
        
        guard !manifest.author.isEmpty else {
            throw RepositoryError.invalidManifest(reason: "Host author is empty")
        }
        
        guard !manifest.sources.isEmpty else {
            throw RepositoryError.invalidManifest(reason: "No sources found in manifest")
        }
        
        // validate each source has required fields
        for source in manifest.sources {
            guard !source.name.isEmpty else {
                throw RepositoryError.invalidManifest(reason: "Source name is empty")
            }
            
            guard !source.slug.isEmpty else {
                throw RepositoryError.invalidManifest(reason: "Source slug is empty")
            }
        }
        
        return manifest
    }
    
    public func saveHost(manifest: HostManifest, hostURL: URL) async throws -> Host {
        // delegate to local data source
        let (hostRecord, sourceRecords, configRecords, tagRecords) = try await localDataSource.saveHost(
            manifest: manifest,
            hostURL: hostURL
        )
        
        guard let hostId = hostRecord.id else {
            throw RepositoryError.mappingError(reason: "Host ID is nil")
        }
        
        // build host display name for sources
        let hostDisplayName = "@\(hostRecord.author)/\(hostRecord.name)"
        
        // map source records to domain sources
        let sources = try sourceRecords.enumerated().compactMap { index, sourceRecord -> Source? in
            guard let sourceId = sourceRecord.id else {
                throw RepositoryError.mappingError(reason: "Source ID is nil")
            }
            
            // get corresponding manifest source for complete data
            let manifestSource = manifest.sources[index]
            
            // find config for this source
            let config = configRecords.first { $0.sourceId == sourceId }
            
            // find tags for this source
            let sourceTags = tagRecords.filter { $0.sourceId == sourceId }
            
            // map tags
            let tags = sourceTags.map { SearchTag(
                slug: $0.slug,
                name: $0.name,
                nsfw: $0.nsfw
            )}
            
            // map auth
            let auth = mapAuthType(sourceRecord.authType)
            
            // build search object
            let search = Search(
                supportedSorts: config?.supportedSorts ?? manifestSource.search.sort,
                supportedFilters: config?.supportedFilters ?? manifestSource.search.filters,
                tags: tags,
                presets: []
            )
            
            return Source(
                id: sourceId.rawValue,
                slug: sourceRecord.slug,
                name: sourceRecord.name,
                icon: sourceRecord.icon,
                pinned: sourceRecord.pinned,
                disabled: sourceRecord.disabled,
                host: hostDisplayName,
                auth: auth,
                search: search
            )
        }
        
        return Host(
            id: hostId.rawValue,
            name: hostRecord.name,
            author: hostRecord.author,
            url: hostRecord.url,
            repository: hostRecord.repository,
            official: hostRecord.official,
            sources: sources
        )
    }
    
    public func getAllHosts() async throws -> [Host] {
        // implementation would go here
        return []
    }
    
    public func deleteHost(id: Int64) async throws {
        try await localDataSource.deleteHost(id: id)
    }
    
    // MARK: - Private Mapping Helpers
    
    private func mapAuthType(_ authType: AuthType?) -> Auth {
        guard let authType = authType else { return .none }
        
        switch authType {
        case .none:
            return .none
        case .basic:
            return .basic(fields: BasicAuthFields(username: "", password: ""))
        case .session:
            return .session(fields: SessionAuthFields(username: "", password: ""))
        case .apiKey:
            return .apiKey(fields: ApiKeyAuthFields(apiKey: ""))
        case .bearer:
            return .bearer(fields: BearerAuthFields(token: ""))
        case .cookie:
            return .cookie(fields: CookieAuthFields(cookie: ""))
        }
    }
}

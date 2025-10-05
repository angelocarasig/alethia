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
    private let remote: HostRemoteDataSource
    private let local: HostLocalDataSource
    
    public init(
        remote: HostRemoteDataSource? = nil,
        local: HostLocalDataSource? = nil
    ) {
        self.remote = remote ?? HostRemoteDataSource()
        self.local = local ?? HostLocalDataSource()
    }
    
    public func validateHost(url: URL) async throws -> HostManifest {
        // fetch manifest from remote
        let manifest = try await remote.fetchManifest(from: url.trailingSlash(.remove))
        
        // check if host already exists by repository url
        if let (existingId, existingURL) = try await local.hostExists(with: manifest.repository) {
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
        // delegate to local data source - now returns presets too
        let (hostRecord, sourceRecords, configRecords, tagRecords, presetRecords) = try await local.saveHost(
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
            
            // find presets for this source
            let sourcePresets = presetRecords.filter { $0.sourceId == sourceId }
            
            // map tags
            let tags = sourceTags.map { SearchTag(
                slug: $0.slug,
                name: $0.name,
                nsfw: $0.nsfw
            )}
            
            // map presets
            let presets = try sourcePresets.compactMap { presetRecord -> SearchPreset? in
                guard let presetId = presetRecord.id else { return nil }
                
                // decode the request from json data
                let decoder = JSONDecoder()
                let presetRequest = try decoder.decode(PresetRequest.self, from: presetRecord.request)
                
                // convert string keys to FilterOption enum and create FilterValue map
                let filters: [FilterOption: FilterValue]
                if let requestFilters = presetRequest.filters {
                    filters = requestFilters.compactMapKeys { FilterOption(rawValue: $0.rawValue) }
                } else {
                    filters = [:]
                }
                
                // convert string sort/direction to enums
                let sortOption = SortOption(rawValue: presetRequest.sort) ?? .relevance
                let sortDirection = presetRequest.direction == "asc" ? SortDirection.ascending : .descending
                
                return SearchPreset(
                    id: presetId.rawValue,
                    name: presetRecord.name,
                    filters: filters,
                    sortOption: sortOption,
                    sortDirection: sortDirection,
                )
            }
            
            // map auth
            let auth = mapAuthType(sourceRecord.authType)
            
            // build search object
            let search = Search(
                supportedSorts: config?.supportedSorts ?? manifestSource.search.sort,
                supportedFilters: config?.supportedFilters ?? manifestSource.search.filters,
                tags: tags,
                presets: presets
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
                search: search,
                presets: presets
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
    
    public func getAllHosts() -> AsyncStream<[Host]> {
        AsyncStream { continuation in
            // get the stream from data source
            let recordsStream = local.observeAllHosts()
            
            // create task to transform records to domain entities
            let task = Task {
                for await recordsData in recordsStream {
                    if Task.isCancelled { break }
                    
                    do {
                        let hosts = try self.mapRecordsToHosts(recordsData)
                        continuation.yield(hosts)
                    } catch {
                        // log error but continue stream
                        print("Error mapping hosts: \(error)")
                        // optionally yield empty array or previous state
                        continuation.yield([])
                    }
                }
                continuation.finish()
            }
            
            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }
    
    // MARK: - Private Mapping Helpers
    
    private func mapRecordsToHosts(_ recordsData: [(HostRecord, [(SourceRecord, SearchConfigRecord?, [SearchTagRecord], [SearchPresetRecord])])]) throws -> [Host] {
        try recordsData.map { (hostRecord, sourcesData) in
            guard let hostId = hostRecord.id else {
                throw RepositoryError.mappingError(reason: "Host ID is nil")
            }
            
            let hostDisplayName = "@\(hostRecord.author)/\(hostRecord.name)"
            
            let sources = try sourcesData.compactMap { (sourceRecord, configRecord, tagRecords, presetRecords) -> Source? in
                guard let sourceId = sourceRecord.id else {
                    throw RepositoryError.mappingError(reason: "Source ID is nil")
                }
                
                // map tags
                let tags = tagRecords.map { SearchTag(
                    slug: $0.slug,
                    name: $0.name,
                    nsfw: $0.nsfw
                )}
                
                // map presets
                let presets = try presetRecords.compactMap { presetRecord -> SearchPreset? in
                    guard let presetId = presetRecord.id else { return nil }
                    
                    // decode the request from json data
                    let decoder = JSONDecoder()
                    let presetRequest = try decoder.decode(PresetRequest.self, from: presetRecord.request)
                    
                    // convert string keys to FilterOption enum and create FilterValue map
                    let filters: [FilterOption: FilterValue]
                    if let requestFilters = presetRequest.filters {
                        filters = requestFilters.compactMapKeys { FilterOption(rawValue: $0.rawValue) }
                    } else {
                        filters = [:]
                    }
                    
                    // convert string sort/direction to enums
                    let sortOption = SortOption(rawValue: presetRequest.sort) ?? .relevance
                    let sortDirection = presetRequest.direction == "asc" ? SortDirection.ascending : .descending
                    
                    return SearchPreset(
                        id: presetId.rawValue,
                        name: presetRecord.name,
                        filters: filters,
                        sortOption: sortOption,
                        sortDirection: sortDirection,
                    )
                }
                
                // map auth
                let auth = mapAuthType(sourceRecord.authType)
                
                // build search object
                let search = Search(
                    supportedSorts: configRecord?.supportedSorts ?? [],
                    supportedFilters: configRecord?.supportedFilters ?? [],
                    tags: tags,
                    presets: presets
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
                    search: search,
                    presets: presets
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
    }
    
    public func deleteHost(id: Int64) async throws {
        try await local.deleteHost(id: id)
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

// helper extension for dictionary key mapping
private extension Dictionary {
    func compactMapKeys<T: Hashable>(_ transform: (Key) -> T?) -> [T: Value] {
        var result = [T: Value]()
        for (key, value) in self {
            if let newKey = transform(key) {
                result[newKey] = value
            }
        }
        return result
    }
}

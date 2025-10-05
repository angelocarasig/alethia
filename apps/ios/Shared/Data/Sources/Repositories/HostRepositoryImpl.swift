//
//  HostRepositoryImpl.swift
//  Data
//
//  Created by Angelo Carasig on 5/10/2025.
//

import Foundation
import Domain
import GRDB

public final class HostRepositoryImpl: HostRepository {
    private let remoteDataSource: HostRemoteDataSource
    private let localDataSource: HostLocalDataSource
    
    public init() {
        self.remoteDataSource = HostRemoteDataSourceImpl()
        self.localDataSource = HostLocalDataSourceImpl()
    }
    
    public func validateHost(url: URL) async throws -> HostDTO {
        let dto = try await remoteDataSource.fetchManifest(from: url.trailingSlash(.remove))
        
        // check if already exists
        if let (_, repositoryURL) = try await localDataSource.hostExists(with: dto.repository) {
            throw RepositoryError.hostAlreadyExists(
                id: HostRecord.ID(rawValue: 0), // temporary
                url: repositoryURL
            )
        }
        
        // validate
        guard !dto.name.isEmpty else {
            throw RepositoryError.invalidManifest(reason: "Host name is empty")
        }
        
        guard !dto.author.isEmpty else {
            throw RepositoryError.invalidManifest(reason: "Host author is empty")
        }
        
        guard !dto.sources.isEmpty else {
            throw RepositoryError.invalidManifest(reason: "No sources found in manifest")
        }
        
        for source in dto.sources {
            guard !source.name.isEmpty else {
                throw RepositoryError.invalidManifest(reason: "Source name is empty")
            }
            
            guard !source.slug.isEmpty else {
                throw RepositoryError.invalidManifest(reason: "Source slug is empty")
            }
        }
        
        return dto
    }
    
    public func saveHost(_ dto: HostDTO, hostURL: URL) async throws -> Host {
        let (hostRecord, sourceRecords, configRecords, tagRecords, presetRecords) = try await localDataSource.saveHost(dto, hostURL: hostURL)
        
        return try mapToHost(
            hostRecord: hostRecord,
            sourceRecords: sourceRecords,
            configRecords: configRecords,
            tagRecords: tagRecords,
            presetRecords: presetRecords
        )
    }
    
    public func getAllHosts() -> AsyncStream<[Host]> {
        AsyncStream { continuation in
            let recordsStream = localDataSource.observeAllHosts()
            
            let task = Task {
                for await recordsData in recordsStream {
                    if Task.isCancelled { break }
                    
                    do {
                        let hosts = try self.mapRecordsToHosts(recordsData)
                        continuation.yield(hosts)
                    } catch {
                        print("Error mapping hosts: \(error)")
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
    
    public func deleteHost(id: Int64) async throws {
        try await localDataSource.deleteHost(id: id)
    }
    
    // MARK: - Private Mapping Methods
    
    private func mapToHost(
        hostRecord: HostRecord,
        sourceRecords: [SourceRecord],
        configRecords: [SearchConfigRecord],
        tagRecords: [SearchTagRecord],
        presetRecords: [SearchPresetRecord]
    ) throws -> Host {
        guard let hostId = hostRecord.id else {
            throw RepositoryError.mappingError(reason: "Host ID is nil")
        }
        
        let hostDisplayName = "@\(hostRecord.author)/\(hostRecord.name)"
        
        let sources = try sourceRecords.compactMap { sourceRecord -> Source? in
            guard let sourceId = sourceRecord.id else {
                throw RepositoryError.mappingError(reason: "Source ID is nil")
            }
            
            let config = configRecords.first { $0.sourceId == sourceId }
            let sourceTags = tagRecords.filter { $0.sourceId == sourceId }
            let sourcePresets = presetRecords.filter { $0.sourceId == sourceId }
            
            let tags = sourceTags.map { SearchTag(
                slug: $0.slug,
                name: $0.name,
                nsfw: $0.nsfw
            )}
            
            let presets = try sourcePresets.compactMap { presetRecord -> SearchPreset? in
                guard let presetId = presetRecord.id else { return nil }
                
                let decoder = JSONDecoder()
                let request = try decoder.decode(PresetRequestDTO.self, from: presetRecord.request)
                
                return SearchPreset(
                    id: presetId.rawValue,
                    name: presetRecord.name,
                    description: presetRecord.description,
                    filters: request.filters ?? [:],
                    sortOption: request.sort,
                    sortDirection: request.direction
                )
            }
            
            let auth = mapAuthType(sourceRecord.authType)
            
            let search = Search(
                supportedSorts: config?.supportedSorts ?? [],
                supportedFilters: config?.supportedFilters ?? [],
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
    
    private func mapRecordsToHosts(_ recordsData: [(HostRecord, [(SourceRecord, SearchConfigRecord?, [SearchTagRecord], [SearchPresetRecord])])]) throws -> [Host] {
        try recordsData.map { (hostRecord, sourcesData) in
            let sourceRecords = sourcesData.map { $0.0 }
            let configRecords = sourcesData.compactMap { $0.1 }
            let tagRecords = sourcesData.flatMap { $0.2 }
            let presetRecords = sourcesData.flatMap { $0.3 }
            
            return try mapToHost(
                hostRecord: hostRecord,
                sourceRecords: sourceRecords,
                configRecords: configRecords,
                tagRecords: tagRecords,
                presetRecords: presetRecords
            )
        }
    }
    
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

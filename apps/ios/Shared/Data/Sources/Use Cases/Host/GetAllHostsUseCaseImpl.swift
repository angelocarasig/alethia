//
//  GetAllHostsUseCaseImpl.swift
//  Data
//
//  Created by Angelo Carasig on 5/10/2025.
//

import Foundation
import Domain
import GRDB

public final class GetAllHostsUseCaseImpl: GetAllHostsUseCase {
    private let repository: HostRepository
    private let database: DatabaseConfiguration
    
    public init(repository: HostRepository) {
        self.repository = repository
        self.database = DatabaseConfiguration.shared
    }
    
    public func execute() -> AsyncStream<[Domain.Host]> {
        AsyncStream { continuation in
            let observation = ValueObservation
                .tracking { db -> [HostWithSources] in
                    try self.repository.fetchHostsWithData(in: db)
                }
            
            let task = Task {
                do {
                    for try await hostsData in observation.values(in: database.reader) {
                        if Task.isCancelled { break }
                        
                        do {
                            let hosts = try self.mapToHosts(hostsData)
                            continuation.yield(hosts)
                        } catch {
                            // log mapping errors but continue stream
                            #if DEBUG
                            print("Error mapping hosts: \(error)")
                            #endif
                            continuation.yield([])
                        }
                    }
                    continuation.finish()
                } catch {
                    #if DEBUG
                    print("Error observing hosts: \(error)")
                    #endif
                    continuation.finish()
                }
            }
            
            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }
    
    // MARK: - Mapping
    
    private func mapToHosts(_ hostsData: [HostWithSources]) throws -> [Domain.Host] {
        try hostsData.map { hostWithSources in
            try mapToHost(hostWithSources)
        }
    }
    
    private func mapToHost(_ hostWithSources: HostWithSources) throws -> Domain.Host {
        // cast host record
        guard let hostRecord = hostWithSources.host as? HostRecord else {
            throw SystemError.mappingFailed(reason: "Invalid host record type")
        }
        
        guard let hostId = hostRecord.id else {
            throw SystemError.mappingFailed(reason: "Host ID is nil")
        }
        
        // map sources
        let sources = try hostWithSources.sources.map { sourceWithConfig in
            try mapToSource(sourceWithConfig, hostRecord: hostRecord)
        }
        
        return Domain.Host(
            id: hostId.rawValue,
            name: hostRecord.name,
            author: hostRecord.author,
            url: hostRecord.url,
            repository: hostRecord.repository,
            official: hostRecord.official,
            sources: sources
        )
    }
    
    private func mapToSource(_ sourceWithConfig: SourceWithConfig, hostRecord: HostRecord) throws -> Domain.Source {
        // cast source record
        guard let sourceRecord = sourceWithConfig.source as? SourceRecord else {
            throw SystemError.mappingFailed(reason: "Invalid source record type")
        }
        
        guard let sourceId = sourceRecord.id else {
            throw SystemError.mappingFailed(reason: "Source ID is nil")
        }
        
        // cast search config if present
        let searchConfig = sourceWithConfig.searchConfig as? SearchConfigRecord
        
        // cast and map tags
        let searchTags = (sourceWithConfig.searchTags as? [SearchTagRecord] ?? []).map { tagRecord in
            Domain.SearchTag(
                slug: tagRecord.slug,
                name: tagRecord.name,
                nsfw: tagRecord.nsfw
            )
        }
        
        // cast and map presets
        let searchPresets = try (sourceWithConfig.searchPresets as? [SearchPresetRecord] ?? []).compactMap { presetRecord -> Domain.SearchPreset? in
            guard let presetId = presetRecord.id else { return nil }
            
            let decoder = JSONDecoder()
            let request = try decoder.decode(PresetRequestDTO.self, from: presetRecord.request)
            
            return Domain.SearchPreset(
                id: presetId.rawValue,
                name: presetRecord.name,
                description: presetRecord.description,
                filters: request.filters ?? [:],
                sortOption: request.sort,
                sortDirection: request.direction
            )
        }
        
        // map auth type
        let auth = mapAuthType(sourceRecord.authType)
        
        // create search configuration
        let search = Domain.Search(
            supportedSorts: searchConfig?.supportedSorts ?? [],
            supportedFilters: searchConfig?.supportedFilters ?? [],
            tags: searchTags,
            presets: searchPresets
        )
        
        let hostDisplayName = "@\(hostRecord.author)/\(hostRecord.name)"
        
        return Domain.Source(
            id: sourceId.rawValue,
            slug: sourceRecord.slug,
            name: sourceRecord.name,
            icon: sourceRecord.icon,
            url: sourceRecord.url,
            repository: hostRecord.repository,
            pinned: sourceRecord.pinned,
            disabled: sourceRecord.disabled,
            host: hostDisplayName,
            auth: auth,
            search: search,
            presets: searchPresets,
            languages: sourceRecord.languages
        )
    }
    
    private func mapAuthType(_ authType: AuthType?) -> Domain.Auth {
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

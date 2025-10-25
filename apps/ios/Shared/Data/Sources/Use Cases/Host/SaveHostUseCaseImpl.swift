//
//  SaveHostUseCaseImpl.swift
//  Data
//
//  Created by Angelo Carasig on 25/10/2025.
//

import Foundation
import Domain
import GRDB

public final class SaveHostUseCaseImpl: SaveHostUseCase {
    private let repository: HostRepository
    private let database: DatabaseConfiguration
    
    public init(repository: HostRepository) {
        self.repository = repository
        self.database = DatabaseConfiguration.shared
    }
    
    public func execute(_ dto: HostDTO, hostURL: URL) async throws -> Host {
        // validate host has at least one source
        guard !dto.sources.isEmpty else {
            throw BusinessError.noSourcesInHost
        }
        
        // validate host configuration
        guard !dto.name.isEmpty else {
            throw BusinessError.invalidHostConfiguration(reason: "Host name is empty")
        }
        
        guard !dto.author.isEmpty else {
            throw BusinessError.invalidHostConfiguration(reason: "Host author is empty")
        }
        
        for source in dto.sources {
            guard !source.name.isEmpty else {
                throw BusinessError.invalidHostConfiguration(reason: "Source name is empty")
            }
            
            guard !source.slug.isEmpty else {
                throw BusinessError.invalidHostConfiguration(reason: "Source slug is empty")
            }
        }
        
        do {
            let hostData = try await database.writer.write { db in
                // check if host already exists
                if try self.repository.hostExists(repository: dto.repository, in: db) {
                    throw BusinessError.hostAlreadyExists(repository: URL(string: dto.repository)!)
                }
                
                // save host with all related data
                return try self.repository.saveHostWithData(dto, url: hostURL, in: db)
            }
            
            // map to domain entity
            return try mapToHost(hostData)
            
        } catch let error as BusinessError {
            throw error
        } catch let error as StorageError {
            throw error.toDomainError()
        } catch let dbError as DatabaseError {
            throw StorageError.from(grdbError: dbError, context: "saveHost").toDomainError()
        } catch {
            throw DataAccessError.storageFailure(reason: "Failed to save host", underlying: error)
        }
    }
    
    // MARK: - Mapping
    
    private func mapToHost(_ data: HostData) throws -> Host {
        // cast records to proper types
        guard let hostRecord = data.host as? HostRecord else {
            throw StorageError.invalidCast(expected: "HostRecord", actual: String(describing: type(of: data.host)))
        }
        
        guard let hostId = hostRecord.id else {
            throw SystemError.mappingFailed(reason: "Host ID is nil after save")
        }
        
        let sourceRecords = data.sources as? [SourceRecord] ?? []
        let configRecords = data.searchConfigs as? [SearchConfigRecord] ?? []
        let tagRecords = data.searchTags as? [SearchTagRecord] ?? []
        let presetRecords = data.searchPresets as? [SearchPresetRecord] ?? []
        
        // map sources
        let sources = try sourceRecords.map { sourceRecord in
            try mapToSource(
                sourceRecord,
                hostRecord: hostRecord,
                configs: configRecords,
                tags: tagRecords,
                presets: presetRecords
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
    
    private func mapToSource(
        _ sourceRecord: SourceRecord,
        hostRecord: HostRecord,
        configs: [SearchConfigRecord],
        tags: [SearchTagRecord],
        presets: [SearchPresetRecord]
    ) throws -> Source {
        guard let sourceId = sourceRecord.id else {
            throw SystemError.mappingFailed(reason: "Source ID is nil")
        }
        
        // find config for this source
        let config = configs.first { $0.sourceId == sourceId }
        
        // filter tags for this source
        let sourceTags = tags
            .filter { $0.sourceId == sourceId }
            .map { SearchTag(slug: $0.slug, name: $0.name, nsfw: $0.nsfw) }
        
        // filter and map presets for this source
        let sourcePresets = try presets
            .filter { $0.sourceId == sourceId }
            .compactMap { presetRecord -> SearchPreset? in
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
        
        // map auth
        let auth = mapAuthType(sourceRecord.authType)
        
        // create search configuration
        let search = Search(
            supportedSorts: config?.supportedSorts ?? [],
            supportedFilters: config?.supportedFilters ?? [],
            tags: sourceTags,
            presets: sourcePresets
        )
        
        let hostDisplayName = "@\(hostRecord.author)/\(hostRecord.name)"
        
        return Source(
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
            presets: sourcePresets,
            languages: sourceRecord.languages
        )
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

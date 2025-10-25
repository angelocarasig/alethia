//
//  HostRepositoryImpl.swift
//  Data
//
//  Created by Angelo Carasig on 5/10/2025.
//

import Foundation
import Domain
import GRDB
import Core

public final class HostRepositoryImpl: HostRepository {
    private let database: DatabaseConfiguration
    private let networkService: NetworkService
    
    public init() {
        self.database = DatabaseConfiguration.shared
        self.networkService = NetworkService()
    }
    
    // MARK: - Remote Operations
    
    public func remoteManifest(from url: URL) async throws -> HostDTO {
        do {
            return try await networkService.request(url: url)
        } catch let error as NetworkError {
            throw error
        } catch {
            throw NetworkError.requestFailed(underlyingError: error as? URLError ?? URLError(.unknown))
        }
    }
    
    public func remoteValidateHost(url: URL) async throws -> Bool {
        do {
            let _: HostDTO = try await networkService.request(url: url)
            return true
        } catch {
            return false
        }
    }
    
    // MARK: - Host Operations
    
    public func fetch(hostId: Int64, in db: Any) throws -> Any? {
        guard let db = db as? Database else { throw StorageError.invalidCast(expected: "Database", actual: String(describing: type(of: db))) }
        return try HostRecord.filter(HostRecord.Columns.id == hostId).fetchOne(db)
    }
    
    public func fetch(hostRepository: String, in db: Any) throws -> Any? {
        guard let db = db as? Database else { throw StorageError.invalidCast(expected: "Database", actual: String(describing: type(of: db))) }
        return try HostRecord.filter(HostRecord.Columns.repository == hostRepository).fetchOne(db)
    }
    
    public func fetchHosts(in db: Any) throws -> [Any] {
        guard let db = db as? Database else { throw StorageError.invalidCast(expected: "Database", actual: String(describing: type(of: db))) }
        return try HostRecord.order(HostRecord.Columns.name).fetchAll(db)
    }
    
    public func fetchHosts(limit: Int?, offset: Int?, in db: Any) throws -> [Any] {
        guard let db = db as? Database else { throw StorageError.invalidCast(expected: "Database", actual: String(describing: type(of: db))) }
        
        var request = HostRecord.order(HostRecord.Columns.name)
        if let limit = limit {
            request = request.limit(limit, offset: offset)
        }
        return try request.fetchAll(db)
    }
    
    @discardableResult
    public func save(host dto: HostDTO, url: URL, in db: Any) throws -> Any {
        guard let db = db as? Database else { throw StorageError.invalidCast(expected: "Database", actual: String(describing: type(of: db))) }
        
        var hostRecord = HostRecord(
            name: dto.name,
            author: dto.author,
            url: url,
            repository: URL(string: dto.repository)!,
            official: false
        )
        
        try hostRecord.insert(db)
        return hostRecord
    }
    
    public func update(hostId: Int64, fields: HostUpdateFields, in db: Any) throws {
        guard let db = db as? Database else { throw StorageError.invalidCast(expected: "Database", actual: String(describing: type(of: db))) }
        
        guard var record = try HostRecord.filter(HostRecord.Columns.id == hostId).fetchOne(db) else {
            throw StorageError.recordNotFound(table: "host", id: String(hostId))
        }
        
        if let name = fields.name { record.name = name }
        if let author = fields.author { record.author = author }
        if let official = fields.official { record.official = official }
        
        try record.update(db)
    }
    
    public func delete(hostId: Int64, in db: Any) throws {
        guard let db = db as? Database else { throw StorageError.invalidCast(expected: "Database", actual: String(describing: type(of: db))) }
        try HostRecord.filter(HostRecord.Columns.id == hostId).deleteAll(db)
    }
    
    // MARK: - Source Operations
    
    public func fetch(sourceId: Int64, in db: Any) throws -> Any? {
        guard let db = db as? Database else { throw StorageError.invalidCast(expected: "Database", actual: String(describing: type(of: db))) }
        return try SourceRecord.filter(SourceRecord.Columns.id == sourceId).fetchOne(db)
    }
    
    public func fetch(sourceSlug: String, hostId: Int64, in db: Any) throws -> Any? {
        guard let db = db as? Database else { throw StorageError.invalidCast(expected: "Database", actual: String(describing: type(of: db))) }
        return try SourceRecord
            .filter(SourceRecord.Columns.slug == sourceSlug)
            .filter(SourceRecord.Columns.hostId == hostId)
            .fetchOne(db)
    }
    
    public func fetchSources(hostId: Int64, in db: Any) throws -> [Any] {
        guard let db = db as? Database else { throw StorageError.invalidCast(expected: "Database", actual: String(describing: type(of: db))) }
        return try SourceRecord
            .filter(SourceRecord.Columns.hostId == hostId)
            .order(SourceRecord.Columns.name)
            .fetchAll(db)
    }
    
    public func fetchSourceWithHost(sourceId: Int64, in db: Any) throws -> (source: Any, host: Any)? {
        guard let db = db as? Database else { throw StorageError.invalidCast(expected: "Database", actual: String(describing: type(of: db))) }
        
        guard let source = try SourceRecord.filter(SourceRecord.Columns.id == sourceId).fetchOne(db) else {
            return nil
        }
        
        guard let host = try source.host.fetchOne(db) else {
            return nil
        }
        
        return (source: source, host: host)
    }
    
    public func update(sourceId: Int64, fields: SourceUpdateFields, in db: Any) throws {
        guard let db = db as? Database else { throw StorageError.invalidCast(expected: "Database", actual: String(describing: type(of: db))) }
        
        guard var record = try SourceRecord.filter(SourceRecord.Columns.id == sourceId).fetchOne(db) else {
            throw StorageError.recordNotFound(table: "source", id: String(sourceId))
        }
        
        if let pinned = fields.pinned { record.pinned = pinned }
        if let disabled = fields.disabled { record.disabled = disabled }
        
        try record.update(db)
    }
    
    public func delete(sourceId: Int64, in db: Any) throws {
        guard let db = db as? Database else { throw StorageError.invalidCast(expected: "Database", actual: String(describing: type(of: db))) }
        try SourceRecord.filter(SourceRecord.Columns.id == sourceId).deleteAll(db)
    }
    
    // MARK: - Search Configuration
    
    public func fetchSearchConfig(sourceId: Int64, in db: Any) throws -> Any? {
        guard let db = db as? Database else { throw StorageError.invalidCast(expected: "Database", actual: String(describing: type(of: db))) }
        return try SearchConfigRecord.filter(SearchConfigRecord.Columns.sourceId == sourceId).fetchOne(db)
    }
    
    public func fetchSearchTags(sourceId: Int64, in db: Any) throws -> [Any] {
        guard let db = db as? Database else { throw StorageError.invalidCast(expected: "Database", actual: String(describing: type(of: db))) }
        return try SearchTagRecord
            .filter(SearchTagRecord.Columns.sourceId == sourceId)
            .order(SearchTagRecord.Columns.name)
            .fetchAll(db)
    }
    
    public func fetchSearchPresets(sourceId: Int64, in db: Any) throws -> [Any] {
        guard let db = db as? Database else { throw StorageError.invalidCast(expected: "Database", actual: String(describing: type(of: db))) }
        return try SearchPresetRecord
            .filter(SearchPresetRecord.Columns.sourceId == sourceId)
            .order(SearchPresetRecord.Columns.name)
            .fetchAll(db)
    }
    
    @discardableResult
    public func save(searchConfig: SearchConfigData, in db: Any) throws -> Any {
        guard let db = db as? Database else { throw StorageError.invalidCast(expected: "Database", actual: String(describing: type(of: db))) }
        
        let sourceId = SourceRecord.ID(rawValue: searchConfig.sourceId)
        
        var config = SearchConfigRecord(
            sourceId: sourceId,
            supportedSorts: searchConfig.sorts,
            supportedFilters: searchConfig.filters
        )
        try config.insert(db)
        return config
    }
    
    @discardableResult
    public func save(searchTag: SearchTagData, in db: Any) throws -> Any {
        guard let db = db as? Database else { throw StorageError.invalidCast(expected: "Database", actual: String(describing: type(of: db))) }
        
        let sourceId = SourceRecord.ID(rawValue: searchTag.sourceId)
        
        var tag = SearchTagRecord(
            sourceId: sourceId,
            slug: searchTag.slug,
            name: searchTag.name,
            nsfw: searchTag.nsfw
        )
        try tag.insert(db)
        return tag
    }
    
    @discardableResult
    public func save(searchPreset: SearchPresetData, in db: Any) throws -> Any {
        guard let db = db as? Database else { throw StorageError.invalidCast(expected: "Database", actual: String(describing: type(of: db))) }
        
        let sourceId = SourceRecord.ID(rawValue: searchPreset.sourceId)
        
        var preset = SearchPresetRecord(
            sourceId: sourceId,
            name: searchPreset.name,
            description: searchPreset.description,
            request: searchPreset.request
        )
        try preset.insert(db)
        return preset
    }
    
    public func delete(searchPresetId: Int64, in db: Any) throws {
        guard let db = db as? Database else { throw StorageError.invalidCast(expected: "Database", actual: String(describing: type(of: db))) }
        try SearchPresetRecord.filter(SearchPresetRecord.Columns.id == searchPresetId).deleteAll(db)
    }
    
    // MARK: - Batch Operations
    
    public func fetchHostWithData(hostId: Int64, in db: Any) throws -> HostData? {
        guard let db = db as? Database else { throw StorageError.invalidCast(expected: "Database", actual: String(describing: type(of: db))) }
        
        guard let host = try HostRecord.filter(HostRecord.Columns.id == hostId).fetchOne(db) else {
            return nil
        }
        
        let sources = try SourceRecord
            .filter(SourceRecord.Columns.hostId == hostId)
            .fetchAll(db)
        
        let sourceIds = sources.compactMap(\.id)
        
        let configs = try SearchConfigRecord
            .filter(sourceIds.contains(SearchConfigRecord.Columns.sourceId))
            .fetchAll(db)
        
        let tags = try SearchTagRecord
            .filter(sourceIds.contains(SearchTagRecord.Columns.sourceId))
            .fetchAll(db)
        
        let presets = try SearchPresetRecord
            .filter(sourceIds.contains(SearchPresetRecord.Columns.sourceId))
            .fetchAll(db)
        
        return HostData(
            host: host,
            sources: sources,
            searchConfigs: configs,
            searchTags: tags,
            searchPresets: presets
        )
    }
    
    public func fetchHostsWithData(in db: Any) throws -> [HostWithSources] {
        guard let db = db as? Database else { throw StorageError.invalidCast(expected: "Database", actual: String(describing: type(of: db))) }
        
        let hosts = try HostRecord.order(HostRecord.Columns.name).fetchAll(db)
        
        return try hosts.map { host in
            guard let hostId = host.id else {
                return HostWithSources(host: host, sources: [])
            }
            
            let sources = try SourceRecord
                .filter(SourceRecord.Columns.hostId == hostId)
                .order(SourceRecord.Columns.name)
                .fetchAll(db)
            
            let sourcesWithConfig = try sources.map { source -> SourceWithConfig in
                guard let sourceId = source.id else {
                    return SourceWithConfig(
                        source: source,
                        searchConfig: nil,
                        searchTags: [],
                        searchPresets: []
                    )
                }
                
                let config = try SearchConfigRecord
                    .filter(SearchConfigRecord.Columns.sourceId == sourceId)
                    .fetchOne(db)
                
                let tags = try SearchTagRecord
                    .filter(SearchTagRecord.Columns.sourceId == sourceId)
                    .fetchAll(db)
                
                let presets = try SearchPresetRecord
                    .filter(SearchPresetRecord.Columns.sourceId == sourceId)
                    .fetchAll(db)
                
                return SourceWithConfig(
                    source: source,
                    searchConfig: config,
                    searchTags: tags,
                    searchPresets: presets
                )
            }
            
            return HostWithSources(host: host, sources: sourcesWithConfig)
        }
    }
    
    @discardableResult
    public func saveHostWithData(_ dto: HostDTO, url: URL, in db: Any) throws -> HostData {
        guard let db = db as? Database else { throw StorageError.invalidCast(expected: "Database", actual: String(describing: type(of: db))) }
        
        // save host
        var hostRecord = HostRecord(
            name: dto.name,
            author: dto.author,
            url: url,
            repository: URL(string: dto.repository)!,
            official: false
        )
        try hostRecord.insert(db)
        
        guard let hostId = hostRecord.id else {
            throw StorageError.recordNotFound(table: "host", id: "after insert")
        }
        
        var savedSources: [SourceRecord] = []
        var savedConfigs: [SearchConfigRecord] = []
        var savedTags: [SearchTagRecord] = []
        var savedPresets: [SearchPresetRecord] = []
        
        // save sources and related data
        for source in dto.sources {
            guard let sourceUrl = URL(string: source.url) else {
                throw StorageError.queryFailed(sql: "saveHostWithData", error: NSError(domain: "InvalidURL", code: 0))
            }
            
            // handle icon
            let iconPath = fileSaveIcon(for: source, hostId: hostId.rawValue)
            
            var sourceRecord = SourceRecord(
                hostId: hostId,
                slug: source.slug,
                name: source.name,
                icon: iconPath,
                url: sourceUrl,
                languages: source.languages,
                pinned: false,
                disabled: false,
                authType: source.auth.type
            )
            
            try sourceRecord.insert(db)
            
            guard let sourceId = sourceRecord.id else {
                throw StorageError.recordNotFound(table: "source", id: "after insert")
            }
            
            savedSources.append(sourceRecord)
            
            // save search config
            var searchConfig = SearchConfigRecord(
                sourceId: sourceId,
                supportedSorts: source.search.sort,
                supportedFilters: source.search.filters
            )
            try searchConfig.insert(db)
            savedConfigs.append(searchConfig)
            
            // save tags
            for tag in source.search.tags {
                var tagRecord = SearchTagRecord(
                    sourceId: sourceId,
                    slug: tag.slug,
                    name: tag.name,
                    nsfw: tag.nsfw
                )
                try tagRecord.insert(db)
                savedTags.append(tagRecord)
            }
            
            // save presets
            for preset in source.presets {
                let encoder = JSONEncoder()
                let requestData = try encoder.encode(preset.request)
                
                var presetRecord = SearchPresetRecord(
                    sourceId: sourceId,
                    name: preset.name,
                    description: preset.description,
                    request: requestData
                )
                try presetRecord.insert(db)
                savedPresets.append(presetRecord)
            }
        }
        
        return HostData(
            host: hostRecord,
            sources: savedSources,
            searchConfigs: savedConfigs,
            searchTags: savedTags,
            searchPresets: savedPresets
        )
    }
    
    // MARK: - Validation
    
    public func hostExists(repository: String, in db: Any) throws -> Bool {
        guard let db = db as? Database else { throw StorageError.invalidCast(expected: "Database", actual: String(describing: type(of: db))) }
        return try HostRecord.filter(HostRecord.Columns.repository == repository).fetchOne(db) != nil
    }
    
    public func sourceExists(slug: String, hostId: Int64, in db: Any) throws -> Bool {
        guard let db = db as? Database else { throw StorageError.invalidCast(expected: "Database", actual: String(describing: type(of: db))) }
        return try SourceRecord
            .filter(SourceRecord.Columns.slug == slug)
            .filter(SourceRecord.Columns.hostId == hostId)
            .fetchOne(db) != nil
    }
    
    // MARK: - File Operations
    
    public func fileSaveIcon(data: Data, sourceSlug: String, hostId: Int64) throws -> URL {
        let hostDirectory = Core.Constants.Paths.host(String(hostId))
        let iconsDirectory = hostDirectory.appendingPathComponent("icons", isDirectory: true)
        
        try FileManager.default.createDirectory(
            at: iconsDirectory,
            withIntermediateDirectories: true
        )
        
        let iconPath = iconsDirectory.appendingPathComponent("\(sourceSlug).png")
        try data.write(to: iconPath)
        
        return iconPath
    }
    
    private func fileSaveIcon(for source: SourceDTO, hostId: Int64) -> URL {
        let hostDirectory = Core.Constants.Paths.host(String(hostId))
        let iconsDirectory = hostDirectory.appendingPathComponent("icons", isDirectory: true)
        
        try? FileManager.default.createDirectory(
            at: iconsDirectory,
            withIntermediateDirectories: true
        )
        
        // download icon if available
        let iconPath = iconsDirectory.appendingPathComponent("\(source.slug).png")
        
        if let iconURL = URL(string: source.icon) {
            Task {
                if let (iconData, _) = try? await URLSession.shared.data(from: iconURL) {
                    try? iconData.write(to: iconPath)
                }
            }
        }
        
        return iconPath
    }
    
    public func fileDeleteIcon(sourceSlug: String, hostId: Int64) throws {
        let iconPath = fileIconURL(sourceSlug: sourceSlug, hostId: hostId)
        
        if FileManager.default.fileExists(atPath: iconPath.path) {
            try FileManager.default.removeItem(at: iconPath)
        }
    }
    
    public func fileCleanupHost(hostId: Int64) throws {
        let hostDirectory = Core.Constants.Paths.host(String(hostId))
        
        if FileManager.default.fileExists(atPath: hostDirectory.path) {
            try FileManager.default.removeItem(at: hostDirectory)
        }
    }
    
    public func fileIconURL(sourceSlug: String, hostId: Int64) -> URL {
        Core.Constants.Paths.host(String(hostId))
            .appendingPathComponent("icons", isDirectory: true)
            .appendingPathComponent("\(sourceSlug).png")
    }
}

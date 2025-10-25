//
//  HostRepository.swift
//  Domain
//
//  Created by Angelo Carasig on 25/10/2025.
//

import Foundation

// MARK: - Data Transfer Objects

public struct HostData: @unchecked Sendable {
    public let host: Any
    public let sources: [Any]
    public let searchConfigs: [Any]
    public let searchTags: [Any]
    public let searchPresets: [Any]
    
    public init(
        host: Any,
        sources: [Any],
        searchConfigs: [Any],
        searchTags: [Any],
        searchPresets: [Any]
    ) {
        self.host = host
        self.sources = sources
        self.searchConfigs = searchConfigs
        self.searchTags = searchTags
        self.searchPresets = searchPresets
    }
}

public struct SourceWithConfig: @unchecked Sendable {
    public let source: Any
    public let searchConfig: Any?
    public let searchTags: [Any]
    public let searchPresets: [Any]
    
    public init(
        source: Any,
        searchConfig: Any?,
        searchTags: [Any],
        searchPresets: [Any]
    ) {
        self.source = source
        self.searchConfig = searchConfig
        self.searchTags = searchTags
        self.searchPresets = searchPresets
    }
}

// MARK: - HostRepository

public protocol HostRepository: Sendable {
    
    // MARK: Remote Operations
    
    func remoteManifest(from url: URL) async throws -> HostDTO
    func remoteValidateHost(url: URL) async throws -> Bool
    
    // MARK: Host Operations
    
    func fetch(hostId: Int64, in db: Any) throws -> Any?
    func fetch(hostRepository: String, in db: Any) throws -> Any?
    func fetchHosts(in db: Any) throws -> [Any]
    func fetchHosts(limit: Int?, offset: Int?, in db: Any) throws -> [Any]
    
    @discardableResult
    func save(host dto: HostDTO, url: URL, in db: Any) throws -> Any
    func update(hostId: Int64, fields: HostUpdateFields, in db: Any) throws
    func delete(hostId: Int64, in db: Any) throws
    
    // MARK: Source Operations
    
    func fetch(sourceId: Int64, in db: Any) throws -> Any?
    func fetch(sourceSlug: String, hostId: Int64, in db: Any) throws -> Any?
    func fetchSources(hostId: Int64, in db: Any) throws -> [Any]
    func fetchSourceWithHost(sourceId: Int64, in db: Any) throws -> (source: Any, host: Any)?
    
    func update(sourceId: Int64, fields: SourceUpdateFields, in db: Any) throws
    func delete(sourceId: Int64, in db: Any) throws
    
    // MARK: Search Configuration
    
    func fetchSearchConfig(sourceId: Int64, in db: Any) throws -> Any?
    func fetchSearchTags(sourceId: Int64, in db: Any) throws -> [Any]
    func fetchSearchPresets(sourceId: Int64, in db: Any) throws -> [Any]
    
    @discardableResult
    func save(searchConfig: SearchConfigData, in db: Any) throws -> Any
    @discardableResult
    func save(searchTag: SearchTagData, in db: Any) throws -> Any
    @discardableResult
    func save(searchPreset: SearchPresetData, in db: Any) throws -> Any
    
    func delete(searchPresetId: Int64, in db: Any) throws
    
    // MARK: Batch Operations
    
    func fetchHostWithData(hostId: Int64, in db: Any) throws -> HostData?
    func fetchHostsWithData(in db: Any) throws -> [HostWithSources]
    
    @discardableResult
    func saveHostWithData(_ dto: HostDTO, url: URL, in db: Any) throws -> HostData
    
    // MARK: Validation
    
    func hostExists(repository: String, in db: Any) throws -> Bool
    func sourceExists(slug: String, hostId: Int64, in db: Any) throws -> Bool
    
    // MARK: File Operations
    
    func fileSaveIcon(data: Data, sourceSlug: String, hostId: Int64) throws -> URL
    func fileDeleteIcon(sourceSlug: String, hostId: Int64) throws
    func fileCleanupHost(hostId: Int64) throws
    func fileIconURL(sourceSlug: String, hostId: Int64) -> URL
}

// MARK: - Supporting Types

public struct HostUpdateFields {
    public var name: String?
    public var author: String?
    public var official: Bool?
    
    public init(name: String? = nil, author: String? = nil, official: Bool? = nil) {
        self.name = name
        self.author = author
        self.official = official
    }
}

public struct SourceUpdateFields {
    public var pinned: Bool?
    public var disabled: Bool?
    
    public init(pinned: Bool? = nil, disabled: Bool? = nil) {
        self.pinned = pinned
        self.disabled = disabled
    }
}

public struct SearchConfigData {
    public let sourceId: Int64
    public let sorts: [Search.Options.Sort]
    public let filters: [Search.Options.Filter]
    
    public init(sourceId: Int64, sorts: [Search.Options.Sort], filters: [Search.Options.Filter]) {
        self.sourceId = sourceId
        self.sorts = sorts
        self.filters = filters
    }
}

public struct SearchTagData {
    public let sourceId: Int64
    public let slug: String
    public let name: String
    public let nsfw: Bool
    
    public init(sourceId: Int64, slug: String, name: String, nsfw: Bool) {
        self.sourceId = sourceId
        self.slug = slug
        self.name = name
        self.nsfw = nsfw
    }
}

public struct SearchPresetData {
    public let sourceId: Int64
    public let name: String
    public let description: String?
    public let request: Data
    
    public init(sourceId: Int64, name: String, description: String?, request: Data) {
        self.sourceId = sourceId
        self.name = name
        self.description = description
        self.request = request
    }
}


public struct HostWithSources: @unchecked Sendable {
    public let host: Any
    public let sources: [SourceWithConfig]
    
    public init(host: Any, sources: [SourceWithConfig]) {
        self.host = host
        self.sources = sources
    }
}

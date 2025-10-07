//
//  HostLocalDataSource.swift
//  Data
//
//  Created by Angelo Carasig on 5/10/2025.
//

import Foundation
import Domain
import GRDB
import Core

internal protocol HostLocalDataSource: Sendable {
    func hostExists(with repositoryURL: String) async throws -> (HostRecord.ID, URL)?
    func saveHost(_ dto: HostDTO, hostURL: URL) async throws -> (HostRecord, [SourceRecord], [SearchConfigRecord], [SearchTagRecord], [SearchPresetRecord])
    func fetchAllHosts() async throws -> [(HostRecord, [(SourceRecord, SearchConfigRecord?, [SearchTagRecord], [SearchPresetRecord])])]
    func observeAllHosts() -> AsyncStream<[(HostRecord, [(SourceRecord, SearchConfigRecord?, [SearchTagRecord], [SearchPresetRecord])])]>
    func deleteHost(id: Int64) async throws
}

internal final class HostLocalDataSourceImpl: HostLocalDataSource {
    private let database: DatabaseConfiguration
    
    init(database: DatabaseConfiguration? = nil) {
        self.database = database ?? DatabaseConfiguration.shared
    }
    
    func hostExists(with repositoryURL: String) async throws -> (HostRecord.ID, URL)? {
        try await database.reader.read { db in
            try HostRecord
                .filter(HostRecord.Columns.repository == repositoryURL)
                .fetchOne(db)
                .flatMap { record in
                    record.id.map { id in (id, record.repository) }
                }
        }
    }
    
    func saveHost(_ dto: HostDTO, hostURL: URL) async throws -> (HostRecord, [SourceRecord], [SearchConfigRecord], [SearchTagRecord], [SearchPresetRecord]) {
        let tempHostId = UUID().uuidString
        let hostDirectory = Core.Constants.Paths.host(tempHostId)
        let iconsDirectory = hostDirectory.appendingPathComponent("icons", isDirectory: true)
        
        do {
            try FileManager.default.createDirectory(
                at: iconsDirectory,
                withIntermediateDirectories: true
            )
            
            // download icons
            var iconPaths: [String: URL] = [:]
            for source in dto.sources {
                let localIconName = "\(source.slug).png"
                let localIconPath = iconsDirectory.appendingPathComponent(localIconName)
                
                if let iconURL = URL(string: source.icon) {
                    let (iconData, _) = try await URLSession.shared.data(from: iconURL)
                    try iconData.write(to: localIconPath)
                    iconPaths[source.slug] = localIconPath
                }
            }
            
            // database transaction
            let result = try await database.writer.write { db in
                var hostRecord = HostRecord(
                    name: dto.name,
                    author: dto.author,
                    url: hostURL,
                    repository: URL(string: dto.repository)!,
                    official: false
                )
                
                try hostRecord.insert(db)
                
                guard let hostId = hostRecord.id else {
                    throw RepositoryError.mappingError(reason: "Failed to get host ID after insert")
                }
                
                // rename temp directory
                let finalHostDirectory = Core.Constants.Paths.host(String(hostId.rawValue))
                
                if FileManager.default.fileExists(atPath: finalHostDirectory.path) {
                    try FileManager.default.removeItem(at: finalHostDirectory)
                }
                
                try FileManager.default.moveItem(at: hostDirectory, to: finalHostDirectory)
                
                // save sources and related data
                let finalIconsDirectory = finalHostDirectory.appendingPathComponent("icons", isDirectory: true)
                
                var savedSources: [SourceRecord] = []
                var savedConfigs: [SearchConfigRecord] = []
                var savedTags: [SearchTagRecord] = []
                var savedPresets: [SearchPresetRecord] = []
                
                for source in dto.sources {
                    let finalIconPath = finalIconsDirectory.appendingPathComponent("\(source.slug).png")
                    
                    guard let url = URL(string: source.url) else {
                        throw RepositoryError.sourceURLInvalid
                    }
                    
                    var sourceRecord = SourceRecord(
                        hostId: hostId,
                        slug: source.slug,
                        name: source.name,
                        icon: finalIconPath,
                        url: url,
                        pinned: false,
                        disabled: false,
                        authType: source.auth.type
                    )
                    
                    try sourceRecord.insert(db)
                    
                    guard let sourceId = sourceRecord.id else {
                        throw RepositoryError.mappingError(reason: "Failed to get source ID after insert")
                    }
                    
                    savedSources.append(sourceRecord)
                    
                    // save search config - using proper initializer
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
                
                return (hostRecord, savedSources, savedConfigs, savedTags, savedPresets)
            }
            
            return result
            
        } catch {
            if FileManager.default.fileExists(atPath: hostDirectory.path) {
                try? FileManager.default.removeItem(at: hostDirectory)
            }
            throw error
        }
    }
    
    func fetchAllHosts() async throws -> [(HostRecord, [(SourceRecord, SearchConfigRecord?, [SearchTagRecord], [SearchPresetRecord])])] {
        try await database.reader.read { db in
            try fetchAllHostsWithData(db)
        }
    }
    
    func observeAllHosts() -> AsyncStream<[(HostRecord, [(SourceRecord, SearchConfigRecord?, [SearchTagRecord], [SearchPresetRecord])])]> {
        AsyncStream { continuation in
            let observation = ValueObservation
                .tracking { db -> [(HostRecord, [(SourceRecord, SearchConfigRecord?, [SearchTagRecord], [SearchPresetRecord])])] in
                    try self.fetchAllHostsWithData(db)
                }
            
            let task = Task {
                do {
                    for try await hostsData in observation.values(in: database.reader) {
                        if Task.isCancelled { break }
                        continuation.yield(hostsData)
                    }
                    continuation.finish()
                } catch {
                    print("Error observing hosts: \(error)")
                    continuation.finish()
                }
            }
            
            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }
    
    func deleteHost(id: Int64) async throws {
    }
    
    private func fetchAllHostsWithData(_ db: GRDB.Database) throws -> [(HostRecord, [(SourceRecord, SearchConfigRecord?, [SearchTagRecord], [SearchPresetRecord])])] {
        let hosts = try HostRecord
            .order(HostRecord.Columns.name)
            .fetchAll(db)
        
        var results: [(HostRecord, [(SourceRecord, SearchConfigRecord?, [SearchTagRecord], [SearchPresetRecord])])] = []
        
        for host in hosts {
            guard let hostId = host.id else { continue }
            
            let sources = try SourceRecord
                .filter(SourceRecord.Columns.hostId == hostId)
                .order(SourceRecord.Columns.name)
                .fetchAll(db)
            
            var sourcesWithData: [(SourceRecord, SearchConfigRecord?, [SearchTagRecord], [SearchPresetRecord])] = []
            
            for source in sources {
                guard let sourceId = source.id else { continue }
                
                let searchConfig = try SearchConfigRecord
                    .filter(SearchConfigRecord.Columns.sourceId == sourceId)
                    .fetchOne(db)
                
                let searchTags = try SearchTagRecord
                    .filter(SearchTagRecord.Columns.sourceId == sourceId)
                    .order(SearchTagRecord.Columns.name)
                    .fetchAll(db)
                
                let searchPresets = try SearchPresetRecord
                    .filter(SearchPresetRecord.Columns.sourceId == sourceId)
                    .order(SearchPresetRecord.Columns.name)
                    .fetchAll(db)
                
                sourcesWithData.append((source, searchConfig, searchTags, searchPresets))
            }
            
            results.append((host, sourcesWithData))
        }
        
        return results
    }
}

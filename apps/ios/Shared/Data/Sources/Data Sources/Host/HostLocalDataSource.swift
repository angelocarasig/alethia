//
//  HostLocalDataSource.swift
//  Data
//
//  Created by Angelo Carasig on 4/10/2025.
//

import Foundation
import Domain
import GRDB
import Core

/// Handles local database operations for host data
public final class HostLocalDataSource: Sendable {
    private let database: DatabaseConfiguration
    
    init(database: DatabaseConfiguration? = nil) {
        self.database = database ?? DatabaseConfiguration.shared
    }
    
    /// Check if a host with the given repository URL already exists
    /// Returns the host ID and repository URL if found, nil otherwise
    func hostExists(with repositoryURL: URL) async throws -> (HostRecord.ID, URL)? {
        try await database.reader.read { db in
            try HostRecord
                .filter(HostRecord.Columns.repository == repositoryURL)
                .fetchOne(db)
                .flatMap { record in
                    record.id.map { id in (id, record.repository) }
                }
        }
    }
    
    func saveHost(manifest: HostManifest, hostURL: URL) async throws -> (HostRecord, [SourceRecord], [SearchConfigRecord], [SearchTagRecord], [SearchPresetRecord]) {
        // first, get a temporary host id for directory creation
        let tempHostId = UUID().uuidString
        let hostDirectory = Core.Constants.Paths.host(tempHostId)
        let iconsDirectory = hostDirectory.appendingPathComponent("icons", isDirectory: true)
        
        do {
            // create temporary directory for icons
            try FileManager.default.createDirectory(
                at: iconsDirectory,
                withIntermediateDirectories: true
            )
            
            // download all icons first (outside of transaction)
            var iconPaths: [String: URL] = [:]
            for sourceManifest in manifest.sources {
                let localIconName = "\(sourceManifest.slug).png"
                let localIconPath = iconsDirectory.appendingPathComponent(localIconName)
                
                let (iconData, _) = try await URLSession.shared.data(from: sourceManifest.icon)
                try iconData.write(to: localIconPath)
                
                iconPaths[sourceManifest.slug] = localIconPath
            }
            
            // now perform database transaction
            let result = try await database.writer.write { db in
                var hostRecord = HostRecord(
                    name: manifest.name,
                    author: manifest.author,
                    url: hostURL,
                    repository: manifest.repository,
                    official: false
                )
#warning("Implement official flag logic")
                
                try hostRecord.insert(db)
                
                guard let hostId = hostRecord.id else {
                    throw RepositoryError.mappingError(reason: "Failed to get host ID after insert")
                }
                
                // rename temp directory to actual host id
                let finalHostDirectory = Core.Constants.Paths.host(String(hostId.rawValue))
                
                // remove existing directory if it exists
                if FileManager.default.fileExists(atPath: finalHostDirectory.path) {
                    try FileManager.default.removeItem(at: finalHostDirectory)
                }
                
                // now move the temp directory
                try FileManager.default.moveItem(at: hostDirectory, to: finalHostDirectory)
                
                // update icon paths to final location
                let finalIconsDirectory = finalHostDirectory.appendingPathComponent("icons", isDirectory: true)
                
                var savedSources: [SourceRecord] = []
                var savedConfigs: [SearchConfigRecord] = []
                var savedTags: [SearchTagRecord] = []
                var savedPresets: [SearchPresetRecord] = []
                
                for sourceManifest in manifest.sources {
                    let finalIconPath = finalIconsDirectory.appendingPathComponent("\(sourceManifest.slug).png")
                    
                    var sourceRecord = SourceRecord(
                        hostId: hostId,
                        slug: sourceManifest.slug,
                        name: sourceManifest.name,
                        icon: finalIconPath,
                        pinned: false,
                        disabled: false,
                        authType: sourceManifest.auth.type == .none ? .none : sourceManifest.auth.type
                    )
                    
                    try sourceRecord.insert(db)
                    
                    guard let sourceId = sourceRecord.id else {
                        throw RepositoryError.mappingError(reason: "Failed to get source ID after insert")
                    }
                    
                    savedSources.append(sourceRecord)
                    
                    var searchConfig = SearchConfigRecord(
                        sourceId: sourceId,
                        supportedSorts: sourceManifest.search.sort,
                        supportedFilters: sourceManifest.search.filters
                    )
                    
                    try searchConfig.insert(db)
                    savedConfigs.append(searchConfig)
                    
                    for tag in sourceManifest.search.tags {
                        var tagRecord = SearchTagRecord(
                            sourceId: sourceId,
                            slug: tag.slug,
                            name: tag.name,
                            nsfw: tag.nsfw
                        )
                        
                        try tagRecord.insert(db)
                        savedTags.append(tagRecord)
                    }
                    
                    // save search presets for this source
                    for preset in sourceManifest.presets {
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
            // cleanup on failure - remove temp directory if it exists
            if FileManager.default.fileExists(atPath: hostDirectory.path) {
                try? FileManager.default.removeItem(at: hostDirectory)
            }
            throw error
        }
    }
    
    /// Returns an AsyncStream that emits whenever the database changes
    func observeAllHosts() -> AsyncStream<[(HostRecord, [(SourceRecord, SearchConfigRecord?, [SearchTagRecord], [SearchPresetRecord])])]> {
        AsyncStream { continuation in
            // create value observation that tracks all host-related tables
            let observation = ValueObservation
                .tracking { db -> [(HostRecord, [(SourceRecord, SearchConfigRecord?, [SearchTagRecord], [SearchPresetRecord])])] in
                    try self.fetchAllHostsWithData(db)
                }
            
            // start observation task
            let task = Task {
                do {
                    for try await hostsData in observation.values(in: database.reader) {
                        if Task.isCancelled { break }
                        continuation.yield(hostsData)
                    }
                    continuation.finish()
                } catch {
                    // log error but don't throw - just finish the stream
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
}

// MARK: Util Functions
private extension HostLocalDataSource {
    /// Fetches all hosts with their related data synchronously (for use in observations)
    private func fetchAllHostsWithData(_ db: GRDB.Database) throws -> [(HostRecord, [(SourceRecord, SearchConfigRecord?, [SearchTagRecord], [SearchPresetRecord])])] {
        // fetch all hosts
        let hosts = try HostRecord
            .order(HostRecord.Columns.name)
            .fetchAll(db)
        
        var results: [(HostRecord, [(SourceRecord, SearchConfigRecord?, [SearchTagRecord], [SearchPresetRecord])])] = []
        
        for host in hosts {
            guard let hostId = host.id else { continue }
            
            // fetch sources for this host
            let sources = try SourceRecord
                .filter(SourceRecord.Columns.hostId == hostId)
                .order(SourceRecord.Columns.name)
                .fetchAll(db)
            
            var sourcesWithData: [(SourceRecord, SearchConfigRecord?, [SearchTagRecord], [SearchPresetRecord])] = []
            
            for source in sources {
                guard let sourceId = source.id else { continue }
                
                // fetch search config for this source
                let searchConfig = try SearchConfigRecord
                    .filter(SearchConfigRecord.Columns.sourceId == sourceId)
                    .fetchOne(db)
                
                // fetch search tags for this source
                let searchTags = try SearchTagRecord
                    .filter(SearchTagRecord.Columns.sourceId == sourceId)
                    .order(SearchTagRecord.Columns.name)
                    .fetchAll(db)
                
                // fetch search presets for this source
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

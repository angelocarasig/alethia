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
    
    func saveHost(manifest: HostManifest, hostURL: URL) async throws -> (HostRecord, [SourceRecord], [SearchConfigRecord], [SearchTagRecord]) {
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
                try FileManager.default.moveItem(at: hostDirectory, to: finalHostDirectory)
                
                // update icon paths to final location
                let finalIconsDirectory = finalHostDirectory.appendingPathComponent("icons", isDirectory: true)
                
                var savedSources: [SourceRecord] = []
                var savedConfigs: [SearchConfigRecord] = []
                var savedTags: [SearchTagRecord] = []
                
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
                }
                
                return (hostRecord, savedSources, savedConfigs, savedTags)
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
    
    func getAllHosts() async throws -> [(HostRecord, [(SourceRecord, SearchConfigRecord?, [SearchTagRecord], [SearchPresetRecord])])] {
        return []
    }
    
    func deleteHost(id: Int64) async throws {
    }
}

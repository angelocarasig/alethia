//
//  SourceLocalDataSource.swift
//  Alethia
//
//  Created by Angelo Carasig on 18/4/2025.
//

import Foundation
import Combine
import GRDB
import Kingfisher

final class SourceLocalDataSource {
    func getHosts() -> AnyPublisher<[Host], Never> {
        return ValueObservation
            .tracking { db -> [Host] in
                return try Host.order(Host.Columns.name).fetchAll(db)
            }
            .publisher(in: DatabaseProvider.shared.writer, scheduling: .immediate)
            .catch { _ in Just([]) }
            .eraseToAnyPublisher()
    }
    
    func getSources() -> AnyPublisher<[SourceMetadata], Never> {
        return ValueObservation
            .tracking { db -> [SourceMetadata] in
                let sources = try Source.order(Source.Columns.name).fetchAll(db)
                
                return try sources.map { source in
                    let host = try Host.fetchOne(db, key: source.hostId)
                    
                    return SourceMetadata(
                        source: source,
                        hostName: host?.name ?? "Unknown Host",
                        hostAuthor: host?.author ?? "Unknown Author",
                        hostWebsite: host?.repository ?? "",
                        hostBaseUrl: host?.baseUrl ?? ""
                    )
                }
            }
            .publisher(in: DatabaseProvider.shared.writer, scheduling: .immediate)
            .catch { _ in Just([]) }
            .eraseToAnyPublisher()
    }
    
    func createHost(with payload: NewHostPayload) async throws -> Void {
        let hostId: Int64 = try await DatabaseProvider.shared.writer.write { db in
            let host = Host(
                name: payload.name,
                author: payload.author,
                repository: payload.repository,
                baseUrl: payload.baseUrl
            )
            let inserted = try host.insertAndFetch(db)
            guard let id = inserted.id else { throw DatabaseError.internalError("Host-retrieved ID failed - Could not be found.") }
            return id
        }
        
        let folderURL = try await downloadSourceIcons(id: hostId, payload: payload)
        
        try await DatabaseProvider.shared.writer.write { db in
            for source in payload.sources {
                let iconPath = folderURL.appendingPathComponent("\(source.path).png")
                
                guard FileManager.default.fileExists(atPath: iconPath.path) else {
                    throw FilesystemError.fileAlreadyExists(iconPath.path)
                }
                
                var dbSource = Source(
                    name: source.name,
                    icon: iconPath.path,
                    path: source.path,
                    website: source.website,
                    description: source.description,
                    hostId: hostId
                )
                
                dbSource = try dbSource.insertAndFetch(db)
                guard let sourceId = dbSource.id else { throw SourceError.notFound }
                
                for routeDTO in source.paths {
                    let route = SourceRoute(
                        name: routeDTO.name,
                        path: routeDTO.path,
                        sourceId: sourceId
                    )
                    try route.insert(db)
                }
            }
        }
    }
    
    func deleteHost(host: Host) throws -> Void {
        try DatabaseProvider.shared.writer.write { db in
            _ = try host.delete(db)
        }
    }
    
    func toggleSourcePinned(sourceId: Int64, newValue: Bool) throws -> Void {
        try DatabaseProvider.shared.writer.write { db in
            guard var source = try Source.fetchOne(db, key: sourceId) else { throw SourceError.notFound }
            
            source.pinned = newValue
            source.disabled = false
            
            try source.update(db)
        }
    }
    
    func toggleSourceDisabled(sourceId: Int64, newValue: Bool) throws -> Void {
        try DatabaseProvider.shared.writer.write { db in
            guard var source = try Source.fetchOne(db, key: sourceId) else { throw SourceError.notFound }
            
            source.disabled = newValue
            source.pinned = false
            
            try source.update(db)
        }
    }
    
    func observeMatchEntries(entries: [Entry]) -> AnyPublisher<[Entry], Never> {
        ValueObservation
            .tracking { db in
                try entries.map { entry in
                    var updated = entry
                    updated.match = try self.match(for: entry, db: db)
                    return updated
                }
            }
            // can put this one in main actor since not an immediate requirement
            .publisher(in: DatabaseProvider.shared.reader, scheduling: .mainActor)
            .replaceError(with: entries)
            .eraseToAnyPublisher()
    }
}

// MARK: Downloading helper

private extension SourceLocalDataSource {
    func downloadSourceIcons(id: Int64, payload: NewHostPayload) async throws -> URL {
        let fileManager = FileManager.default
        let folderURL = fileManager
            .urls(for: .documentDirectory, in: .userDomainMask)
            .first!
            .appendingPathComponent("Local")
            .appendingPathComponent("host-\(id)", isDirectory: true)
        
        try fileManager.createDirectory(at: folderURL, withIntermediateDirectories: true)
        
        try await withThrowingTaskGroup(of: Void.self) { group in
            for source in payload.sources {
                guard let iconURL = URL(string: source.icon) else {
                    throw NetworkError.invalidURL(url: source.icon)
                }
                
                group.addTask {
                    try await self.downloadAndSaveImage(
                        sourceName: source.path,
                        url: iconURL,
                        folderURL: folderURL
                    )
                }
            }
            
            try await group.waitForAll()
        }
        
        return folderURL
    }
    
    func downloadAndSaveImage(sourceName: String, url: URL, folderURL: URL) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            KingfisherManager.shared.retrieveImage(with: url) { result in
                switch result {
                case .success(let value):
                    let image = value.image
                    guard let imageData = image.pngData() else {
                        continuation.resume(throwing: ApplicationError.internalError)
                        return
                    }
                    
                    let fileURL = folderURL.appendingPathComponent("\(sourceName).png")
                    
                    do {
                        try imageData.write(to: fileURL)
                        continuation.resume(returning: ())
                    } catch {
                        continuation.resume(throwing: error)
                    }
                    
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}

// MARK: Source matching helper

extension SourceLocalDataSource {
    func match(for entry: Entry, db: Database) throws -> EntryMatch {
        // 1. Match by mangaId
        if let mangaId = entry.mangaId,
           let _ = try Manga.fetchOne(db, key: mangaId) {
            return .exact
        }
        
        let title = entry.title
        let sourceId = entry.sourceId
        
        // 2. Check for a match by title + source (via origin)
        let mangaWithMatchingSource = try Manga
            .filter(Manga.Columns.inLibrary == true)
            .joining(required: Manga.origins
                .filter(Origin.Columns.sourceId == sourceId)
            )
            .joining(optional: Manga.titles)
            .filter(
                Manga.Columns.title == title ||
                Title.Columns.title == title
            )
            .fetchOne(db)
        
        if mangaWithMatchingSource != nil {
            return .exact
        }
        
        // 3. Fallback: match just by title
        let mangaWithTitleOnly = try Manga
            .filter(Manga.Columns.inLibrary == true)
            .joining(optional: Manga.titles)
            .filter(
                Manga.Columns.title == title ||
                Title.Columns.title == title
            )
            .fetchOne(db)
        
        return mangaWithTitleOnly != nil ? .partial : .none
    }
}

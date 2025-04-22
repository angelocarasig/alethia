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
    func getSources() -> AnyPublisher<[Source], Never> {
        return ValueObservation
            .tracking { db -> [Source] in
                return try Source.order(Source.Columns.name).fetchAll(db)
            }
            .publisher(in: DatabaseProvider.shared.writer, scheduling: .immediate)
            .catch { _ in Just([]) }
            .eraseToAnyPublisher()
    }
    
    func createHost(with payload: NewHostPayload) async throws -> Void {
        let hostId: Int64 = try await DatabaseProvider.shared.writer.write { db in
            let host = Host(name: payload.name, baseUrl: payload.baseUrl)
            let inserted = try host.insertAndFetch(db)
            guard let id = inserted.id else { throw ApplicationError.internalError }
            return id
        }
        
        let folderURL = try await downloadSourceIcons(id: hostId, payload: payload)
        
        try await DatabaseProvider.shared.writer.write { db in
            for source in payload.sources {
                let iconPath = folderURL.appendingPathComponent("\(source.path).png")
                
                guard FileManager.default.fileExists(atPath: iconPath.path) else {
                    throw ApplicationError.internalError
                }
                
                var dbSource = Source(
                    name: source.name,
                    icon: iconPath.path,
                    path: source.path,
                    hostId: hostId
                )
                
                dbSource = try dbSource.insertAndFetch(db)
                guard let sourceId = dbSource.id else { throw ApplicationError.internalError }
                
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
}

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
    
    private func downloadAndSaveImage(sourceName: String, url: URL, folderURL: URL) async throws {
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

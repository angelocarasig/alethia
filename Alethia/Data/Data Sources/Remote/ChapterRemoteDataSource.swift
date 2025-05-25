//
//  ChapterRemoteDataSource.swift
//  Alethia
//
//  Created by Angelo Carasig on 7/5/2025.
//

import Foundation

final class ChapterRemoteDataSource {
    func getChapterContents(chapter: Chapter) async throws -> [String] {
        let ns = NetworkService()
        
        let url: URL = try await DatabaseProvider.shared.reader.read { db in
            guard let origin = try Origin.filter(id: chapter.originId).fetchOne(db) else {
                throw OriginError.notFound
            }
            
            guard let source = try Source.filter(id: origin.sourceId).fetchOne(db) else {
                throw SourceError.notFound
            }
            
            guard let host = try Host.filter(id: source.hostId).fetchOne(db) else {
                throw HostError.notFound
            }
            
            guard let url = URL.appendingPaths(
                host.baseUrl,
                source.path,
                "chapter",
                chapter.slug
            )
            else {
                let reason = "Failed to append URL paths: \(host.baseUrl), \(source.path), chapter, \(chapter.slug)"
                throw ApplicationError.urlBuildingFailed(reason)
            }
            
            return url
        }
        
        let contents: [String] = try await ns.request(url: url)
        
        guard !contents.isEmpty else {
            throw ChapterError.noContent
        }
        
        return contents
    }
}

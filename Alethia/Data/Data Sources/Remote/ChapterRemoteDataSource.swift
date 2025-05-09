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
            guard let origin = try Origin.filter(id: chapter.originId).fetchOne(db),
                  let source = try Source.filter(id: origin.sourceId).fetchOne(db),
                  let host = try Host.filter(id: source.hostId).fetchOne(db),
                  let url = URL.appendingPaths(
                    host.baseUrl,
                    source.path,
                    "chapter",
                    chapter.slug
                )
            else { throw ApplicationError.internalError }
            
            return url
        }
        
        return try await ns.request(url: url)
    }
}

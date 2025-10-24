//
//  ChapterRemoteDataSource.swift
//  Data
//
//  Created by Angelo Carasig on 22/10/2025.
//

import Foundation
import Domain

internal protocol ChapterRemoteDataSource: Sendable {
    /// fetches chapter contents from remote host
    /// - parameters:
    ///   - sourceSlug: slug of the source
    ///   - mangaId: id of the manga
    ///   - chapterSlug: slug of the chapter
    ///   - hostURL: base url of the host
    /// - returns: dto containing page urls
    func fetchChapterContents(sourceSlug: String, mangaId: Int64, chapterSlug: String, hostURL: URL) async throws -> [String]
}

internal final class ChapterRemoteDataSourceImpl: ChapterRemoteDataSource {
    private let networkService: NetworkService
    
    init(networkService: NetworkService? = nil) {
        self.networkService = networkService ?? NetworkService()
    }
    
    func fetchChapterContents(sourceSlug: String, mangaId: Int64, chapterSlug: String, hostURL: URL) async throws -> [String] {
        // build url: {{host_base_url}}/{{source_slug}}/{{mangaId}}/chapters/{{chapterSlug}}
        let url = hostURL
            .appendingPathComponent(sourceSlug)
            .appendingPathComponent(String(mangaId))
            .appendingPathComponent("chapters")
            .appendingPathComponent(chapterSlug)
        
        do {
            return try await networkService.request(url: url)
        } catch let error as NetworkError {
            throw error
        } catch {
            throw NetworkError.requestFailed(underlyingError: error as? URLError ?? URLError(.unknown))
        }
    }
}

//
//  MangaRemoteDataSource.swift
//  Data
//
//  Created by Angelo Carasig on 6/10/2025.
//

import Foundation
import Domain

internal protocol MangaRemoteDataSource: Sendable {
    func fetchManga(sourceSlug: String, entrySlug: String, hostURL: URL) async throws -> MangaDTO
    func fetchChapters(sourceSlug: String, entrySlug: String, hostURL: URL) async throws -> [ChapterDTO]
}

internal final class MangaRemoteDataSourceImpl: MangaRemoteDataSource {
    private let networkService: NetworkService
    
    init(networkService: NetworkService? = nil) {
        self.networkService = networkService ?? NetworkService()
    }
    
    func fetchManga(sourceSlug: String, entrySlug: String, hostURL: URL) async throws -> MangaDTO {
        // build url: {{host.url}}/{{source.slug}}/{{entry.slug}}
        let url = hostURL
            .appendingPathComponent(sourceSlug)
            .appendingPathComponent(entrySlug)
        
        do {
            return try await networkService.request(url: url)
        } catch let error as NetworkError {
            throw error
        } catch {
            throw NetworkError.requestFailed(underlyingError: error as? URLError ?? URLError(.unknown))
        }
    }
    
    func fetchChapters(sourceSlug: String, entrySlug: String, hostURL: URL) async throws -> [ChapterDTO] {
        // build url: {{host.url}}/{{source.slug}}/{{entry.slug}}/chapters
        let url = hostURL
            .appendingPathComponent(sourceSlug)
            .appendingPathComponent(entrySlug)
            .appendingPathComponent("chapters")
        
        do {
            return try await networkService.request(url: url)
        } catch let error as NetworkError {
            throw error
        } catch {
            throw NetworkError.requestFailed(underlyingError: error as? URLError ?? URLError(.unknown))
        }
    }
}

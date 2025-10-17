//
//  SearchRemoteDataSource.swift
//  Data
//
//  Created by Angelo Carasig on 5/10/2025.
//

import Foundation
import Domain

internal protocol SearchRemoteDataSource: Sendable {
    func searchWithPreset(sourceSlug: String, host: URL, preset: SearchPreset) async throws -> SearchResponseDTO
    func search(sourceSlug: String, host: URL, request: SearchRequestDTO) async throws -> SearchResponseDTO
}

internal final class SearchRemoteDataSourceImpl: SearchRemoteDataSource {
    private let networkService: NetworkService
    
    init(networkService: NetworkService? = nil) {
        self.networkService = networkService ?? NetworkService()
    }
    
    func searchWithPreset(sourceSlug: String, host: URL, preset: SearchPreset) async throws -> SearchResponseDTO {
        let searchURL = host
            .appendingPathComponent(sourceSlug)
            .appendingPathComponent("search")
        
        let requestDTO = SearchRequestDTO(
            query: "",
            page: 1,
            limit: 20,
            sort: preset.sortOption,
            direction: preset.sortDirection,
            filters: preset.filters
        )
        
        do {
            return try await networkService.requestWithBody(url: searchURL, body: requestDTO)
        } catch let error as NetworkError {
            throw error
        } catch {
            throw NetworkError.requestFailed(underlyingError: error as? URLError ?? URLError(.unknown))
        }
    }
    
    func search(sourceSlug: String, host: URL, request: SearchRequestDTO) async throws -> SearchResponseDTO {
        let searchURL = host
            .appendingPathComponent(sourceSlug)
            .appendingPathComponent("search")
        
        do {
            return try await networkService.requestWithBody(url: searchURL, body: request)
        } catch let error as NetworkError {
            throw error
        } catch {
            throw NetworkError.requestFailed(underlyingError: error as? URLError ?? URLError(.unknown))
        }
    }
}

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
        // construct search endpoint url
        let searchURL = host
            .appendingPathComponent(sourceSlug)
            .appendingPathComponent("search")
        
        // build request dto from preset
        let requestDTO = SearchRequestDTO(
            query: "",
            page: 1,
            limit: 20,
            sort: preset.sortOption,
            direction: preset.sortDirection,
            filters: preset.filters
        )
        
        // encode request body
        let encoder = JSONEncoder()
        let bodyData = try encoder.encode(requestDTO)
        
        // create request
        var request = URLRequest(url: searchURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = bodyData
        
        // make request
        let (data, response) = try await URLSession.shared.data(for: request)
        try networkService.handleResponse(response)
        
        // decode response
        let decoder = JSONDecoder()
        return try decoder.decode(SearchResponseDTO.self, from: data)
    }
    
    func search(sourceSlug: String, host: URL, request: SearchRequestDTO) async throws -> SearchResponseDTO {
        // construct search endpoint url
        let searchURL = host
            .appendingPathComponent(sourceSlug)
            .appendingPathComponent("search")
        
        // encode request body
        let encoder = JSONEncoder()
        let bodyData = try encoder.encode(request)
        
        // create http request
        var httpRequest = URLRequest(url: searchURL)
        httpRequest.httpMethod = "POST"
        httpRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        httpRequest.httpBody = bodyData
        
        // make request
        let (data, response) = try await URLSession.shared.data(for: httpRequest)
        try networkService.handleResponse(response)
        
        // decode response
        let decoder = JSONDecoder()
        return try decoder.decode(SearchResponseDTO.self, from: data)
    }
}

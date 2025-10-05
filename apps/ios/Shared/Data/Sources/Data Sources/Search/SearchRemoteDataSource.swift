//
//  SearchRemoteDataSource.swift
//  Data
//
//  Created by Angelo Carasig on 5/10/2025.
//

import Foundation
import Domain

public final class SearchRemoteDataSource: Sendable {
    private let networkService: NetworkService
    
    public init(networkService: NetworkService? = nil) {
        self.networkService = networkService ?? NetworkService()
    }
    
    public func searchWithPreset(sourceSlug: String, host: URL, preset: SearchPreset) async throws -> [Entry] {
        // construct the search endpoint url
        let searchURL = host
            .appendingPathComponent(sourceSlug)
            .appendingPathComponent("search")
        
        // build request body from preset
        // presetrequest already handles the complex encoding internally
        let requestBody = PresetRequest(
            query: "",  // presets typically don't include query text
            page: 1,
            limit: 20,
            sort: preset.sortOption.rawValue,
            direction: preset.sortDirection == .ascending ? "asc" : "desc",
            filters: preset.filters
        )
        
        // encode request body - presetrequest's custom encoder handles the conversion
        let encoder = JSONEncoder()
        let bodyData = try encoder.encode(requestBody)
        
        // create request
        var request = URLRequest(url: searchURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = bodyData
        
        // make request
        let (data, response) = try await URLSession.shared.data(for: request)
        try networkService.handleResponse(response)
        
        // decode response to dto
        let decoder = JSONDecoder()
        let searchResponse = try decoder.decode(SearchResponseDTO.self, from: data)
        
        // map dto to domain entities
        return searchResponse.results.map { dto in
            Entry(
                slug: dto.slug,
                title: dto.title,
                cover: dto.cover,
                state: .noMatch
            )
        }
    }
}

// dto for response shape
private struct SearchResponseDTO: Codable {
    let results: [EntryDTO]
    let page: Int
    let more: Bool
}

private struct EntryDTO: Codable {
    let slug: String
    let title: String
    let cover: URL
}

//
//  SearchPresetManifest.swift
//  Domain
//
//  Created by Angelo Carasig on 5/10/2025.
//

import Foundation

public struct SearchPresetManifest: Codable, Sendable {
    public let name: String
    public let description: String?
    public let request: PresetRequest
}

/// The request portion of a search preset
public struct PresetRequest: Codable, Sendable {
    public let query: String
    public let page: Int
    public let limit: Int
    public let sort: String
    public let direction: String
    public let filters: [String: FilterValue]?
    
    public init(
        query: String,
        page: Int,
        limit: Int,
        sort: String,
        direction: String,
        filters: [String : FilterValue]?
    ) {
        self.query = query
        self.page = page
        self.limit = limit
        self.sort = sort
        self.direction = direction
        self.filters = filters
    }
}

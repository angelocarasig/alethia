//
//  SourceManifest.swift
//  Domain
//
//  Created by Angelo Carasig on 4/10/2025.
//

import Foundation

/// Represents a source within a host manifest.
/// Contains all configuration and capabilities for a single manga source.
public struct SourceManifest: Codable, Sendable {
    public let name: String
    public let slug: String
    public let icon: URL
    public let languages: [String]
    public let nsfw: Bool
    public let url: URL
    public let referer: URL
    public let auth: SourceAuthManifest
    public let search: SourceSearchManifest
    public let presets: [SearchPresetManifest]
    
    public init(
        name: String,
        slug: String,
        icon: URL,
        languages: [String],
        nsfw: Bool,
        url: URL,
        referer: URL,
        auth: SourceAuthManifest,
        search: SourceSearchManifest,
        presets: [SearchPresetManifest]
    ) {
        self.name = name
        self.slug = slug
        self.icon = icon
        self.languages = languages
        self.nsfw = nsfw
        self.url = url
        self.referer = referer
        self.auth = auth
        self.search = search
        self.presets = presets
    }
}

/// Represents authentication configuration for a source.
public struct SourceAuthManifest: Codable, Sendable {
    public let type: AuthType
    public let required: Bool
    
    public init(type: AuthType, required: Bool) {
        self.type = type
        self.required = required
    }
    
    // custom decoding to handle string -> enum with validation
    private enum CodingKeys: String, CodingKey {
        case type, required
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let typeString = try container.decode(String.self, forKey: .type)
        
        guard let authType = AuthType(rawValue: typeString) else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: decoder.codingPath + [CodingKeys.type],
                    debugDescription: "Unknown auth type: '\(typeString)'"
                )
            )
        }
        
        self.type = authType
        self.required = try container.decode(Bool.self, forKey: .required)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type.rawValue, forKey: .type)
        try container.encode(required, forKey: .required)
    }
}

/// Represents search capabilities and configuration for a source.
public struct SourceSearchManifest: Codable, Sendable {
    public let sort: [SortOption]
    public let filters: [FilterOption]
    public let tags: [SearchTag]
    
    public init(
        sort: [SortOption],
        filters: [FilterOption],
        tags: [SearchTag]
    ) {
        self.sort = sort
        self.filters = filters
        self.tags = tags
    }
    
    // custom decoding to handle string arrays -> enum arrays with validation
    private enum CodingKeys: String, CodingKey {
        case sort, filters, tags
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // decode and validate sort options
        let sortStrings = try container.decode([String].self, forKey: .sort)
        var mappedSorts: [SortOption] = []
        var unmappedSorts: [String] = []
        
        for sortString in sortStrings {
            if let option = SortOption(rawValue: sortString) {
                mappedSorts.append(option)
            } else {
                unmappedSorts.append(sortString)
            }
        }
        
        guard unmappedSorts.isEmpty else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: decoder.codingPath + [CodingKeys.sort],
                    debugDescription: "Unknown sort options: \(unmappedSorts.joined(separator: ", "))"
                )
            )
        }
        
        // decode and validate filter options
        let filterStrings = try container.decode([String].self, forKey: .filters)
        var mappedFilters: [FilterOption] = []
        var unmappedFilters: [String] = []
        
        for filterString in filterStrings {
            if let option = FilterOption(rawValue: filterString) {
                mappedFilters.append(option)
            } else {
                unmappedFilters.append(filterString)
            }
        }
        
        guard unmappedFilters.isEmpty else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: decoder.codingPath + [CodingKeys.filters],
                    debugDescription: "Unknown filter options: \(unmappedFilters.joined(separator: ", "))"
                )
            )
        }
        
        self.sort = mappedSorts
        self.filters = mappedFilters
        self.tags = try container.decode([SearchTag].self, forKey: .tags)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(sort.map { $0.rawValue }, forKey: .sort)
        try container.encode(filters.map { $0.rawValue }, forKey: .filters)
        try container.encode(tags, forKey: .tags)
    }
}

//
//  SourcePresetDTO.swift
//  Domain
//
//  Created by Angelo Carasig on 5/10/2025.
//

public struct SourcePresetDTO: Codable, Sendable {
    public let name: String
    public let description: String?
    public let request: PresetRequestDTO
}

public struct PresetRequestDTO: Codable, Sendable {
    public let query: String
    public let page: Int
    public let limit: Int
    public let sort: Search.Options.Sort
    public let direction: SortDirection
    public let filters: [Search.Options.Filter: Search.Options.FilterValue]?
    
    private enum CodingKeys: String, CodingKey {
        case query, page, limit, sort, direction, filters
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        query = try container.decode(String.self, forKey: .query)
        page = try container.decode(Int.self, forKey: .page)
        limit = try container.decode(Int.self, forKey: .limit)
        sort = try container.decode(Search.Options.Sort.self, forKey: .sort)
        direction = try container.decode(SortDirection.self, forKey: .direction)
        
        // for filters we need to decode a bit different
        if let rawFilters = try container.decodeIfPresent([String: Search.Options.FilterValue].self, forKey: .filters) {
            var typedFilters = [Search.Options.Filter: Search.Options.FilterValue]()
            for (key, value) in rawFilters {
                if let filterOption = Search.Options.Filter(rawValue: key) {
                    typedFilters[filterOption] = value
                }
            }
            filters = typedFilters.isEmpty ? nil : typedFilters
        } else {
            filters = nil
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(query, forKey: .query)
        try container.encode(page, forKey: .page)
        try container.encode(limit, forKey: .limit)
        try container.encode(sort, forKey: .sort)
        try container.encode(direction, forKey: .direction)
        
        if let filters = filters {
            var rawFilters = [String: Search.Options.FilterValue]()
            for (key, value) in filters {
                rawFilters[key.rawValue] = value
            }
            try container.encode(rawFilters, forKey: .filters)
        }
    }
}

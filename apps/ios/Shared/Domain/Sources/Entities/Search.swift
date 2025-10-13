//
//  Search.swift
//  Domain
//
//  Created by Angelo Carasig on 27/9/2025.
//

import Foundation

public struct Search: Sendable {
    public let options: Options
    public let tags: [SearchTag]
    public let presets: [SearchPreset]
    
    public init(
        supportedSorts: [Options.Sort],
        supportedFilters: [Options.Filter],
        tags: [SearchTag],
        presets: [SearchPreset]
    ) {
        self.options = Options(
            sorting: supportedSorts,
            filtering: supportedFilters
        )
        self.tags = tags
        self.presets = presets
    }
    
    public struct Options: Sendable {
        public let sorting: [Sort]
        public let filtering: [Filter]
        
        public init(sorting: [Sort], filtering: [Filter]) {
            self.sorting = sorting
            self.filtering = filtering
        }
    }
}

public extension Search.Options {
    enum Sort: String, CaseIterable, Codable, Sendable {
        case title = "title"
        case year = "year"
        case createdAt = "createdAt"
        case updatedAt = "updatedAt"
        case relevance = "relevance"
        case popularity = "popularity"
        case rating = "rating"
        case chapters = "chapters"
        case follows = "follows"
        
        public var displayName: String {
            switch self {
            case .title: return "Title"
            case .year: return "Year"
            case .createdAt: return "Date Added"
            case .updatedAt: return "Last Updated"
            case .relevance: return "Relevance"
            case .popularity: return "Popularity"
            case .rating: return "Rating"
            case .chapters: return "Chapter Count"
            case .follows: return "Follows"
            }
        }
    }
    
    enum Filter: String, CaseIterable, Codable, Hashable, Sendable {
        case year = "year"
        case includeTag = "includeTag"
        case excludeTag = "excludeTag"
        case status = "status"
        case originalLanguage = "originalLanguage"
        case translatedLanguage = "translatedLanguage"
        case contentRating = "contentRating"
        case minChapters = "minChapters"
        
        public var displayName: String {
            switch self {
            case .year: return "Year"
            case .includeTag: return "Include Tags"
            case .excludeTag: return "Exclude Tags"
            case .status: return "Status"
            case .originalLanguage: return "Original Language"
            case .translatedLanguage: return "Translated Language"
            case .contentRating: return "Content Rating"
            case .minChapters: return "Minimum Chapter Count"
            }
        }
    }
    
    enum FilterValue: Codable, Hashable, Sendable, Equatable {
        case string(String)
        case stringArray([String])
        case number(Int)
        case boolean(Bool)
        
        public init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            
            if let intValue = try? container.decode(Int.self) {
                self = .number(intValue)
            } else if let boolValue = try? container.decode(Bool.self) {
                self = .boolean(boolValue)
            } else if let arrayValue = try? container.decode([String].self) {
                self = .stringArray(arrayValue)
            } else if let stringValue = try? container.decode(String.self) {
                self = .string(stringValue)
            } else {
                throw DecodingError.typeMismatch(
                    FilterValue.self,
                    DecodingError.Context(
                        codingPath: decoder.codingPath,
                        debugDescription: "Unable to decode FilterValue"
                    )
                )
            }
        }
        
        public func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            switch self {
            case .string(let value):
                try container.encode(value)
            case .stringArray(let values):
                try container.encode(values)
            case .number(let value):
                try container.encode(value)
            case .boolean(let value):
                try container.encode(value)
            }
        }
    }
}

public struct SearchTag: Equatable, Codable, Sendable {
    public let slug: String
    public let name: String
    public let nsfw: Bool
    
    public init(slug: String, name: String, nsfw: Bool) {
        self.slug = slug
        self.name = name
        self.nsfw = nsfw
    }
}

public struct SearchPreset: Sendable, Hashable {
    public let id: Int64
    public let name: String
    public let description: String?
    public let filters: [Search.Options.Filter: Search.Options.FilterValue]
    public let sortOption: Search.Options.Sort
    public let sortDirection: SortDirection
    
    public init(
        id: Int64,
        name: String,
        description: String?,
        filters: [Search.Options.Filter: Search.Options.FilterValue] = [:],
        sortOption: Search.Options.Sort = .relevance,
        sortDirection: SortDirection = .descending
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.filters = filters
        self.sortOption = sortOption
        self.sortDirection = sortDirection
    }
}

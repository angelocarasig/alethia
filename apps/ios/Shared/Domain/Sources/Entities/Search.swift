//
//  Search.swift
//  Domain
//
//  Created by Angelo Carasig on 27/9/2025.
//

import Foundation

public struct Search {
    public let supportedSorts: [SortOption]
    public let supportedFilters: [FilterOption]
    public let tags: [SearchTag]
    public let presets: [SearchPreset]
}

/// Source-specific supported sort options
public enum SortOption: String, CaseIterable, Codable {
    case alphabetical
    case chapters
    case createdAt
    case follows
    case latest
    case popularity
    case rating
    case relevance
    case title
    case updatedAt
    case views
    case year
    
    public var displayName: String {
        switch self {
        case .alphabetical: "A-Z"
        case .chapters: "Chapter Count"
        case .createdAt: "Date Added"
        case .follows: "Follows"
        case .latest: "Latest"
        case .popularity: "Popularity"
        case .rating: "Rating"
        case .relevance: "Relevance"
        case .title: "Title"
        case .updatedAt: "Last Updated"
        case .views: "Views"
        case .year: "Year"
        }
    }
}

/// Source-specific supported filter options
public enum FilterOption: String, CaseIterable, Codable {
    /// Content categorization filters
    case genre
    case demographic
    
    /// Content metadata filters
    case status
    case contentRating
    case year
    
    /// Language filters
    case originalLanguage
    case translatedLanguage
    
    /// Creator filters
    case author
    case artist
    case publisher
    
    /// Tag filters
    case includeTag
    case excludeTag
    
    public var displayName: String {
        switch self {
        case .genre: "Genre"
        case .demographic: "Demographic"
        case .status: "Status"
        case .contentRating: "Content Rating"
        case .year: "Year"
        case .originalLanguage: "Original Language"
        case .translatedLanguage: "Translated Language"
        case .author: "Author"
        case .artist: "Artist"
        case .publisher: "Publisher"
        case .includeTag: "Include Tags"
        case .excludeTag: "Exclude Tags"
        }
    }
    
    public var expectedType: FilterValueType {
        switch self {
        case .status, .contentRating, .originalLanguage,
             .translatedLanguage, .author, .artist, .publisher:
            return .string
        case .genre, .includeTag, .excludeTag, .demographic:
            return .stringArray
        case .year:
            return .number
        }
    }
}

/// Associated value for a given filter option
public enum FilterValue: Codable, Equatable {
    case string(String)
    case stringArray([String])
    case number(Int)
    case boolean(Bool)
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode([String].self) {
            self = .stringArray(value)
        } else if let value = try? container.decode(Int.self) {
            self = .number(value)
        } else if let value = try? container.decode(Bool.self) {
            self = .boolean(value)
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
        case .string(let value): try container.encode(value)
        case .stringArray(let values): try container.encode(values)
        case .number(let value): try container.encode(value)
        case .boolean(let value): try container.encode(value)
        }
    }
}

/// Maps directly to filter values and correlates to the type
public enum FilterValueType {
    case string, stringArray, number, boolean
    
    func matches(_ value: FilterValue) -> Bool {
        switch (self, value) {
        case (.string, .string),
            (.stringArray, .stringArray),
            (.number, .number),
            (.boolean, .boolean):
            return true
        default:
            return false
        }
    }
}

/// A tag option available for a given source with include/exclude tag supported filter option
public struct SearchTag: Equatable, Codable {
    public let slug: String
    public let name: String
    public let nsfw: Bool
}

/// Source-specific preset for a search config
public struct SearchPreset {
    public let id: Int64
    public let name: String
    public let filters: [FilterOption: FilterValue]
    public let sortOption: SortOption
    public let sortDirection: SortDirection
    public let tags: [SearchTag]
    
    public init(
        id: Int64,
        name: String,
        filters: [FilterOption: FilterValue] = [:],
        sortOption: SortOption = .relevance,
        sortDirection: SortDirection = .descending,
        tags: [SearchTag] = []
    ) {
        self.id = id
        self.name = name
        self.filters = filters
        self.sortOption = sortOption
        self.sortDirection = sortDirection
        self.tags = tags
    }
    
    public var isValid: Bool {
        filters.allSatisfy { $0.key.expectedType.matches($0.value) }
    }
}

#warning("TODO - Move to different layer")
public struct SearchRequest {
    public let query: String
    public let page: Int
    public let limit: Int
    public let sort: SortOption
    public let direction: SortDirection
    public let filters: [String: FilterValue]?
    
    public init(
        query: String = "",
        page: Int = 1,
        limit: Int = Constants.Search.defaultPageSize,
        sort: SortOption = .relevance,
        direction: SortDirection = .descending,
        filters: [FilterOption: FilterValue]? = nil
    ) {
        self.query = query
        self.page = max(1, page)
        self.limit = min(Constants.Search.maxResults, max(1, limit))
        self.sort = sort
        self.direction = direction
        self.filters = filters?.reduce(into: [:]) { $0[$1.key.rawValue] = $1.value }
    }
}

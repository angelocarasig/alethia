//
//  SearchRequest.swift
//  Domain
//
//  Created by Angelo Carasig on 4/10/2025.
//

import Foundation

public struct SearchRequest: Sendable {
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

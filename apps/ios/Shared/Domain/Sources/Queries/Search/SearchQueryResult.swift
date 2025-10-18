//
//  SearchQueryResult.swift
//  Domain
//
//  Created by Angelo Carasig on 18/10/2025.
//


public struct SearchQueryResult: Sendable {
    public let entries: [Entry]
    public let hasMore: Bool
    public let currentPage: Int
    public let totalCount: Int?
    
    public init(
        entries: [Entry],
        hasMore: Bool,
        currentPage: Int,
        totalCount: Int? = nil
    ) {
        self.entries = entries
        self.hasMore = hasMore
        self.currentPage = currentPage
        self.totalCount = totalCount
    }
    
    public static func empty() -> SearchQueryResult {
        SearchQueryResult(entries: [], hasMore: false, currentPage: 1, totalCount: 0)
    }
}

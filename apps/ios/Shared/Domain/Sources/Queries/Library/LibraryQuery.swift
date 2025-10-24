//
//  LibraryQuery.swift
//  Domain
//
//  Created by Angelo Carasig on 11/10/2025.
//

import Foundation

public struct LibraryQuery: Sendable, Equatable {
    public let sort: LibrarySort
    public let filters: LibraryFilters
    public let cursor: LibraryCursor?
    
    public init(
        sort: LibrarySort = LibrarySort(),
        filters: LibraryFilters = LibraryFilters(),
        cursor: LibraryCursor? = nil
    ) {
        self.sort = sort
        self.filters = filters
        self.cursor = cursor
    }
}

// MARK: - Sort Configuration

public struct LibrarySort: Sendable, Equatable {
    public let field: LibrarySortField
    public let direction: SortDirection
    
    public init(
        field: LibrarySortField = .alphabetical,
        direction: SortDirection = .ascending
    ) {
        self.field = field
        self.direction = direction
    }
}

public enum LibrarySortField: String, CaseIterable, Sendable {
    case alphabetical = "title"
    case lastRead = "lastReadAt"
    case lastUpdated = "updatedAt"
    case unreadCount = "unreadCount"
    case dateAdded = "addedAt"
    case chapterCount = "chapterCount"
    
    public var displayName: String {
        switch self {
        case .alphabetical: return "Alphabetical"
        case .lastRead: return "Last Read"
        case .lastUpdated: return "Last Updated"
        case .unreadCount: return "Unread Count"
        case .dateAdded: return "Date Added"
        case .chapterCount: return "Chapter Count"
        }
    }
    
    public var icon: String {
        switch self {
        case .alphabetical: return "textformat"
        case .lastRead: return "book"
        case .lastUpdated: return "clock"
        case .unreadCount: return "circle.badge"
        case .dateAdded: return "calendar"
        case .chapterCount: return "number"
        }
    }
}

// MARK: - Filter Configuration

public struct LibraryFilters: Sendable, Equatable {
    public let search: String?
    public let collectionId: Int64?
    public let sourceIds: Set<Int64>
    public let statuses: Set<Status>
    public let classifications: Set<Classification>
    public let addedDate: DateFilter
    public let updatedDate: DateFilter
    public let unreadOnly: Bool
    public let downloadedOnly: Bool
    
    public init(
        search: String? = nil,
        collectionId: Int64? = nil,
        sourceIds: Set<Int64> = [],
        statuses: Set<Status> = [],
        classifications: Set<Classification> = [],
        addedDate: DateFilter = DateFilter(type: .none),
        updatedDate: DateFilter = DateFilter(type: .none),
        unreadOnly: Bool = false,
        downloadedOnly: Bool = false
    ) {
        // trim and nilify empty search strings
        self.search = search?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty()
        self.collectionId = collectionId
        self.sourceIds = sourceIds
        self.statuses = statuses
        self.classifications = classifications
        self.addedDate = addedDate
        self.updatedDate = updatedDate
        self.unreadOnly = unreadOnly
        self.downloadedOnly = downloadedOnly
    }
    
    public var isEmpty: Bool {
        search == nil &&
        collectionId == nil &&
        sourceIds.isEmpty &&
        statuses.isEmpty &&
        classifications.isEmpty &&
        !addedDate.isActive &&
        !updatedDate.isActive &&
        !unreadOnly &&
        !downloadedOnly
    }
    
    public var activeFilterCount: Int {
        var count = 0
        if search != nil { count += 1 }
        if collectionId != nil { count += 1 }
        if !sourceIds.isEmpty { count += 1 }
        if !statuses.isEmpty { count += 1 }
        if !classifications.isEmpty { count += 1}
        if addedDate.isActive { count += 1 }
        if updatedDate.isActive { count += 1 }
        if unreadOnly { count += 1 }
        if downloadedOnly { count += 1 }
        return count
    }
}

// MARK: - Date Filter

public struct DateFilter: Sendable, Equatable, Hashable {
    public enum FilterType: Sendable, Equatable, Hashable {
        case none
        case before(Date)
        case after(Date)
        case between(start: Date, end: Date)
    }
    
    public let type: FilterType
    
    public init(type: FilterType) {
        self.type = type
    }
    
    // convenience constructors
    public static func none() -> DateFilter {
        DateFilter(type: .none)
    }
    
    public static func before(_ date: Date) -> DateFilter {
        DateFilter(type: .before(date))
    }
    
    public static func after(_ date: Date) -> DateFilter {
        DateFilter(type: .after(date))
    }
    
    public static func between(start: Date, end: Date) -> DateFilter {
        DateFilter(type: .between(start: start, end: end))
    }
    
    // helper computed properties
    public var isActive: Bool {
        switch type {
        case .none: return false
        default: return true
        }
    }
    
    public var displayText: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        
        switch type {
        case .none:
            return "None"
        case .before(let date):
            return "Before \(formatter.string(from: date))"
        case .after(let date):
            return "After \(formatter.string(from: date))"
        case .between(let start, let end):
            return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
        }
    }
}

// MARK: - Cursor for Pagination

public struct LibraryCursor: Sendable, Equatable {
    public let afterId: Int64?
    public let limit: Int
    
    public init(afterId: Int64? = nil, limit: Int = 50) {
        self.afterId = afterId
        self.limit = limit
    }
    
    public static let initial = LibraryCursor(afterId: nil, limit: 50)
    
    public func next(from lastId: Int64?) -> LibraryCursor {
        LibraryCursor(afterId: lastId, limit: limit)
    }
}

// MARK: - Query Result

public struct LibraryQueryResult: Sendable {
    public let entries: [Entry]
    public let hasMore: Bool
    public let nextCursor: LibraryCursor?
    public let totalCount: Int?
    
    public init(
        entries: [Entry],
        hasMore: Bool,
        nextCursor: LibraryCursor? = nil,
        totalCount: Int? = nil
    ) {
        self.entries = entries
        self.hasMore = hasMore
        self.nextCursor = nextCursor
        self.totalCount = totalCount
    }
    
    public static func empty() -> LibraryQueryResult {
        LibraryQueryResult(entries: [], hasMore: false, nextCursor: nil, totalCount: 0)
    }
}

// MARK: - Helper Extensions

private extension String {
    func nilIfEmpty() -> String? {
        isEmpty ? nil : self
    }
}

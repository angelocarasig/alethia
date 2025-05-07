//
//  LibraryFilters.swift
//  Alethia
//
//  Created by Angelo Carasig on 7/5/2025.
//

import Foundation
import SwiftUI

/// TODO:
/// - Full text search (via fts5)
/// - tracking support
/// - manga with detached sources
struct LibraryFilters {
    // MARK: Basic
    var searchText: String = ""
    var collection: Collection? = nil
    
    // MARK: Sorting
    var sortType: LibrarySortType = .title
    var sortDirection: LibrarySortDirection = .descending
    
    // MARK: Dates
    var addedAt: LibraryDate = .none
    var updatedAt: LibraryDate = .none
    
    // MARK: Tags
    var tags: [LibraryTag] = []
    
    // MARK: Content Type
    var publishStatus: [PublishStatus] = []
    var contentRating: [Classification] = []
    
    enum FilterType {
        // excludes basic + sorting
        case date, tag(includes: Bool), contentType
        
        var color: Color {
            switch self {
            case .date:
                return .appOrange
            case .tag(let includes):
                return includes ? .appGreen : .appRed
            case .contentType:
                return .yellow
            }
        }
    }
    
    struct ActiveFilter: Identifiable {
        let id = UUID()
        
        let name: String
        let color: Color
        let type: FilterType
        
        init(name: String, type: FilterType) {
            self.name = name
            self.color = type.color
            self.type = type
        }
    }
    
    var activeFilters: [ActiveFilter] {
        var filters: [ActiveFilter] = []
        
        if addedAt != .none {
            filters.append(ActiveFilter(name: "Added At", type: .date))
        }
        
        if updatedAt != .none {
            filters.append(ActiveFilter(name: "Added At", type: .date))
        }
        
        if !tags.isEmpty {
            filters.append(
                contentsOf: tags.map {
                    ActiveFilter(
                        name: $0.tag.name,
                        type: .tag(includes: $0.inclusionType == .include)
                    )
                })
        }

        return filters
    }
    
    // Checks if default filters are applied
    var isEmpty: Bool {
        return
            addedAt == .none &&
            updatedAt == .none &&
            tags.isEmpty &&
            publishStatus.isEmpty &&
            contentRating.isEmpty
    }
    
    mutating func reset() {
        sortType = .title
        sortDirection = .descending
        addedAt = .none
        updatedAt = .none
        tags = []
        publishStatus = []
        contentRating = []
    }
}

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
    var classification: [Classification] = []
    
    enum FilterType {
        // excludes basic + sorting
        case date
        case tag(includes: Bool)
        case metadata
        
        var color: Color {
            switch self {
            case .date:                 return .appOrange
            case .metadata:             return .appOrange
            case .tag(let includes):    return includes ? .appGreen : .appRed
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
        
        filters.append(contentsOf: tags.map {
            ActiveFilter(name: $0.tag.name, type: .tag(includes: $0.inclusionType == .include))
        })
        
        filters.append(contentsOf: publishStatus.map {
            ActiveFilter(name: $0.rawValue, type: .metadata)
        })
        
        filters.append(contentsOf: classification.map {
            ActiveFilter(name: $0.rawValue, type: .metadata)
        })
        
        return filters
    }
    
    // Checks if default filters are applied
    var isEmpty: Bool {
        return  addedAt == .none &&
        updatedAt == .none &&
        tags.isEmpty &&
        publishStatus.isEmpty &&
        classification.isEmpty
    }
    
    mutating func reset() {
        sortType = .title
        sortDirection = .descending
        addedAt = .none
        updatedAt = .none
        tags = []
        publishStatus = []
        classification = []
    }
}

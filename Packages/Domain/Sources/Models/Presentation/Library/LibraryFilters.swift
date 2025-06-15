//
//  LibraryFilters.swift
//  Domain
//
//  Created by Angelo Carasig on 14/6/2025.
//

import Foundation
import SwiftUI

public extension Domain.Models.Presentation {
    struct LibraryFilters: Sendable {
        // MARK: Basic
        public var searchText: String = ""
        public var collection: Domain.Models.Persistence.Collection? = nil
        
        // MARK: Sorting
        public var sortType: LibrarySortType = .title
        public var sortDirection: LibrarySortDirection = .descending
        
        // MARK: Dates
        public var addedAt: LibraryDate = .none
        public var updatedAt: LibraryDate = .none
        
        // MARK: Tags
        public var tags: [LibraryTag] = []
        
        // MARK: Content Type
        public var publishStatus: [Domain.Models.Enums.PublishStatus] = []
        public var classification: [Domain.Models.Enums.Classification] = []
        
        public init() {
            
        }
        
        public init(
            searchText: String,
            collection: Domain.Models.Persistence.Collection? = nil,
            sortType: LibrarySortType,
            sortDirection: LibrarySortDirection,
            addedAt: LibraryDate,
            updatedAt: LibraryDate,
            tags: [LibraryTag],
            publishStatus: [Domain.Models.Enums.PublishStatus],
            classification: [Domain.Models.Enums.Classification]
        ) {
            self.searchText = searchText
            self.collection = collection
            self.sortType = sortType
            self.sortDirection = sortDirection
            self.addedAt = addedAt
            self.updatedAt = updatedAt
            self.tags = tags
            self.publishStatus = publishStatus
            self.classification = classification
        }
        
        public enum FilterType {
            // excludes basic + sorting
            case date
            case tag(includes: Bool)
            case metadata
            
            var color: Color {
                switch self {
                case .date:                 return .orange
                case .metadata:             return .orange
                case .tag(let includes):    return includes ? .green : .red
                }
            }
        }
        
        public struct ActiveFilter: Identifiable {
            public let id = UUID()
            
            public let name: String
            public let color: Color
            public let type: FilterType
            
            public init(name: String, type: FilterType) {
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
        
        func isPresent(_ filterType: FilterType) -> Bool {
            switch filterType {
            case .date:
                return addedAt != .none || updatedAt != .none
            case .metadata:
                return !publishStatus.isEmpty || !classification.isEmpty
            case .tag:
                return !tags.isEmpty
            }
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
}

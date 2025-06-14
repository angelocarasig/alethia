//
//  LibrarySortDirection.swift
//  Domain
//
//  Created by Angelo Carasig on 7/5/2025.
//

internal typealias LibrarySortDirection = Domain.Models.Presentation.LibrarySortDirection

public extension Domain.Models.Presentation {
    enum LibrarySortDirection: String {
        case descending = "Descending" // (A-Z)
        case ascending = "Ascending"  // (Z-A)
        
        mutating func toggle() {
            self = self == .ascending ? .descending : .ascending
        }
    }
}

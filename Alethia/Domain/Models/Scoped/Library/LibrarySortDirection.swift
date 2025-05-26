//
//  LibrarySortDirection.swift
//  Alethia
//
//  Created by Angelo Carasig on 7/5/2025.
//

import Foundation

enum LibrarySortDirection: String {
    case descending = "Descending" // (A-Z)
    case ascending = "Ascending"  // (Z-A)
    
    mutating func toggle() {
        self = self == .ascending ? .descending : .ascending
    }
}

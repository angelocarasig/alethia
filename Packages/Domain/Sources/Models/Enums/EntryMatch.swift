//
//  EntryMatch.swift
//  Domain
//
//  Created by Angelo Carasig on 14/6/2025.
//

typealias EntryMatch = Domain.Models.Enums.EntryMatch

public extension Domain.Models.Enums {
    /// matching property to indicate an entry's inclusive state in the library
    enum EntryMatch: Codable {
        /// does not exist in library at all
        case none
        
        /// found a title that can belong to the match
        case partial
        
        /// found exact match by ID
        case exact
    }
}

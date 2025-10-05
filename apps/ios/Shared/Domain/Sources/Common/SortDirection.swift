//
//  SortDirection.swift
//  Domain
//
//  Created by Angelo Carasig on 27/9/2025.
//

public enum SortDirection: String, Codable, Sendable {
    case ascending = "asc"
    case descending = "desc"
    
    public var displayName: String {
        switch self {
        case .ascending: return "Ascending"
        case .descending: return "Descending"
        }
    }
}

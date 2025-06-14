//
//  LibraryFilterTarget.swift
//  Domain
//
//  Created by Angelo Carasig on 10/5/2025.
//

internal typealias LibraryFilterTarget = Domain.Models.Presentation.LibraryFilterTarget

public extension Domain.Models.Presentation {
    enum LibraryFilterTarget {
        case addedAt
        case updatedAt
        case metadata
        case tags
    }
}

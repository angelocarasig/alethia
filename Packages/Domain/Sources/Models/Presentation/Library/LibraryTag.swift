//
//  LibraryTag.swift
//  Alethia
//
//  Created by Angelo Carasig on 7/5/2025.
//

internal typealias LibraryTag = Domain.Models.Presentation.LibraryTag

public extension Domain.Models.Presentation {
    struct LibraryTag: Sendable {
        let tag: Domain.Models.Persistence.Tag
        var inclusionType: InclusionType
        
        enum InclusionType {
            case include
            case exclude
        }
    }
}

//
//  LibraryTag.swift
//  Alethia
//
//  Created by Angelo Carasig on 7/5/2025.
//

internal typealias LibraryTag = Domain.Models.Presentation.LibraryTag

extension Domain.Models.Presentation {
    struct LibraryTag {
        let tag: Tag
        var inclusionType: InclusionType
        
        enum InclusionType {
            case include
            case exclude
        }
    }
}

//
//  LibraryTag.swift
//  Alethia
//
//  Created by Angelo Carasig on 7/5/2025.
//

import Foundation

struct LibraryTag {
    let tag: Tag
    var inclusionType: InclusionType
    
    enum InclusionType {
        case include
        case exclude
    }
}

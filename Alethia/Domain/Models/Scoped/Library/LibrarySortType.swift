//
//  LibrarySortType.swift
//  Alethia
//
//  Created by Angelo Carasig on 7/5/2025.
//

import Foundation

enum LibrarySortType: String, CaseIterable, Equatable, Identifiable {
    var id: String { self.rawValue }
    
    case title = "Title"
    case updated = "Date Updated"
    case added = "Date Added"
    case read = "Last Read"
}


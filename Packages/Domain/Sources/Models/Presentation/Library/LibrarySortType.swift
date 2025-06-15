//
//  LibrarySortType.swift
//  Alethia
//
//  Created by Angelo Carasig on 7/5/2025.
//

public extension Domain.Models.Presentation {
    enum LibrarySortType: String, CaseIterable, Equatable, Identifiable, Sendable {
        public var id: String { self.rawValue }
        
        case title = "Title"
        case updated = "Last Updated"
        case read = "Last Read"
        case added = "Date Added"
    }
}

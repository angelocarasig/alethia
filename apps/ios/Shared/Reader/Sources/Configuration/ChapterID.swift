//
//  ChapterID.swift
//  Reader
//
//  Created by Angelo Carasig on 22/10/2025.
//

import Foundation

/// sendable type-erased chapter identifier
public struct ChapterID: Hashable, Sendable {
    private let value: String
    
    init<ID: Hashable & Sendable>(_ id: ID) {
        // convert any hashable ID to a stable string representation
        self.value = String(describing: id)
    }
    
    public static func == (lhs: ChapterID, rhs: ChapterID) -> Bool {
        return lhs.value == rhs.value
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(value)
    }
}

//
//  ChapterOrdering.swift
//  Reader
//
//  Created by Angelo Carasig on 22/10/2025.
//

import Foundation

/// defines how chapters are ordered for navigation
public enum ChapterOrdering<Chapter: ReadableChapter>: Sendable {
    /// navigate by array index order
    case index
    
    /// custom navigation logic
    /// - Parameter closure: given current chapter id and all chapters, return next and previous chapters
    case custom(@Sendable (Chapter.ID, [Chapter]) -> (next: Chapter?, previous: Chapter?))
}

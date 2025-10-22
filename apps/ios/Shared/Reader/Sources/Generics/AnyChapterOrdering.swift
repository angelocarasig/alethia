//
//  AnyChapterOrdering.swift
//  Reader
//
//  Created by Angelo Carasig on 22/10/2025.
//

import Foundation

/// type-erased wrapper for ChapterOrdering
internal enum AnyChapterOrdering: Sendable {
    case index
    case custom(@Sendable (ChapterID, [AnyReadableChapter]) -> (next: AnyReadableChapter?, previous: AnyReadableChapter?))
    
    init<C: ReadableChapter>(_ ordering: ChapterOrdering<C>) {
        switch ordering {
        case .index:
            self = .index
            
        case .custom(let closure):
            self = .custom { chapterId, chapters in
                // find the chapter with matching ID
                guard let currentChapter = chapters.first(where: { $0.id == chapterId }),
                      let typedCurrent: C = currentChapter.asChapter() else {
                    return (next: nil, previous: nil)
                }
                
                let typedChapters = chapters.compactMap { $0.asChapter() as C? }
                let result = closure(typedCurrent.id, typedChapters)
                
                return (
                    next: result.next.map { AnyReadableChapter($0) },
                    previous: result.previous.map { AnyReadableChapter($0) }
                )
            }
        }
    }
}

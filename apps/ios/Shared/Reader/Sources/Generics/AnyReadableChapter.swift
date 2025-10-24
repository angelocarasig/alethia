//
//  AnyReadableChapter.swift
//  Reader
//
//  Created by Angelo Carasig on 22/10/2025.
//

import Foundation

/// type-erased wrapper for ReadableChapter
internal struct AnyReadableChapter: Hashable {
    let id: ChapterID
    private let _asAny: Any
    
    init<C: ReadableChapter>(_ chapter: C) {
        self.id = ChapterID(chapter.id)
        self._asAny = chapter
    }
    
    func asChapter<C: ReadableChapter>() -> C? {
        return _asAny as? C
    }
    
    static func == (lhs: AnyReadableChapter, rhs: AnyReadableChapter) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

extension AnyReadableChapter: @unchecked Sendable {}

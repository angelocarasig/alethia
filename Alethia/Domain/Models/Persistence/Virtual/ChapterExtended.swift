//
//  ChapterWithSource.swift
//  Alethia
//
//  Created by Angelo Carasig on 18/4/2025.
//

import Foundation
import GRDB

struct ChapterExtended: Decodable, FetchableRecord, Equatable {
    static func == (lhs: ChapterExtended, rhs: ChapterExtended) -> Bool {
        lhs.chapter.id == rhs.chapter.id
    }
    
    var chapter: Chapter
    var scanlator: Scanlator
    var origin: Origin
    var source: Source? // as origin can be detached
}

extension ChapterExtended: Identifiable {
    var id: String {
        chapter.slug
    }
}

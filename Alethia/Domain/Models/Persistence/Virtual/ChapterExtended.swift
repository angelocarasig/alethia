//
//  ChapterWithSource.swift
//  Alethia
//
//  Created by Angelo Carasig on 18/4/2025.
//

import Foundation
import GRDB

struct ChapterExtended: Codable, FetchableRecord {
    static func == (lhs: ChapterExtended, rhs: ChapterExtended) -> Bool {
        lhs.chapter.id == rhs.chapter.id
    }
    
    var chapter: Chapter
    var scanlator: Scanlator
    var origin: Origin
    var source: Source? // as origin can be detached
    
    static let placeholder: ChapterExtended = .init(
        chapter: .init(originId: -1, scanlatorId: -1, title: "", slug: "", number: 0.0, date: .distantPast),
        scanlator: .init(originId: -1, name: ""),
        origin: .init(mangaId: -1, slug: "", url: "", referer: "", classification: .Unknown, status: .Unknown, createdAt: .distantPast),
        source: .init(name: "", icon: "", path: "", hostId: -1)
    )
}

extension ChapterExtended: Identifiable, Hashable, Equatable {
    var id: String {
        chapter.slug
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

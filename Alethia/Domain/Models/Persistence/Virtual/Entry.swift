//
//  Entry.swift
//  Alethia
//
//  Created by Angelo Carasig on 10/4/2025.
//

import Foundation
import GRDB

enum EntryMatch {
    // Does not exist in library at all
    case none

    // Same title
    case partial

    // Exact ID
    case exact
}

struct Entry: Codable, Hashable, Identifiable, FetchableRecord, TableRecord {
    // MARK: Public API
    
    var id: String {
        fetchUrl ?? // fetchUrl is a stable unique value - may not exist if source not present
        "\(mangaId ?? sourceId ?? -1)-\(title)-\(unread)"
    }

    var transitionId: String {
        id
    }

    var mangaId: Int64?
    var sourceId: Int64?
    var title: String
    var cover: String?
    var fetchUrl: String?

    // MARK: Transient state
    var match: EntryMatch = .none
    var unread: Int

    // MARK: Decoding & GRDB
    private enum CodingKeys: String, CodingKey {
        case mangaId, sourceId, title, cover, fetchUrl, unread
    }

    enum Columns {
        static let mangaId = Column(CodingKeys.mangaId)
        static let sourceId = Column(CodingKeys.sourceId)
        static let title = Column(CodingKeys.title)
        static let cover = Column(CodingKeys.cover)
        static let fetchUrl = Column(CodingKeys.fetchUrl)
        static let unread = Column(CodingKeys.unread)
    }

    // Custom initializer
    init(
        mangaId: Int64? = nil,
        sourceId: Int64? = nil,
        title: String,
        cover: String? = nil,
        fetchUrl: String? = nil,
        unread: Int = -1,
        match: EntryMatch? = EntryMatch.none
    ) {
        self.mangaId = mangaId
        self.sourceId = sourceId
        self.title = title
        self.cover = cover
        self.fetchUrl = fetchUrl
        self.unread = unread
        self.match = match ?? .none
    }
}

struct RecommendedEntries {
    // Similar in your library
    let withSimilarTags: [Entry]
    
    // Others in same collection
    let fromSameCollection: [Entry]
    
    // Authors other works
    let otherWorksByAuthor: [Entry]
    
    // Scanlator's other series
    let otherSeriesByScanlator: [Entry]
}

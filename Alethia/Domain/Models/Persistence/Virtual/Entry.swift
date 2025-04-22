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

struct Entry: Codable, Hashable, FetchableRecord {
    var mangaId: Int64?
    var sourceId: Int64?
    
    var title: String
    var cover: String?
    var fetchUrl: String?
    
    // Transient
    var match: EntryMatch = .none
    var unread: Int?
    
    enum CodingKeys: String, CodingKey {
        case mangaId, sourceId, title, cover, fetchUrl
    }
    
    enum Columns {
        static let mangaId = Column(Entry.CodingKeys.mangaId)
        static let sourceId = Column(Entry.CodingKeys.sourceId)
        static let title = Column(Entry.CodingKeys.title)
        static let cover = Column(Entry.CodingKeys.cover)
        static let fetchUrl = Column(Entry.CodingKeys.fetchUrl)
    }
    
    init(
        mangaId: Int64? = nil,
        sourceId: Int64? = nil,
        title: String,
        cover: String? = nil,
        fetchUrl: String? = nil,
        unread: Int? = nil,
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

extension Entry {
    var transitionId: String {
        "\(sourceId ?? 0)-\(fetchUrl ?? title)"
    }
}

//
//  Entry.swift
//  Alethia
//
//  Created by Angelo Carasig on 10/4/2025.
//

import Foundation
import GRDB

struct Entry: Codable, FetchableRecord {
    var mangaId: Int64?
    var sourceId: Int64?
    
    var title: String
    var cover: String?
    var fetchUrl: String?
    var unread: Int?
    
    enum Columns {
        static let mangaId = Column(Entry.CodingKeys.mangaId)
        static let sourceId = Column(Entry.CodingKeys.sourceId)
        static let title = Column(Entry.CodingKeys.title)
        static let cover = Column(Entry.CodingKeys.cover)
        static let fetchUrl = Column(Entry.CodingKeys.fetchUrl)
        static let unread = Column(Entry.CodingKeys.unread)
    }
    
    init(
        mangaId: Int64? = nil,
        sourceId: Int64? = nil,
        title: String,
        cover: String? = nil,
        fetchUrl: String? = nil,
        unread: Int? = nil
    ) {
        self.mangaId = mangaId
        self.sourceId = sourceId
        self.title = title
        self.cover = cover
        self.fetchUrl = fetchUrl
        self.unread = unread
    }
}

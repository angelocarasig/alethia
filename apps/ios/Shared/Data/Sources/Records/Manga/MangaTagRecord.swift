//
//  MangaTagRecord.swift
//  Data
//
//  Created by Angelo Carasig on 28/9/2025.
//

import GRDB
import Tagged

internal struct MangaTagRecord: Codable {
    var mangaId: MangaRecord.ID
    var tagId: TagRecord.ID
}

extension MangaTagRecord: FetchableRecord, PersistableRecord {
    static var databaseTableName: String {
        "manga_tag"
    }
    
    enum Columns {
        static let mangaId = Column(CodingKeys.mangaId)
        static let tagId = Column(CodingKeys.tagId)
    }
}

extension MangaTagRecord {
    static let manga = belongsTo(MangaRecord.self)
    static let tag = belongsTo(TagRecord.self)
}

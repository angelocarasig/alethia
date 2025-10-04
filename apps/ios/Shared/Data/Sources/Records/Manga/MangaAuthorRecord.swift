//
//  MangaAuthorRecord.swift
//  Data
//
//  Created by Angelo Carasig on 28/9/2025.
//

import GRDB
import Tagged

internal struct MangaAuthorRecord: Codable {
    var mangaId: MangaRecord.ID
    var authorId: AuthorRecord.ID
}

extension MangaAuthorRecord: FetchableRecord, PersistableRecord {
    static var databaseTableName: String {
        "manga_author"
    }
    
    enum Columns {
        static let mangaId = Column(CodingKeys.mangaId)
        static let authorId = Column(CodingKeys.authorId)
    }
}

extension MangaAuthorRecord {
    static let manga = belongsTo(MangaRecord.self)
    static let author = belongsTo(AuthorRecord.self)
}

//
//  MangaCollectionRecord.swift
//  Data
//
//  Created by Angelo Carasig on 28/9/2025.
//

import Foundation
import GRDB
import Tagged

internal struct MangaCollectionRecord: Codable {
    var mangaId: MangaRecord.ID
    var collectionId: CollectionRecord.ID
    var order: Int = 0 // For custom ordering within collection
    var addedAt: Date = .now
}

extension MangaCollectionRecord: FetchableRecord, PersistableRecord {
    static var databaseTableName: String {
        "manga_collection"
    }
    
    enum Columns {
        static let mangaId = Column(CodingKeys.mangaId)
        static let collectionId = Column(CodingKeys.collectionId)
        static let order = Column(CodingKeys.order)
        static let addedAt = Column(CodingKeys.addedAt)
    }
}

extension MangaCollectionRecord {
    static let manga = belongsTo(MangaRecord.self)
    static let collection = belongsTo(CollectionRecord.self)
}

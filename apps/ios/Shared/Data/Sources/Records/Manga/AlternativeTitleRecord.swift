//
//  AlternativeTitleRecord.swift
//  Data
//
//  Created by Angelo Carasig on 28/9/2025.
//

import Foundation
import GRDB
import Tagged

internal struct AlternativeTitleRecord: Codable {
    typealias ID = Tagged<Self, Int64>
    private(set) var id: ID?
    
    var mangaId: MangaRecord.ID
    var title: String
}

extension AlternativeTitleRecord: FetchableRecord, MutablePersistableRecord {
    static var databaseTableName: String {
        "alternative_title"
    }
    
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let mangaId = Column(CodingKeys.mangaId)
        static let title = Column(CodingKeys.title)
    }
    
    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = ID(rawValue: inserted.rowID)
    }
}

extension AlternativeTitleRecord {
    static let manga = belongsTo(MangaRecord.self)
    
    var manga: QueryInterfaceRequest<MangaRecord> {
        request(for: AlternativeTitleRecord.manga)
    }
}

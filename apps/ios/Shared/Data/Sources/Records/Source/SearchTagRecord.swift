//
//  SearchTagRecord.swift
//  Data
//
//  Created by Angelo Carasig on 28/9/2025.
//

import Foundation
import GRDB
import Tagged

internal struct SearchTagRecord: Codable {
    typealias ID = Tagged<Self, Int64>
    private(set) var id: ID?
    
    private(set) var sourceId: SourceRecord.ID
    
    var slug: String
    var name: String
    var nsfw: Bool = false
}

extension SearchTagRecord: FetchableRecord, MutablePersistableRecord {
    static var databaseTableName: String {
        "search_tag"
    }
    
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let sourceId = Column(CodingKeys.sourceId)
        static let slug = Column(CodingKeys.slug)
        static let name = Column(CodingKeys.name)
        static let nsfw = Column(CodingKeys.nsfw)
    }
    
    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = ID(rawValue: inserted.rowID)
    }
}

extension SearchTagRecord {
    static let source = belongsTo(SourceRecord.self)
    
    var source: QueryInterfaceRequest<SourceRecord> {
        request(for: SearchTagRecord.source)
    }
}

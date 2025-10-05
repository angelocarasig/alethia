//
//  SearchPresetRecord.swift
//  Data
//
//  Created by Angelo Carasig on 28/9/2025.
//

import Foundation
import GRDB
import Tagged
import Domain

internal struct SearchPresetRecord: Codable {
    typealias ID = Tagged<Self, Int64>
    private(set) var id: ID?
    
    private(set) var sourceId: SourceRecord.ID
    
    var name: String
    var description: String?
    var request: Data // JSON-Encoded PresetRequest
    
    init(sourceId: SourceRecord.ID, name: String, description: String?, request: Data) {
        self.id = nil
        self.sourceId = sourceId
        self.name = name
        self.description = description
        self.request = request
    }
}

extension SearchPresetRecord: FetchableRecord, MutablePersistableRecord {
    static var databaseTableName: String {
        "search_preset"
    }
    
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let sourceId = Column(CodingKeys.sourceId)
        static let name = Column(CodingKeys.name)
        static let description = Column(CodingKeys.description)
        static let request = Column(CodingKeys.request)
    }
    
    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = ID(rawValue: inserted.rowID)
    }
}

extension SearchPresetRecord {
    static let source = belongsTo(SourceRecord.self)
    
    var source: QueryInterfaceRequest<SourceRecord> {
        request(for: SearchPresetRecord.source)
    }
}

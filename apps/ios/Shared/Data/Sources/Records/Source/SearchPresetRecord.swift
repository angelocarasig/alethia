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
    var filters: Data // JSON encoded [FilterOption: FilterValue]
    var sortOption: Domain.SortOption
    var sortDirection: Domain.SortDirection
    var tagIds: [SearchTagRecord.ID] = []
}

extension SearchPresetRecord: FetchableRecord, MutablePersistableRecord {
    static var databaseTableName: String {
        "search_preset"
    }
    
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let sourceId = Column(CodingKeys.sourceId)
        static let name = Column(CodingKeys.name)
        static let filters = Column(CodingKeys.filters)
        static let sortOption = Column(CodingKeys.sortOption)
        static let sortDirection = Column(CodingKeys.sortDirection)
        static let tagIds = Column(CodingKeys.tagIds)
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

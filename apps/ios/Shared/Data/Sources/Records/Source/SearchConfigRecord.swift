//
//  SearchConfigRecord.swift
//  Data
//
//  Created by Angelo Carasig on 28/9/2025.
//

import Foundation
import GRDB
import Tagged
import Domain

internal struct SearchConfigRecord: Codable {
    typealias ID = Tagged<Self, Int64>
    private(set) var id: ID?
    
    private(set) var sourceId: SourceRecord.ID
    
    var supportedSorts: [Domain.Search.Options.Sort] = []
    var supportedFilters: [Domain.Search.Options.Filter] = []
    
    init(
        sourceId: SourceRecord.ID,
        supportedSorts: [Domain.Search.Options.Sort],
        supportedFilters: [Domain.Search.Options.Filter]
    ) {
        self.id = nil
        self.sourceId = sourceId
        self.supportedSorts = supportedSorts
        self.supportedFilters = supportedFilters
    }
}

extension SearchConfigRecord: FetchableRecord, MutablePersistableRecord {
    static var databaseTableName: String {
        "search_config"
    }
    
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let sourceId = Column(CodingKeys.sourceId)
        static let supportedSorts = Column(CodingKeys.supportedSorts)
        static let supportedFilters = Column(CodingKeys.supportedFilters)
    }
    
    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = ID(rawValue: inserted.rowID)
    }
}

extension SearchConfigRecord {
    static let source = belongsTo(SourceRecord.self)
    
    var source: QueryInterfaceRequest<SourceRecord> {
        request(for: SearchConfigRecord.source)
    }
}

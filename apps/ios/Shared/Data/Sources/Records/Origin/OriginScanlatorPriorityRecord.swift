//
//  OriginScanlatorPriorityRecord.swift
//  Data
//
//  Created by Angelo Carasig on 28/9/2025.
//

import Foundation
import GRDB
import Tagged

internal struct OriginScanlatorPriorityRecord: Codable {
    typealias ID = Tagged<Self, Int64>
    private(set) var id: ID?
    
    private(set) var originId: OriginRecord.ID
    private(set) var scanlatorId: ScanlatorRecord.ID
    var priority: Int
    
    init(originId: OriginRecord.ID, scanlatorId: ScanlatorRecord.ID, priority: Int) {
        self.originId = originId
        self.scanlatorId = scanlatorId
        self.priority = priority
    }
}

extension OriginScanlatorPriorityRecord: FetchableRecord, MutablePersistableRecord {
    static var databaseTableName: String {
        "origin_scanlator_priority"
    }
    
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let originId = Column(CodingKeys.originId)
        static let scanlatorId = Column(CodingKeys.scanlatorId)
        static let priority = Column(CodingKeys.priority)
    }
    
    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = ID(rawValue: inserted.rowID)
    }
}

extension OriginScanlatorPriorityRecord {
    static let origin = belongsTo(OriginRecord.self)
    static let scanlator = belongsTo(ScanlatorRecord.self)
    
    var origin: QueryInterfaceRequest<OriginRecord> {
        request(for: OriginScanlatorPriorityRecord.origin)
    }
    
    var scanlator: QueryInterfaceRequest<ScanlatorRecord> {
        request(for: OriginScanlatorPriorityRecord.scanlator)
    }
}

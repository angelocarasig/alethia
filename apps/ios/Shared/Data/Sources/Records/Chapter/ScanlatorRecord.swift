//
//  ScanlatorRecord.swift
//  Data
//
//  Created by Angelo Carasig on 28/9/2025.
//

import Foundation
import GRDB
import Tagged
import Domain

internal struct ScanlatorRecord: Codable {
    typealias ID = Tagged<Self, Int64>
    private(set) var id: ID?
    
    var name: String
}

extension ScanlatorRecord: FetchableRecord, MutablePersistableRecord {
    static var databaseTableName: String {
        "scanlator"
    }
    
    enum Columns {
        static let id = Column(CodingKeys.id)
        
        static let name = Column(CodingKeys.name)
    }
    
    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = ID(rawValue: inserted.rowID)
    }
}

extension ScanlatorRecord {
    static let chapters = hasMany(ChapterRecord.self)
        .order(ChapterRecord.Columns.date.desc)
    
    var chapters: QueryInterfaceRequest<ChapterRecord> {
        request(for: ScanlatorRecord.chapters)
    }
}

extension ScanlatorRecord {
    static let originPriorities = hasMany(OriginScanlatorPriorityRecord.self)
    
    static let prioritizedOrigins = hasMany(
        OriginRecord.self,
        through: originPriorities,
        using: OriginScanlatorPriorityRecord.origin
    )
}

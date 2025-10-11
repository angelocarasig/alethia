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

internal struct ScanlatorRecord: Codable, DatabaseRecord {
    typealias ID = Tagged<Self, Int64>
    private(set) var id: ID?
    
    var name: String
}

// MARK: - DatabaseRecord

extension ScanlatorRecord {
    static var databaseTableName: String {
        "scanlator"
    }
    
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let name = Column(CodingKeys.name)
    }
    
    static func createTable(db: Database) throws {
        try db.create(table: databaseTableName, options: [.ifNotExists]) { t in
            t.autoIncrementedPrimaryKey(Columns.id.name)
            
            t.column(Columns.name.name, .text).notNull().unique()
        }
    }
    
    static func migrate(with migrator: inout GRDB.DatabaseMigrator, from version: DatabaseVersion) throws {
        switch version {
        case ..<DatabaseVersion(1, 0, 0):
            // unique constraint on name already creates an index
            break
        default:
            break
        }
    }
    
    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = ID(rawValue: inserted.rowID)
    }
}

// MARK: - Associations

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

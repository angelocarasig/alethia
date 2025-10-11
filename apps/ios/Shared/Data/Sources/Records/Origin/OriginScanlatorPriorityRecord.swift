//
//  OriginScanlatorPriorityRecord.swift
//  Data
//
//  Created by Angelo Carasig on 28/9/2025.
//

import Foundation
import GRDB
import Tagged

internal struct OriginScanlatorPriorityRecord: Codable, DatabaseRecord {
    typealias ID = Tagged<Self, Int64>
    private(set) var id: ID?
    
    private(set) var originId: OriginRecord.ID
    private(set) var scanlatorId: ScanlatorRecord.ID
    var priority: Int
    
    init(originId: OriginRecord.ID, scanlatorId: ScanlatorRecord.ID, priority: Int) {
        self.id = nil
        self.originId = originId
        self.scanlatorId = scanlatorId
        self.priority = priority
    }
}

// MARK: - DatabaseRecord

extension OriginScanlatorPriorityRecord {
    static var databaseTableName: String {
        "origin_scanlator_priority"
    }
    
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let originId = Column(CodingKeys.originId)
        static let scanlatorId = Column(CodingKeys.scanlatorId)
        static let priority = Column(CodingKeys.priority)
    }
    
    static func createTable(db: Database) throws {
        try db.create(table: databaseTableName, options: [.ifNotExists]) { t in
            t.autoIncrementedPrimaryKey(Columns.id.name)
            
            t.belongsTo(OriginRecord.databaseTableName, onDelete: .cascade)
            t.belongsTo(ScanlatorRecord.databaseTableName, onDelete: .cascade)
            
            t.column(Columns.priority.name, .integer).notNull()
            
            t.uniqueKey([Columns.originId.name, Columns.scanlatorId.name])
        }
    }
    
    static func migrate(with migrator: inout GRDB.DatabaseMigrator, from version: DatabaseVersion) throws {
        switch version {
        case ..<DatabaseVersion(1, 0, 0):
            let migrationName = DatabaseVersion(1, 0, 0).createMigrationName(description: "origin scanlator priority initial indexes")
            migrator.registerMigration(migrationName) { db in
                // foreign key indexes
                try db.create(index: "idx_origin_scanlator_priority_originId", on: databaseTableName, columns: [Columns.originId.name])
                try db.create(index: "idx_origin_scanlator_priority_scanlatorId", on: databaseTableName, columns: [Columns.scanlatorId.name])
                
                // composite index for scanlator priority within origin
                try db.create(index: "idx_osp_priority", on: databaseTableName, columns: [
                    Columns.originId.name,
                    Columns.scanlatorId.name,
                    Columns.priority.name
                ])
            }
        default:
            break
        }
    }
    
    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = ID(rawValue: inserted.rowID)
    }
}

// MARK: - Associations

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

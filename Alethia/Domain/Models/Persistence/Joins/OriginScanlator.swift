//
//  OriginScanlator.swift
//  Alethia
//
//  Created by Angelo Carasig on 8/6/2025.
//

import Foundation
import GRDB

struct OriginScanlator: Codable {
    var originId: Int64
    var scanlatorId: Int64
    var priority: Int = 0
}

extension OriginScanlator {
    static let origin = belongsTo(Origin.self)
    static let scanlator = belongsTo(Scanlator.self)
}

extension OriginScanlator: TableRecord {
    enum Columns {
        static let originId = Column(CodingKeys.originId)
        static let scanlatorId = Column(CodingKeys.scanlatorId)
        static let priority = Column(CodingKeys.priority)
    }
}

extension OriginScanlator: FetchableRecord {}
extension OriginScanlator: PersistableRecord {}

extension OriginScanlator: DatabaseModel {
    static func createTable(db: Database) throws {
        try db.create(table: databaseTableName, body: { t in
            t.column(Columns.originId.name, .integer)
                .notNull()
                .indexed()
                .references(Origin.databaseTableName, onDelete: .cascade)
            
            t.column(Columns.scanlatorId.name, .integer)
                .notNull()
                .indexed()
                .references(Scanlator.databaseTableName, onDelete: .cascade)
            
            t.column(Columns.priority.name, .integer)
                .notNull()
                .defaults(to: 0)
            
            // Composite primary key
            t.primaryKey([Columns.originId.name, Columns.scanlatorId.name])
            
            // Ensure unique priority per origin
            t.uniqueKey([Columns.originId.name, Columns.priority.name], onConflict: .fail)
        })
    }
    
    static func migrate(with migrator: inout DatabaseMigrator, from version: Version) throws {
        // No migrations needed - current schema is baseline
    }
}

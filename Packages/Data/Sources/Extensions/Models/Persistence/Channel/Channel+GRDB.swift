//
//  Channel+GRDB.swift
//  Data
//
//  Created by Claude on 15/6/2025.
//

import GRDB
import Domain

private typealias Channel = Domain.Models.Persistence.Channel
private typealias Origin = Domain.Models.Persistence.Origin
private typealias Scanlator = Domain.Models.Persistence.Scanlator

// MARK: - Database Conformance
extension Channel: @retroactive FetchableRecord {}

extension Channel: @retroactive PersistableRecord {}

extension Channel: @retroactive TableRecord {
    public enum Columns {
        public static let originId = Column(CodingKeys.originId)
        public static let scanlatorId = Column(CodingKeys.scanlatorId)
        public static let priority = Column(CodingKeys.priority)
    }
}

// MARK: - Database Relations
extension Channel {
    // belongs to a paricular origin
    public static let origin = belongsTo(Domain.Models.Persistence.Origin.self)
    
    // belongs to a particular scanlator
    public static let scanlator = belongsTo(Domain.Models.Persistence.Scanlator.self)
}

// MARK: - Databse Table Definition + Migrations
extension Channel: @retroactive Data.Infrastructure.DatabaseMigratable {
    public static func createTable(db: Database) throws {
        try db.create(table: databaseTableName, body: { t in
            // id - composite primary based on origin/scanlator ids
            t.primaryKey([Columns.originId.name, Columns.scanlatorId.name])
            
            // related joins
            t.column(Columns.originId.name, .integer)
                .notNull()
                .references(Domain.Models.Persistence.Origin.databaseTableName, onDelete: .cascade)
            
            t.column(Columns.scanlatorId.name, .integer)
                .notNull()
                .references(Domain.Models.Persistence.Scanlator.databaseTableName, onDelete: .cascade)

            // properties
            t.column(Columns.priority.name, .integer)
                .notNull()
                .defaults(to: -1)
        })
    }
    
    public static func migrate(with migrator: inout DatabaseMigrator, from version: Data.Infrastructure.Version) throws {
        // No migrations needed - current schema is baseline
    }
}

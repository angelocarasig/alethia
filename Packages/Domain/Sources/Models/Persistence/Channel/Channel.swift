//
//  Channel.swift
//  Domain
//
//  Created by Angelo Carasig on 14/6/2025.
//

import GRDB

internal typealias Channel = Domain.Models.Persistence.Channel

public extension Domain.Models.Persistence {
    /// represents the relationship between an origin and scanlator with priority ordering
    ///
    /// - channels define which scanlator groups provide chapters for a specific origin
    /// - priority determining which scanlator's chapters are preferred when multiple groups have translated the same chapter.
    /// - acts as a many-to-many join table with additional business logic for scanlator preference.
    struct Channel: Codable {
        // MARK: - Properties
        
        /// joiner to associated origin id
        public var originId: Int64
        
        /// joiner to associated scanlator id
        public var scanlatorId: Int64
        
        /// priority-based algorithm to determine how the unified chapter list
        /// is returned where priority ∈ ℤ, 0 ≤ priority < ∞
        ///
        /// lower values have higher precedence (0 = highest priority).
        public var priority: Int = -1
        
        init(
            originId: Int64,
            scanlatorId: Int64,
            priority: Int
        ) {
            self.originId = originId
            self.scanlatorId = scanlatorId
            self.priority = priority
        }
    }
}

// MARK: - Database Conformance
extension Channel: FetchableRecord, PersistableRecord {}

extension Channel: TableRecord {
    public enum Columns {
        public static let originId = Column(CodingKeys.originId)
        public static let scanlatorId = Column(CodingKeys.scanlatorId)
        public static let priority = Column(CodingKeys.priority)
    }
}

// MARK: - Database Relations
extension Channel {
    // belongs to a paricular origin
    static let origin = belongsTo(Domain.Models.Persistence.Origin.self)
    
    // belongs to a particular scanlator
    static let scanlator = belongsTo(Domain.Models.Persistence.Scanlator.self)
}

// MARK: - Databse Table Definition + Migrations
extension Channel: Domain.Models.Database.DatabaseMigratable {
    public static func createTable(db: Database) throws {
        try db.create(table: databaseTableName, body: { t in
            // id - composite primary based on origin/scanlator ids
            t.primaryKey([Columns.originId.name, Columns.scanlatorId.name])
            
            // related joins
            t.column(Columns.originId.name, .integer)
                .notNull()
                .references(Origin.databaseTableName, onDelete: .cascade)
            
            t.column(Columns.scanlatorId.name, .integer)
                .notNull()
                .references(Scanlator.databaseTableName, onDelete: .cascade)

            // properties
            t.column(Columns.priority.name, .integer)
                .notNull()
                .defaults(to: -1)
        })
    }
    
    public static func migrate(with migrator: inout DatabaseMigrator, from version: Domain.Models.Database.Version) throws {
        // No migrations needed - current schema is baseline
    }
}

//
//  SourceRoute+GRDB.swift
//  Data
//
//  Created by Claude on 15/6/2025.
//

import Foundation
import GRDB
import Domain


private typealias SourceRoute = Domain.Models.Persistence.SourceRoute
private typealias Source = Domain.Models.Persistence.Source

// MARK: - Database Conformance
extension SourceRoute: @retroactive FetchableRecord {}

extension SourceRoute: @retroactive PersistableRecord {}

extension SourceRoute: @retroactive TableRecord {
    public enum Columns {
        public static let id = Column(CodingKeys.id)
        public static let name = Column(CodingKeys.name)
        public static let path = Column(CodingKeys.path)
        public static let sourceId = Column(CodingKeys.sourceId)
    }
}

// MARK: - Database Relations
extension SourceRoute {
    // belongs to a single source
    public static let source = belongsTo(Domain.Models.Persistence.Source.self)
    var source: QueryInterfaceRequest<Source> {
        request(for: Domain.Models.Persistence.SourceRoute.source)
    }
}

// MARK: - Database Table Definition + Migrations
extension SourceRoute: @retroactive Data.Infrastructure.DatabaseMigratable {
    public static func createTable(db: Database) throws {
        try db.create(table: databaseTableName, body: { t in
            // ids
            t.autoIncrementedPrimaryKey(Columns.id.name)
            t.column(Columns.sourceId.name, .integer)
                .notNull()
                .references(Domain.Models.Persistence.Source.databaseTableName, onDelete: .cascade)
            
            // properties
            t.column(Columns.name.name, .text).notNull()
            t.column(Columns.path.name, .text).notNull()
        })
    }
    
    public static func migrate(with migrator: inout DatabaseMigrator, from version: Data.Infrastructure.Version) throws {
        // No migrations needed - current schema is baseline
    }
}

//
//  Source+GRDB.swift
//  Data
//
//  Created by Claude on 15/6/2025.
//

import Foundation
import GRDB
import Domain


private typealias Source = Domain.Models.Persistence.Source
private typealias Host = Domain.Models.Persistence.Host
private typealias SourceRoute = Domain.Models.Persistence.SourceRoute
private typealias Origin = Domain.Models.Persistence.Origin

// MARK: - Database Conformance
extension Source: @retroactive FetchableRecord {}

extension Source: @retroactive PersistableRecord {}

extension Source: @retroactive TableRecord {
    public enum Columns {
        public static let id = Column(CodingKeys.id)
        public static let hostId = Column(CodingKeys.hostId)
        
        public static let name = Column(CodingKeys.name)
        public static let icon = Column(CodingKeys.icon)
        public static let path = Column(CodingKeys.path)
        
        public static let website = Column(CodingKeys.website)
        public static let description = Column(CodingKeys.description)
        
        public static let pinned = Column(CodingKeys.pinned)
        public static let disabled = Column(CodingKeys.disabled)
    }
}

// MARK: - Database Relations
extension Source {
    // belongs to a single host
    public static let host = belongsTo(Domain.Models.Persistence.Host.self)
    var host: QueryInterfaceRequest<Host> {
        request(for: Domain.Models.Persistence.Source.host)
    }
    
    // has many routes
    public static let routes = hasMany(Domain.Models.Persistence.SourceRoute.self)
    var routes: QueryInterfaceRequest<SourceRoute> {
        request(for: Domain.Models.Persistence.Source.routes)
    }
    
    // has many origins
    public static let origins = hasMany(Domain.Models.Persistence.Origin.self)
}

// MARK: - Database Table Definition + Migrations
extension Source: @retroactive Data.Infrastructure.DatabaseMigratable {
    public static func createTable(db: Database) throws {
        try db.create(table: databaseTableName, body: { t in
            // ids
            t.autoIncrementedPrimaryKey(Columns.id.name)
            t.column(Columns.hostId.name, .integer)
                .notNull()
                .references(Domain.Models.Persistence.Host.databaseTableName, onDelete: .cascade)
            
            // properties
            t.column(Columns.name.name, .text).notNull()
            t.column(Columns.icon.name, .text).notNull()
            t.column(Columns.path.name, .text).notNull()
            
            // external
            t.column(Columns.website.name, .text).notNull()
            t.column(Columns.description.name, .text).notNull()
            
            // controls
            t.column(Columns.pinned.name, .boolean).notNull()
            t.column(Columns.disabled.name, .boolean).notNull()
        })
    }
    
    public static func migrate(with migrator: inout DatabaseMigrator, from version: Data.Infrastructure.Version) throws {
        // nothing for now
    }
}

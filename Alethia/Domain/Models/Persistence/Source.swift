//
//  Source.swift
//  Alethia
//
//  Created by Angelo Carasig on 10/4/2025.
//

import Foundation
import GRDB

struct Source: Codable, Identifiable {
    var id: Int64?
    
    var name: String
    var icon: String
    var path: String
    
    var pinned: Bool = false
    var disabled: Bool = false
    
    var hostId: Int64
}

extension Source {
    static let host = belongsTo(Host.self)
    static let routes = hasMany(SourceRoute.self)
    static let origins = hasMany(Origin.self)
}

extension Source {
    var host: QueryInterfaceRequest<Host> {
        request(for: Source.host)
    }
    
    var routes: QueryInterfaceRequest<SourceRoute> {
        request(for: Source.routes)
    }
    
    var origins: QueryInterfaceRequest<Origin> {
        request(for: Source.origins)
    }
}

extension Source: TableRecord {
    enum Columns {
        static let id = Column(Source.CodingKeys.id)
        static let name = Column(Source.CodingKeys.name)
        static let icon = Column(Source.CodingKeys.icon)
        static let path = Column(Source.CodingKeys.path)
        static let pinned = Column(Source.CodingKeys.pinned)
        static let disabled = Column(Source.CodingKeys.disabled)
        static let hostId = Column(Source.CodingKeys.hostId)
    }
}

extension Source: FetchableRecord {}
extension Source: PersistableRecord {}

extension Source: DatabaseModel {
    static var version: Version = Version(1, 0, 0)
    
    static func createTable(db: Database) throws {
        try db.create(table: databaseTableName, body: { t in
            t.autoIncrementedPrimaryKey(Columns.id.name)
            
            t.column(Columns.name.name, .text).notNull()
            t.column(Columns.icon.name, .text).notNull()
            t.column(Columns.path.name, .text).notNull()
            t.column(Columns.pinned.name, .boolean).notNull()
            t.column(Columns.disabled.name, .boolean).notNull()
            
            t.column(Columns.hostId.name, .integer)
                .notNull()
                .indexed()
                .references(Host.databaseTableName, onDelete: .cascade)
        })
    }
    
    static func migrate(with migrator: inout DatabaseMigrator, from version: Version) throws {
        // Nothing for now
    }
}

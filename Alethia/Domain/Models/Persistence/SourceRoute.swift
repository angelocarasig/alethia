//
//  SourceRoute.swift
//  Alethia
//
//  Created by Angelo Carasig on 10/4/2025.
//

import Foundation
import GRDB

struct SourceRoute: Codable, Identifiable {
    var id: Int64?
    
    var name: String
    var path: String
    
    var sourceId: Int64
}

extension SourceRoute {
    static let source = belongsTo(Source.self)
}

extension SourceRoute {
    var source: QueryInterfaceRequest<Source> {
        request(for: SourceRoute.source)
    }
}

extension SourceRoute: TableRecord {
    enum Columns {
        static let id = Column(SourceRoute.CodingKeys.id)
        static let name = Column(SourceRoute.CodingKeys.name)
        static let path = Column(SourceRoute.CodingKeys.path)
        static let sourceId = Column(SourceRoute.CodingKeys.sourceId)
    }
}

extension SourceRoute: FetchableRecord {}
extension SourceRoute: PersistableRecord {}

extension SourceRoute: DatabaseModel {
    static func createTable(db: Database) throws {
        try db.create(table: databaseTableName, body: { t in
            t.autoIncrementedPrimaryKey(Columns.id.name)
            
            t.column(Columns.name.name, .text).notNull()
            t.column(Columns.path.name, .text).notNull()
            
            t.column(Columns.sourceId.name, .integer)
                .notNull()
                .indexed()
                .references(Source.databaseTableName, onDelete: .cascade)
        })
    }
    
    static func migrate(with migrator: inout DatabaseMigrator, from version: Version) throws {
        // Nothing for now
    }
}

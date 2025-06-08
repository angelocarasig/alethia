//
//  Host.swift
//  Alethia
//
//  Created by Angelo Carasig on 10/4/2025.
//

import Foundation
import GRDB

struct Host: Codable, Identifiable {
    var id: Int64?
    
    var name: String
    var author: String
    var repository: String
    var baseUrl: String
}


extension Host {
    static var sources = hasMany(Source.self)
}

extension Host {
    var sources: QueryInterfaceRequest<Source> {
        request(for: Host.sources)
    }
}

extension Host: TableRecord {
    enum Columns {
        static let id = Column(Host.CodingKeys.id)
        static let name = Column(Host.CodingKeys.name)
        static let author = Column(Host.CodingKeys.author)
        static let repository = Column(Host.CodingKeys.repository)
        static let baseUrl = Column(Host.CodingKeys.baseUrl)
    }
}

extension Host: FetchableRecord {}
extension Host: PersistableRecord {}
extension Host: DatabaseUnique {
    static func uniqueFilter(for instance: Host) -> QueryInterfaceRequest<Host> {
        filter(Columns.baseUrl == instance.baseUrl)
    }
}

extension Host: DatabaseModel {
    static func createTable(db: Database) throws {
        try db.create(table: databaseTableName, body: { t in
            // Persistence
            t.autoIncrementedPrimaryKey(Columns.id.name)
            t.column(Columns.name.name, .text).notNull()
            t.column(Columns.author.name, .text).notNull()
            t.column(Columns.repository.name, .text).notNull()
            t.column(Columns.baseUrl.name, .text)
                .notNull()
                .collate(.nocase)
                .unique(onConflict: .fail)
        })
    }
    
    static func migrate(with migrator: inout DatabaseMigrator, from version: Version) throws {
        // No migrations needed - current schema is baseline
    }
}

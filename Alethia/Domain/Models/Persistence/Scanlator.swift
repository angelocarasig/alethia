//
//  Scanlator.swift
//  Alethia
//
//  Created by Angelo Carasig on 10/4/2025.
//

import Foundation
import GRDB

struct Scanlator: Codable, Identifiable {
    var id: Int64?
    var name: String
    
    init(name: String) {
        self.name = name
    }
}

extension Scanlator {
    static let chapters = hasMany(Chapter.self)
    static let originScanlator = hasMany(OriginScanlator.self)
    static let origins = hasMany(Origin.self, through: originScanlator, using: OriginScanlator.origin)
}

extension Scanlator {
    var chapters: QueryInterfaceRequest<Chapter> {
        request(for: Scanlator.chapters)
    }
    
    var origins: QueryInterfaceRequest<Origin> {
        request(for: Scanlator.origins)
    }
}

extension Scanlator: TableRecord {
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let name = Column(CodingKeys.name)
    }
}

extension Scanlator: FetchableRecord {}
extension Scanlator: PersistableRecord {}

extension Scanlator: DatabaseUnique {
    static func uniqueFilter(for instance: Scanlator) -> QueryInterfaceRequest<Scanlator> {
        filter(Columns.name == instance.name)
    }
}

extension Scanlator: DatabaseModel {
    static func createTable(db: Database) throws {
        try db.create(table: databaseTableName, body: { t in
            t.autoIncrementedPrimaryKey(Columns.id.name)
            
            t.column(Columns.name.name, .text)
                .notNull()
                .unique()
                .collate(.nocase)
                .indexed()
        })
    }
    
    static func migrate(with migrator: inout DatabaseMigrator, from version: Version) throws {
        // No migrations needed - current schema is baseline
    }
}

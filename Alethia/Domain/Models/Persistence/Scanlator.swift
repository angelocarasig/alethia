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
    
    var originId: Int64
    
    var name: String
    var priority: Int = -1
}

extension Scanlator {
    static let origin = belongsTo(Origin.self)
    static let chapters = hasMany(Chapter.self)
}

extension Scanlator {
    var origin: QueryInterfaceRequest<Origin> {
        request(for: Scanlator.origin)
    }
    
    var chapters: QueryInterfaceRequest<Chapter> {
        request(for: Scanlator.chapters)
    }
}

extension Scanlator: TableRecord {
    enum Columns {
        static let id = Column(Scanlator.CodingKeys.id)
        static let originId = Column(Scanlator.CodingKeys.originId)
        
        static let name = Column(Scanlator.CodingKeys.name)
        static let priority = Column(Scanlator.CodingKeys.priority)
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
    static var version: Version = Version(1, 0, 0)
    
    static func createTable(db: Database) throws {
        try db.create(table: self.databaseTableName, body: { t in
            t.autoIncrementedPrimaryKey(Columns.id.name)
            
            t.column(Columns.name.name, .text)
                .notNull()
                .collate(.nocase)
            t.column(Columns.priority.name, .integer).notNull()
            
            t.column(Columns.originId.name, .integer)
                .notNull()
                .indexed()
                .references(Origin.databaseTableName, onDelete: .cascade)
            
            // No duplicate priority values for the same origin
            t.uniqueKey([Columns.priority.name, Columns.originId.name], onConflict: .fail)
            
            // Scanlator names should be unique per origin
            t.uniqueKey([Columns.name.name, Columns.originId.name], onConflict: .ignore)
        })
    }
    
    static func migrate(with migrator: inout DatabaseMigrator, from version: Version) throws {
        // Nothing for now
    }
}

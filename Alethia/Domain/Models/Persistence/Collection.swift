//
//  Collection.swift
//  Alethia
//
//  Created by Angelo Carasig on 23/4/2025.
//

import Foundation
import GRDB

struct Collection: Codable, Identifiable, Equatable {
    var id: Int64?
    
    var name: String
    var color: String // hex color string (e.g., "#FF0000")
    var icon: String  // sf symbol icon
    
    var ordering: Int = 0
}

extension Collection {
    static let mangaCollection = hasMany(MangaCollection.self)
    static let manga = hasMany(Manga.self, through: mangaCollection, using: MangaCollection.manga)
}

extension Collection: TableRecord {
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let name = Column(CodingKeys.name)
        static let color = Column(CodingKeys.color)
        static let icon = Column(CodingKeys.icon)
        static let ordering = Column(CodingKeys.ordering)
    }
}

extension Collection: FetchableRecord, PersistableRecord {}

extension Collection: DatabaseUnique {
    static func uniqueFilter(for instance: Collection) -> QueryInterfaceRequest<Collection> {
        filter(Columns.name == instance.name)
    }
}

extension Collection: DatabaseModel {
    static func createTable(db: Database) throws {
        try db.create(table: databaseTableName, body: { t in
            t.autoIncrementedPrimaryKey(Columns.id.name)
            
            t.column(Columns.name.name, .text)
                .notNull()
                .unique()
                .collate(.nocase)
                .indexed()
                // TODO:
                .check { length($0) >= 3 && length($0) <= 5 }
            
            t.column(Columns.color.name, .text)
                .notNull()
                .defaults(to: "#007AFF") // iOS blue
            
            t.column(Columns.icon.name, .text)
                .notNull()
                .defaults(to: "square.inset.filled")
            
            t.column(Columns.ordering.name, .integer)
                .notNull()
                .unique()
                .indexed()
                .defaults(to: 0)
        })
        
        try db.create(index: "idx_collection_unique_priority",
                      on: Collection.databaseTableName,
                      columns: [Columns.ordering.name],
                      unique: true)
    }
    
    static func migrate(with migrator: inout GRDB.DatabaseMigrator, from version: Version) throws {
        if version <= Version(1, 0, 1) {
            // add ordering
            migrator.registerMigration("add_collection_ordering_v1.0.1") { db in
                // Add the ordering column without unique constraint first
                try db.alter(table: Collection.databaseTableName) { t in
                    t.add(column: Columns.ordering.name, .integer)
                        .notNull()
                        .defaults(to: 0)
                }
                
                // Fetch all collections ordered by name
                let collections = try Collection
                    .order(Columns.name.asc)
                    .fetchAll(db)
                
                // Update each collection with incremental ordering
                for (index, collection) in collections.enumerated() {
                    try db.execute(
                        sql: "UPDATE collection SET ordering = ? WHERE id = ?",
                        arguments: [index, collection.id]
                    )
                }
                
                // Now add the unique index after all values are set
                try db.create(
                    index: "idx_collection_unique_ordering",
                    on: Collection.databaseTableName,
                    columns: [Columns.ordering.name],
                    unique: true
                )
            }
        }
    }
}

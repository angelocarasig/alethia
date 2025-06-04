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
    }
}

extension Collection: FetchableRecord, PersistableRecord {}

extension Collection: DatabaseUnique {
    static func uniqueFilter(for instance: Collection) -> QueryInterfaceRequest<Collection> {
        filter(Columns.name == instance.name)
    }
}

extension Collection: DatabaseModel {
    static var version: Version = Version(1, 0, 2)
    
    static func createTable(db: Database) throws {
        try db.create(table: databaseTableName, body: { t in
            t.autoIncrementedPrimaryKey(Columns.id.name)
            
            t.column(Columns.name.name, .text)
                .notNull()
                .unique()
                .collate(.nocase)
                .indexed()
            
            t.column(Columns.color.name, .text)
                .notNull()
                .defaults(to: "#007AFF") // iOS blue
            
            t.column(Columns.icon.name, .text)
                .notNull()
                .defaults(to: "square.inset.filled")
        })
    }
    
    static func migrate(with migrator: inout GRDB.DatabaseMigrator, from version: Version) throws {
        if version < Version(1, 0, 2) {
            migrator.registerMigration("collection icons and colors") { db in
                try db.alter(table: databaseTableName) { t in
                    t.add(column: Columns.color.name, .text)
                        .notNull()
                        .defaults(to: "#007AFF")
                    
                    t.add(column: Columns.icon.name, .text)
                        .notNull()
                        .defaults(to: "square.inset.filled")
                }
            }
        }
    }
}

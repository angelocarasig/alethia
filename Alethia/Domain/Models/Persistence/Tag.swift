//
//  Tag.swift
//  Alethia
//
//  Created by Angelo Carasig on 10/4/2025.
//

import Foundation
import GRDB

struct Tag: Codable, Identifiable {
    var id: Int64?
    var name: String
    
    init(name: String) {
        self.name = name
    }
}

extension Tag {
    static let mangaTag = hasMany(MangaTag.self)
    static let manga = hasMany(Manga.self, through: mangaTag, using: MangaTag.manga)
}

extension Tag: TableRecord {
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let name = Column(CodingKeys.name)
    }
}

extension Tag: FetchableRecord {}
extension Tag: PersistableRecord {}

extension Tag: DatabaseUnique {
    static func uniqueFilter(for instance: Tag) -> QueryInterfaceRequest<Tag> {
        filter(Columns.name == instance.name)
    }
}

extension Tag: DatabaseModel {
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

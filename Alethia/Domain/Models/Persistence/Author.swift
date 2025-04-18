//
//  Author.swift
//  Alethia
//
//  Created by Angelo Carasig on 10/4/2025.
//

import Foundation
import GRDB

struct Author: Codable, Identifiable {
    var id: Int64?
    var name: String
    
    init(name: String) {
        self.name = name
    }
}

extension Author {
    static let mangaAuthor = hasMany(MangaAuthor.self)
    static let manga = hasMany(Manga.self, through: mangaAuthor, using: MangaAuthor.manga)
}

extension Author: TableRecord {
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let name = Column(CodingKeys.name)
    }
}

extension Author: FetchableRecord {}
extension Author: PersistableRecord {}
extension Author: DatabaseUnique {
    static func uniqueFilter(for instance: Author) -> QueryInterfaceRequest<Author> {
        filter(Columns.name == instance.name)
    }
}


extension Author: DatabaseModel {
    static var version: Version = Version(1, 0, 0)
    
    static func createTable(db: Database) throws {
        try db.create(table: databaseTableName, body: { t in
            t.autoIncrementedPrimaryKey(Columns.id.name)
            
            t.column(Columns.name.name, .text)
                .notNull()
                .unique()
                .indexed()
        })
    }
    
    static func migrate(with migrator: inout DatabaseMigrator, from version: Version) throws {
        // Nothing for now
    }
}

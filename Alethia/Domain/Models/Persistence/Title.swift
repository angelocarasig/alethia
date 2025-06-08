//
//  Title.swift
//  Alethia
//
//  Created by Angelo Carasig on 9/4/2025.
//

import Foundation
import GRDB

struct Title: Codable, Identifiable {
    var id: Int64?
    
    var title: String
    
    var mangaId: Int64
}

extension Title {
    static let manga = belongsTo(Manga.self)
}

extension Title {
    var manga: QueryInterfaceRequest<Manga> {
        request(for: Title.manga)
    }
}

extension Title: TableRecord {
    enum Columns {
        static let id = Column(Title.CodingKeys.id)
        static let title = Column(Title.CodingKeys.title)
        static let mangaId = Column(Title.CodingKeys.mangaId)
    }
}

extension Title: FetchableRecord {}
extension Title: PersistableRecord {}

extension Title: DatabaseModel {
    static func createTable(db: Database) throws {
        try db.create(table: self.databaseTableName, body: { t in
            t.autoIncrementedPrimaryKey(Columns.id.name)
            
            t.column(Columns.title.name, .text)
                .notNull()
                .indexed()
                .collate(.nocase)
            
            t.column(Columns.mangaId.name, .integer)
                .notNull()
                .indexed()
                .references(Manga.databaseTableName, onDelete: .cascade)
            
            // If same manga-title key already exists it'll just ignore it
            t.uniqueKey([Columns.title.name, Columns.mangaId.name], onConflict: .ignore)
        })
    }
    
    static func migrate(with migrator: inout DatabaseMigrator, from version: Version) throws {
        // Nothing for now
    }
}

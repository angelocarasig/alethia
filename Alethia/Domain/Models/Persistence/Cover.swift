//
//  Cover.swift
//  Alethia
//
//  Created by Angelo Carasig on 10/4/2025.
//

import Foundation
import GRDB

struct Cover: Codable, Identifiable, Equatable {
    
    var id: Int64?
    
    var active: Bool
    var url: String
    var path: String
    
    var mangaId: Int64
}

extension Cover {
    static let manga = belongsTo(Manga.self)
}

extension Cover {
    var manga: QueryInterfaceRequest<Manga> {
        request(for: Cover.manga)
    }
}

extension Cover: TableRecord {
    enum Columns {
        static let id = Column(Cover.CodingKeys.id)
        static let active = Column(Cover.CodingKeys.active)
        static let url = Column(Cover.CodingKeys.url)
        static let path = Column(Cover.CodingKeys.path)
        static let mangaId = Column(Cover.CodingKeys.mangaId)
    }
}

extension Cover: FetchableRecord {}

extension Cover: PersistableRecord {}

extension Cover: DatabaseModel {
    static func createTable(db: Database) throws {
        try db.create(table: self.databaseTableName, body: { t in
            t.autoIncrementedPrimaryKey(Columns.id.name)
            
            t.column(Columns.active.name, .boolean)
                .notNull()
                // no indexing here since below's index only on 'active' column
            
            t.column(Columns.url.name, .text).notNull()
            t.column(Columns.path.name, .text).notNull()
            
            t.column(Columns.mangaId.name, .integer)
                .notNull()
                .references(Manga.databaseTableName, onDelete: .cascade)
        })
        
        // Create unique index to ensure only 1 cover can be 'active' for a given mangaId at a time
        let sql = """
            CREATE UNIQUE INDEX IF NOT EXISTS cover_one_active_per_manga
            ON cover(mangaId)
            WHERE active = 1
        """
        try db.execute(sql: sql)
        
        try db.execute(sql: """
            CREATE INDEX idx_cover_active_manga 
            ON cover(mangaId) 
            WHERE active = 1
        """)
    }
    
    static func migrate(with migrator: inout DatabaseMigrator, from version: Version) throws {
        // No migrations needed - current schema is baseline
    }
}

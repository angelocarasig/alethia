//
//  MangaCollection+GRDB.swift
//  Data
//
//  Created by Angelo Carasig on 15/6/2025.
//

import GRDB
import Domain


private typealias MangaCollection = Domain.Models.Persistence.MangaCollection
private typealias Manga = Domain.Models.Persistence.Manga
private typealias Collection = Domain.Models.Persistence.Collection

// MARK: - Database Conformance
extension MangaCollection: @retroactive FetchableRecord {}

extension MangaCollection: @retroactive PersistableRecord {}

extension MangaCollection: @retroactive TableRecord {
    public enum Columns {
        public static let mangaId = Column(CodingKeys.mangaId)
        public static let collectionId = Column(CodingKeys.collectionId)
    }
}

// MARK: - Database Relations
extension MangaCollection {
    // belongs to a particular manga
    public static let manga = belongsTo(Domain.Models.Persistence.Manga.self)
    
    // belongs to a particular collection
    public static let collection = belongsTo(Domain.Models.Persistence.Collection.self)
}

// MARK: - Database Table Definition + Migrations
extension MangaCollection: @retroactive Data.Infrastructure.DatabaseMigratable {
    public static func createTable(db: Database) throws {
        try db.create(table: databaseTableName, body: { t in
            // note: no composite primary key here as manga can be in multiple collections
            
            t.column(Columns.mangaId.name, .integer)
                .notNull()
                .references(Domain.Models.Persistence.Manga.databaseTableName, onDelete: .setNull)
            
            t.column(Columns.collectionId.name, .integer)
                .notNull()
                .references(Domain.Models.Persistence.Collection.databaseTableName, onDelete: .cascade)
        })
    }
    
    public static func migrate(with migrator: inout DatabaseMigrator, from version: Data.Infrastructure.Version) throws {
        // nothing for now
    }
}

//
//  Cover+GRDB.swift
//  Data
//
//  Created by Angelo Carasig on 15/6/2025.
//

import GRDB
import Domain


private typealias Cover = Domain.Models.Persistence.Cover
private typealias Manga = Domain.Models.Persistence.Manga

// MARK: - Database Conformance
extension Cover: @retroactive FetchableRecord {}

extension Cover: @retroactive PersistableRecord {}

extension Cover: @retroactive TableRecord {
    public enum Columns {
        public static let id = Column(CodingKeys.id)
        public static let mangaId = Column(CodingKeys.mangaId)
        public static let active = Column(CodingKeys.active)
        public static let url = Column(CodingKeys.url)
        public static let path = Column(CodingKeys.path)
    }
}

// MARK: - Database Relations
extension Cover {
    // belongs to a single manga
    public static let manga = belongsTo(Domain.Models.Persistence.Manga.self)
    var manga: QueryInterfaceRequest<Domain.Models.Persistence.Manga> {
        request(for: Domain.Models.Persistence.Cover.manga)
    }
}

// MARK: - Database Table Definition + Migrations
extension Cover: @retroactive Data.Infrastructure.DatabaseMigratable {
    public static func createTable(db: Database) throws {
        try db.create(table: databaseTableName, body: { t in
            // ids
            t.autoIncrementedPrimaryKey(Columns.id.name)
            
            t.column(Columns.mangaId.name, .integer)
                .notNull()
                .references(Domain.Models.Persistence.Manga.databaseTableName, onDelete: .cascade)
            
            // properties
            t.column(Columns.active.name, .boolean)
                .notNull()
            
            t.column(Columns.url.name, .text).notNull()
            t.column(Columns.path.name, .text).notNull()
        })
    }
    
    public static func migrate(with migrator: inout DatabaseMigrator, from version: Data.Infrastructure.Version) throws {
        // nothing for now
    }
}

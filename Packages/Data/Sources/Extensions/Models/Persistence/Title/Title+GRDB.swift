//
//  Title+GRDB.swift
//  Data
//
//  Created by Angelo Carasig on 15/6/2025.
//

import GRDB
import Domain

private typealias Title = Domain.Models.Persistence.Title
private typealias Manga = Domain.Models.Persistence.Manga

// MARK: - Database Conformance
extension Title: @retroactive FetchableRecord {}

extension Title: @retroactive PersistableRecord {}

extension Title: @retroactive TableRecord {
    public enum Columns {
        public static let id = Column(CodingKeys.id)
        public static let mangaId = Column(CodingKeys.mangaId)
        public static let title = Column(CodingKeys.title)
    }
}

// MARK: - Database Relations
extension Title {
    // belongs to a single manga
    public static let manga = belongsTo(Domain.Models.Persistence.Manga.self)
    var manga: QueryInterfaceRequest<Domain.Models.Persistence.Manga> {
        request(for: Domain.Models.Persistence.Title.manga)
    }
}

// MARK: - Database Table Definition + Migrations
extension Title: @retroactive Data.Infrastructure.DatabaseMigratable {
    public static func createTable(db: Database) throws {
        try db.create(table: databaseTableName, body: { t in
            // ids
            t.autoIncrementedPrimaryKey(Columns.id.name)
            
            t.column(Columns.mangaId.name, .integer)
                .notNull()
                .references(Domain.Models.Persistence.Manga.databaseTableName, onDelete: .cascade)
            
            // properties
            t.column(Columns.title.name, .text)
                .notNull()
                .collate(.nocase)
            
            // all titles for a given manga must be unique - if not we can just skip
            // titles themselves don't need to be unique - should be resolved by user in UI layer
            t.uniqueKey([Columns.title.name, Columns.mangaId.name], onConflict: .ignore)
        })
    }
    
    public static func migrate(with migrator: inout DatabaseMigrator, from version: Data.Infrastructure.Version) throws {
        // nothing for now
    }
}

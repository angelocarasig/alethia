//
//  Scanlator+GRDB.swift
//  Data
//
//  Created by Angelo Carasig on 15/6/2025.
//

import GRDB
import Domain


private typealias Scanlator = Domain.Models.Persistence.Scanlator
private typealias Chapter = Domain.Models.Persistence.Chapter
private typealias Channel = Domain.Models.Persistence.Channel
private typealias Origin = Domain.Models.Persistence.Origin

// MARK: - Database Conformance
extension Scanlator: @retroactive FetchableRecord {}

extension Scanlator: @retroactive PersistableRecord {}

extension Scanlator: @retroactive TableRecord {
    public enum Columns {
        public static let id = Column(CodingKeys.id)
        public static let name = Column(CodingKeys.name)
    }
}

extension Scanlator: @retroactive Data.Infrastructure.DatabaseUnique {
    public static func uniqueFilter(for instance: Scanlator) -> QueryInterfaceRequest<Scanlator> {
        filter(Columns.name == instance.name)
    }
}

// MARK: - Database Relations
extension Scanlator {
    // has many chapters
    public static let chapters = hasMany(Domain.Models.Persistence.Chapter.self)
    
    // has many origin scanlators
    public static let originScanlator = hasMany(Domain.Models.Persistence.Chapter.self)
    
    // has many origins
    public static let origins = hasMany(Domain.Models.Persistence.Chapter.self)
}

// MARK: - Database Table Definition + Migrations
extension Scanlator: @retroactive Data.Infrastructure.DatabaseMigratable {
    public static func createTable(db: Database) throws {
        try db.create(table: databaseTableName, body: { t in
            // ids
            t.autoIncrementedPrimaryKey(Columns.id.name)
            
            // properties
            t.column(Columns.name.name, .text)
                .notNull()
                .collate(.nocase)
                .unique(onConflict: .fail)
        })
    }
    
    public static func migrate(with migrator: inout DatabaseMigrator, from version: Data.Infrastructure.Version) throws {
        // No migrations needed - current schema is baseline
    }
}

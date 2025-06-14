//
//  Scanlator.swift
//  Domain
//
//  Created by Angelo Carasig on 14/6/2025.
//
import GRDB

internal typealias Scanlator = Domain.Models.Persistence.Scanlator

public extension Domain.Models.Persistence {
    /// represents a scanlator group
    ///
    /// metadata only includes name as other properties are difficult to track
    ///
    /// priority values are defined in a separate `Channel` model as each scanlator
    /// may be preferred over another based on each origin/manga
    struct Scanlator: Identifiable, Codable {
        // MARK: - Properties
        
        /// unique database identifier
        public var id: Int64?
        
        /// name of scanlation group
        public var name: String
        
        init(
            id: Int64? = nil,
            name: String
        ) {
            self.id = id
            self.name = name
        }
    }
}

// MARK: - Database Conformance
extension Scanlator: FetchableRecord, PersistableRecord {}

extension Scanlator: Domain.Models.Database.DatabaseUnique {
    public static func uniqueFilter(for instance: Domain.Models.Persistence.Scanlator) -> QueryInterfaceRequest<Domain.Models.Persistence.Scanlator> {
        filter(Columns.name == instance.name)
    }
}

extension Scanlator: TableRecord {
    public enum Columns {
        public static let id = Column(CodingKeys.id)
        public static let name = Column(CodingKeys.name)
    }
}

// MARK: - Database Relations
extension Scanlator {
    // has many chapters
    static let chapters = hasMany(Domain.Models.Persistence.Chapter.self)
    
    // has many origin scanlators
    static let originScanlator = hasMany(Domain.Models.Persistence.Chapter.self)
    
    // has many origins
    static let origins = hasMany(Domain.Models.Persistence.Chapter.self)
}

// MARK: - Database Table Definition + Migrations
extension Scanlator: Domain.Models.Database.DatabaseMigratable {
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
    
    public static func migrate(with migrator: inout DatabaseMigrator, from version: Domain.Models.Database.Version) throws {
        // No migrations needed - current schema is baseline
    }
}

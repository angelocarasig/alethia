//
//  SourceRoute.swift
//  Domain
//
//  Created by Angelo Carasig on 14/6/2025.
//
import GRDB

internal typealias SourceRoute = Domain.Models.Persistence.SourceRoute

public extension Domain.Models.Persistence {
    /// represents a unique route for a source
    ///
    /// examples include: 'Popular', 'Top', Recently Updated', 'New', etc.
    struct SourceRoute: Codable, Identifiable {
        // MARK: - Properties
        
        /// unique database identifier
        public var id: Int64?
        
        /// parent source the route belongs to
        public var sourceId: Int64
        
        /// display name of the route
        public var name: String
        
        /// url-based path identifier for the route - used when constructing a fetch url
        public var path: String
        
        init(
            id: Int64? = nil,
            sourceId: Int64,
            name: String,
            path: String
        ) {
            self.id = id
            self.sourceId = sourceId
            self.name = name
            self.path = path
        }
    }
}

// MARK: - Database Conformance
extension SourceRoute: FetchableRecord, PersistableRecord {}

extension SourceRoute: TableRecord {
    public enum Columns {
        public static let id = Column(CodingKeys.id)
        public static let name = Column(CodingKeys.name)
        public static let path = Column(CodingKeys.path)
        public static let sourceId = Column(CodingKeys.sourceId)
    }
}

// MARK: - Database Relations
extension SourceRoute {
    // belongs to a single source
    static let source = belongsTo(Domain.Models.Persistence.Source.self)
    var source: QueryInterfaceRequest<Domain.Models.Persistence.Source> {
        request(for: Domain.Models.Persistence.SourceRoute.source)
    }
}

// MARK: - Database Table Definition + Migrations
extension SourceRoute: DatabaseMigratable {
    static func createTable(db: Database) throws {
        try db.create(table: databaseTableName, body: { t in
            // ids
            t.autoIncrementedPrimaryKey(Columns.id.name)
            t.column(Columns.sourceId.name, .integer)
                .notNull()
                .references(Source.databaseTableName, onDelete: .cascade)
            
            // properties
            t.column(Columns.name.name, .text).notNull()
            t.column(Columns.path.name, .text).notNull()
        })
    }
    
    static func migrate(with migrator: inout DatabaseMigrator, from version: Version) throws {
        // No migrations needed - current schema is baseline
    }
}

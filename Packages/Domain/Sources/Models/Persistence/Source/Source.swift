//
//  Source.swift
//  Domain
//
//  Created by Angelo Carasig on 14/6/2025.
//

import GRDB

internal typealias Source = Domain.Models.Persistence.Source

public extension Domain.Models.Persistence {
    /// represents an individual source provided by the underlying host
    struct Source: Identifiable, Codable {
        // MARK: - Properties
        
        /// unique database identifier
        public var id: Int64?
        
        /// parent host the source belongs to
        public var hostId: Int64
        
        /// display name of the source
        public var name: String
        
        /// path to the icon
        public var icon: String
        
        /// url-based path identifier used when constructing a fetch url
        public var path: String
        
        /// url to the source website
        ///
        /// requirement to ensure visibility of original provider
        /// and can be used as reference for mismatches/inconsistencies
        /// within the app
        public var website: String
        
        /// description of source
        ///
        /// often this is just the <meta> description tag from the website
        public var description: String
        
        /// determines if the source is pinned
        ///
        /// used so that displayed sources are sorted alphabetically with
        /// pinned sources at the top
        public var pinned: Bool = false
        
        /// determines if the source is disabled
        ///
        /// disabled sources are placed either at the bottom of lists or
        /// not displayed at all.
        /// disabled sources are not used in any content refreshes, not
        /// displayed in any search results and any origins belonging to
        /// the disabled source do not display their chapters if any.
        public var disabled: Bool = false
        
        init(
            id: Int64? = nil,
            hostId: Int64,
            name: String,
            icon: String,
            path: String,
            website: String,
            description: String,
            pinned: Bool = false,
            disabled: Bool = false
        ) {
            self.id = id
            self.hostId = hostId
            self.name = name
            self.icon = icon
            self.path = path
            self.website = website
            self.description = description
            self.pinned = pinned
            self.disabled = disabled
        }
    }
}

// MARK: - Database Conformance
extension Source: FetchableRecord, PersistableRecord {}

extension Source: TableRecord {
    public enum Columns {
        public static let id = Column(CodingKeys.id)
        public static let hostId = Column(CodingKeys.hostId)
        
        public static let name = Column(CodingKeys.name)
        public static let icon = Column(CodingKeys.icon)
        public static let path = Column(CodingKeys.path)
        
        public static let website = Column(CodingKeys.website)
        public static let description = Column(CodingKeys.description)
        
        public static let pinned = Column(CodingKeys.pinned)
        public static let disabled = Column(CodingKeys.disabled)
    }
}

// MARK: - Database Relations
extension Source {
    // belongs to a single host
    static let host = belongsTo(Domain.Models.Persistence.Host.self)
    var host: QueryInterfaceRequest<Domain.Models.Persistence.Host> {
        request(for: Domain.Models.Persistence.Source.host)
    }
    
    // has many routes
    static let routes = hasMany(Domain.Models.Persistence.SourceRoute.self)
    var routes: QueryInterfaceRequest<Domain.Models.Persistence.SourceRoute> {
        request(for: Domain.Models.Persistence.Source.routes)
    }
    
    // has many origins
    static let origins = hasMany(Domain.Models.Persistence.Origin.self)
}

// MARK: - Database Table Definition + Migrations
extension Source: DatabaseMigratable {
    static func createTable(db: Database) throws {
        try db.create(table: databaseTableName, body: { t in
            // ids
            t.autoIncrementedPrimaryKey(Columns.id.name)
            t.column(Columns.hostId.name, .integer)
                .notNull()
                .references(Host.databaseTableName, onDelete: .cascade)
            
            // properties
            t.column(Columns.name.name, .text).notNull()
            t.column(Columns.icon.name, .text).notNull()
            t.column(Columns.path.name, .text).notNull()
            
            // external
            t.column(Columns.website.name, .text).notNull()
            t.column(Columns.description.name, .text).notNull()
            
            // controls
            t.column(Columns.pinned.name, .boolean).notNull()
            t.column(Columns.disabled.name, .boolean).notNull()
        })
    }
    
    static func migrate(with migrator: inout GRDB.DatabaseMigrator, from version: Version) throws {
        // nothing for now
    }
}

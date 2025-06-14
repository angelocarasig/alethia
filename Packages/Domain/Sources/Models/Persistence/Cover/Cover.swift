//
//  Cover.swift
//  Domain
//
//  Created by Angelo Carasig on 14/6/2025.
//
import GRDB

internal typealias Cover = Domain.Models.Persistence.Cover

public extension Domain.Models.Persistence {
    /// represents a cover image for a manga
    struct Cover: Identifiable, Equatable, Codable {
        // MARK: - Properties
        
        /// unique database identifier
        public var id: Int64?
        
        /// associated manga for this cover
        public var mangaId: Int64
        
        /// whether this cover is the active one
        public var active: Bool
        
        /// url to the cover image
        public var url: String
        
        /// local file path to the cached cover
        public var path: String
        
        init(
            id: Int64? = nil,
            mangaId: Int64,
            active: Bool,
            url: String,
            path: String
        ) {
            self.id = id
            self.mangaId = mangaId
            self.active = active
            self.url = url
            self.path = path
        }
    }
}

// MARK: - Database Conformance
extension Cover: FetchableRecord, PersistableRecord {}

extension Cover: TableRecord {
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
    static let manga = belongsTo(Domain.Models.Persistence.Manga.self)
    var manga: QueryInterfaceRequest<Domain.Models.Persistence.Manga> {
        request(for: Cover.manga)
    }
}

// MARK: - Database Table Definition + Migrations
extension Cover: DatabaseMigratable {
    static func createTable(db: Database) throws {
        try db.create(table: databaseTableName, body: { t in
            // ids
            t.autoIncrementedPrimaryKey(Columns.id.name)
            
            t.column(Columns.mangaId.name, .integer)
                .notNull()
                .references(Manga.databaseTableName, onDelete: .cascade)
            
            // properties
            t.column(Columns.active.name, .boolean)
                .notNull()
            
            t.column(Columns.url.name, .text).notNull()
            t.column(Columns.path.name, .text).notNull()
        })
    }
    
    static func migrate(with migrator: inout DatabaseMigrator, from version: Version) throws {
        // nothing for now
    }
}

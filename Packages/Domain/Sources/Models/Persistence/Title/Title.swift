//
//  Title.swift
//  Domain
//
//  Created by Angelo Carasig on 14/6/2025.
//
import GRDB

internal typealias Title = Domain.Models.Persistence.Title

public extension Domain.Models.Persistence {
    /// represents a title for a manga and generally considered as alternative titles
    struct Title: Identifiable, Codable {
        // MARK: - Properties
        
        /// unique database identifier
        public var id: Int64?
        
        /// associated manga for this title
        public var mangaId: Int64
        
        /// alternative title for the manga
        public var title: String
        
        init(
            id: Int64? = nil,
            mangaId: Int64,
            title: String
        ) {
            self.id = id
            self.mangaId = mangaId
            self.title = title
        }
    }
}

// MARK: - Database Conformance
extension Title: FetchableRecord, PersistableRecord {}

extension Title: TableRecord {
    public enum Columns {
        public static let id = Column(CodingKeys.id)
        public static let mangaId = Column(CodingKeys.mangaId)
        public static let title = Column(CodingKeys.title)
    }
}

// MARK: - Database Relations
extension Title {
    // belongs to a single manga
    static let manga = belongsTo(Domain.Models.Persistence.Manga.self)
    var manga: QueryInterfaceRequest<Domain.Models.Persistence.Manga> {
        request(for: Domain.Models.Persistence.Title.manga)
    }
}

// MARK: - Database Table Definition + Migrations
extension Title: DatabaseMigratable {
    static func createTable(db: Database) throws {
        try db.create(table: databaseTableName, body: { t in
            // ids
            t.autoIncrementedPrimaryKey(Columns.id.name)
            
            t.column(Columns.mangaId.name, .integer)
                .notNull()
                .references(Manga.databaseTableName, onDelete: .cascade)
            
            // properties
            t.column(Columns.title.name, .text)
                .notNull()
                .collate(.nocase)
            
            // all titles for a given manga must be unique - if not we can just skip
            // titles themselves don't need to be unique - should be resolved by user in UI layer
            t.uniqueKey([Columns.title.name, Columns.mangaId.name], onConflict: .ignore)
        })
    }
    
    static func migrate(with migrator: inout DatabaseMigrator, from version: Version) throws {
        // nothing for now
    }
}

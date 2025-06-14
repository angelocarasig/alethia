//
//  MangaCollection.swift
//  Domain
//
//  Created by Angelo Carasig on 14/6/2025.
//
import GRDB

internal typealias MangaCollection = Domain.Models.Persistence.MangaCollection

public extension Domain.Models.Persistence {
    // a manga can have many collections
    // a collection can have many manga
    struct MangaCollection: Codable {
        // MARK: - Properties
        
        /// joiner to associated manga id
        public var mangaId: Int64
        
        /// joiner to associated collection id
        public var collectionId: Int64
        
        init(
            mangaId: Int64,
            collectionId: Int64
        ) {
            self.mangaId = mangaId
            self.collectionId = collectionId
        }
    }
}

// MARK: - Database Conformance
extension MangaCollection: FetchableRecord, PersistableRecord {}

extension MangaCollection: TableRecord {
    public enum Columns {
        public static let mangaId = Column(CodingKeys.mangaId)
        public static let collectionId = Column(CodingKeys.collectionId)
    }
}

// MARK: - Database Relations
extension MangaCollection {
    // belongs to a particular manga
    static let manga = belongsTo(Domain.Models.Persistence.Manga.self)
    
    // belongs to a particular collection
    static let collection = belongsTo(Domain.Models.Persistence.Collection.self)
}

// MARK: - Database Table Definition + Migrations
extension MangaCollection: Domain.Models.Database.DatabaseMigratable {
    public static func createTable(db: Database) throws {
        try db.create(table: databaseTableName, body: { t in
            // note: no composite primary key here as manga can be in multiple collections
            
            t.column(Columns.mangaId.name, .integer)
                .notNull()
                .references(Manga.databaseTableName, onDelete: .setNull)
            
            t.column(Columns.collectionId.name, .integer)
                .notNull()
                .references(Collection.databaseTableName, onDelete: .cascade)
        })
    }
    
    public static func migrate(with migrator: inout DatabaseMigrator, from version: Domain.Models.Database.Version) throws {
        // nothing for now
    }
}

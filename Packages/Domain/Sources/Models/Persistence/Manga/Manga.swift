//
//  Manga.swift
//  Domain
//
//  Created by Angelo Carasig on 14/6/2025.
//

import Foundation
import GRDB

internal typealias Manga = Domain.Models.Persistence.Manga

public extension Domain.Models.Persistence {
    /// a manga series
    ///
    /// the main unit of the app really
    struct Manga: Identifiable, Codable {
        // MARK: - Properties
        
        /// unique database identifier
        public var id: Int64?
        
        /// title of manga
        public var title: String
        
        /// synopsis of manga
        ///
        /// using `syonpsis` keyword instead of description to prevent
        /// potential conflicts just in internal naming conventions
        public var synopsis: String
        
        /// date the manga was added at
        public var addedAt: Date = Date()
        
        /// date the manga was last updated
        ///
        /// this property more specifically is whenever a new chapter for
        /// the manga is actually inserted, not when it was last refreshed
        public var updatedAt: Date = Date()
        
        /// date the manga was last read at
        public var lastReadAt: Date? = nil
        
        /// whether manga is in the library or not
        public var inLibrary: Bool = false
        
        /// reading orientation of the manga
        ///
        /// defaults to the `Default` orientation, which in this case
        /// will be inferred whether to show a horizontal/vertical orientation
        ///
        /// any subsequent updates can and should only be out of the 4 non-default
        /// options which essentially acts as an override over the inferring value
        public var orientation: Domain.Models.Enums.Orientation = .Default
        
        /// control what chapters to show - whether to show all chapters
        public var showAllChapters: Bool = false
        
        /// control what chapters to show - whether to show non-integer chapters
        ///
        /// more specifically:
        /// - where chapter.number ∈ ℤ (e.g., 1, 2, 3)
        /// - chapter.number ∈ ℝ\ℤ (e.g., 1.5, 2.1, 3.9)
        public var showHalfChapters: Bool = true
        
        init(title: String, synopsis: String) {
            self.title = title
            self.synopsis = synopsis
        }
    }
}

// MARK: - Database Conformance
extension Manga: FetchableRecord, PersistableRecord {}

extension Manga: TableRecord {
    public enum Columns {
        public static let id = Column(CodingKeys.id)
        public static let title = Column(CodingKeys.title)
        public static let synopsis = Column(CodingKeys.synopsis)
        
        public static let addedAt = Column(CodingKeys.addedAt)
        public static let updatedAt = Column(CodingKeys.updatedAt)
        public static let lastReadAt = Column(CodingKeys.lastReadAt)
        
        public static let inLibrary = Column(CodingKeys.inLibrary)
        public static let orientation = Column(CodingKeys.orientation)
        public static let showAllChapters = Column(CodingKeys.showAllChapters)
        public static let showHalfChapters = Column(CodingKeys.showHalfChapters)
    }
}

// MARK: - Database Relations
extension Manga {
    // has many titles
    public static let titles = hasMany(Domain.Models.Persistence.Title.self)
    var titles: QueryInterfaceRequest<Domain.Models.Persistence.Title> {
        request(for: Manga.titles)
    }
    
    // has many covers
    public static let covers = hasMany(Domain.Models.Persistence.Cover.self)
    var covers: QueryInterfaceRequest<Domain.Models.Persistence.Cover> {
        request(for: Manga.covers)
    }
    
    // has many origins
    public static let origins = hasMany(Domain.Models.Persistence.Origin.self)
    var origins: QueryInterfaceRequest<Domain.Models.Persistence.Origin> {
        request(for: Manga.origins)
    }
    
    // has many authors
    public static let mangaAuthors = hasMany(Domain.Models.Persistence.MangaAuthor.self)
    public static let authors = hasMany(Author.self, through: mangaAuthors, using: MangaAuthor.author)
    var authors: QueryInterfaceRequest<Domain.Models.Persistence.Author> {
        request(for: Manga.authors)
    }
    
    // has many tags
    public static let tags = hasMany(Domain.Models.Persistence.Tag.self)
    var tags: QueryInterfaceRequest<Domain.Models.Persistence.Tag> {
        request(for: Manga.tags)
    }
    
    // has many collections
    public static let mangaCollections = hasMany(Domain.Models.Persistence.MangaCollection.self)
    public static let collections = hasMany(Collection.self, through: mangaCollections, using: Domain.Models.Persistence.MangaCollection.collection)
    var collections: QueryInterfaceRequest<Domain.Models.Persistence.Collection> {
        request(for: Manga.collections)
    }
}

// MARK: - Database Table Definition + Migrations
extension Manga: DatabaseMigratable {
    static func createTable(db: Database) throws {
        try db.create(table: databaseTableName, body: { t in
            // ids
            t.autoIncrementedPrimaryKey(Columns.id.name)
            
            // properties
            t.column(Columns.title.name, .text)
                .notNull()
                .collate(.nocase)
            t.column(Columns.synopsis.name, .text).notNull()
            t.column(Columns.addedAt.name, .datetime).notNull()
            t.column(Columns.updatedAt.name, .datetime).notNull()
            t.column(Columns.lastReadAt.name, .datetime) // Include from start
            
            // control
            t.column(Columns.inLibrary.name, .boolean).notNull()
            t.column(Columns.orientation.name, .text).notNull()
            t.column(Columns.showAllChapters.name, .boolean).notNull()
            t.column(Columns.showHalfChapters.name, .boolean).notNull()
        })
    }
    
    static func migrate(with migrator: inout DatabaseMigrator, from version: Version) throws {
        // nothing for now
    }
}

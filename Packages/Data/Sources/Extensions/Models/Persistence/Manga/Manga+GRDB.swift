//
//  Manga+GRDB.swift
//  Data
//
//  Created by Angelo Carasig on 15/6/2025.
//

import Foundation
import Domain
import GRDB


private typealias Manga = Domain.Models.Persistence.Manga
private typealias Title = Domain.Models.Persistence.Title
private typealias Cover = Domain.Models.Persistence.Cover
private typealias Origin = Domain.Models.Persistence.Origin
private typealias MangaAuthor = Domain.Models.Persistence.MangaAuthor
private typealias Author = Domain.Models.Persistence.Author
private typealias Tag = Domain.Models.Persistence.Tag
private typealias MangaCollection = Domain.Models.Persistence.MangaCollection
private typealias Collection = Domain.Models.Persistence.Collection

// MARK: - Database Conformance
extension Manga: @retroactive FetchableRecord {}

extension Manga: @retroactive PersistableRecord {}

extension Manga: @retroactive TableRecord {
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
    var titles: QueryInterfaceRequest<Title> {
        request(for: Domain.Models.Persistence.Manga.titles)
    }
    
    // has many covers
    public static let covers = hasMany(Domain.Models.Persistence.Cover.self)
    var covers: QueryInterfaceRequest<Cover> {
        request(for: Domain.Models.Persistence.Manga.covers)
    }
    
    // has many origins
    public static let origins = hasMany(Domain.Models.Persistence.Origin.self)
    var origins: QueryInterfaceRequest<Origin> {
        request(for: Domain.Models.Persistence.Manga.origins)
    }
    
    // has many authors
    public static let mangaAuthors = hasMany(Domain.Models.Persistence.MangaAuthor.self)
    public static let authors = hasMany(Domain.Models.Persistence.Author.self, through: mangaAuthors, using: Domain.Models.Persistence.MangaAuthor.author)
    var authors: QueryInterfaceRequest<Author> {
        request(for: Domain.Models.Persistence.Manga.authors)
    }
    
    // has many tags
    public static let tags = hasMany(Domain.Models.Persistence.Tag.self)
    var tags: QueryInterfaceRequest<Tag> {
        request(for: Domain.Models.Persistence.Manga.tags)
    }
    
    // has many collections
    public static let mangaCollections = hasMany(Domain.Models.Persistence.MangaCollection.self)
    public static let collections = hasMany(Domain.Models.Persistence.Collection.self, through: mangaCollections, using: Domain.Models.Persistence.MangaCollection.collection)
    var collections: QueryInterfaceRequest<Collection> {
        request(for: Domain.Models.Persistence.Manga.collections)
    }
}

// MARK: - Database Table Definition + Migrations
extension Manga: @retroactive Data.Infrastructure.DatabaseMigratable {
    public static func createTable(db: Database) throws {
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
    
    public static func migrate(with migrator: inout DatabaseMigrator, from version: Data.Infrastructure.Version) throws {
        // nothing for now
    }
}

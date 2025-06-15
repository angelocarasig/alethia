//
//  Origin+GRDB.swift
//  Data
//
//  Created by Angelo Carasig on 15/6/2025.
//

import Foundation
import GRDB
import Domain


private typealias Origin = Domain.Models.Persistence.Origin
private typealias Manga = Domain.Models.Persistence.Manga
private typealias Source = Domain.Models.Persistence.Source
private typealias Chapter = Domain.Models.Persistence.Chapter
private typealias Channel = Domain.Models.Persistence.Channel
private typealias Scanlator = Domain.Models.Persistence.Scanlator

// MARK: - Database Conformance
extension Origin: @retroactive FetchableRecord {}

extension Origin: @retroactive PersistableRecord {}

extension Origin: @retroactive TableRecord {
    public enum Columns {
        public static let id = Column(CodingKeys.id)
        public static let sourceId = Column(CodingKeys.sourceId)
        public static let mangaId = Column(CodingKeys.mangaId)
        
        public static let slug = Column(CodingKeys.slug)
        public static let url = Column(CodingKeys.url)
        public static let referer = Column(CodingKeys.referer)
        public static let classification = Column(CodingKeys.classification)
        public static let status = Column(CodingKeys.status)
        public static let createdAt = Column(CodingKeys.createdAt)
        
        public static let priority = Column(CodingKeys.priority)
    }
}

// MARK: - Database Relations
extension Origin {
    // belongs to a single manga
    public static let manga = belongsTo(Domain.Models.Persistence.Manga.self)
    
    // belongs to a single (optional) source
    public static let source = belongsTo(Domain.Models.Persistence.Source.self)
    var source: QueryInterfaceRequest<Domain.Models.Persistence.Source> {
        request(for: Domain.Models.Persistence.Origin.source)
    }
    
    // has many chapters
    public static let chapters = hasMany(Domain.Models.Persistence.Chapter.self)
    var chapters: QueryInterfaceRequest<Domain.Models.Persistence.Chapter> {
        request(for: Domain.Models.Persistence.Origin.chapters)
    }
    
    // has many channels
    public static let channels = hasMany(Domain.Models.Persistence.Channel.self)
    
    // has many scanlators
    public static let scanlators = hasMany(Domain.Models.Persistence.Scanlator.self, through: channels, using: Domain.Models.Persistence.Channel.scanlator)
}

// MARK: - Database Table Definition + Migrations
extension Origin: @retroactive Data.Infrastructure.DatabaseMigratable {
    public static func createTable(db: Database) throws {
        try db.create(table: databaseTableName, body: { t in
            // ids
            t.autoIncrementedPrimaryKey(Columns.id.name)
            t.column(Columns.sourceId.name, .integer)
                .references(Domain.Models.Persistence.Source.databaseTableName, onDelete: .setNull)
            t.column(Columns.mangaId.name, .integer)
                .notNull()
                .references(Domain.Models.Persistence.Manga.databaseTableName, onDelete: .cascade)
            
            // properties
            t.column(Columns.slug.name, .text).notNull()
            t.column(Columns.url.name, .text).notNull()
            t.column(Columns.referer.name, .text).notNull()
            t.column(Columns.classification.name, .text).notNull()
            t.column(Columns.status.name, .text).notNull()
            t.column(Columns.createdAt.name, .date).notNull()
            
            // control
            t.column(Columns.priority.name, .integer).notNull()
        })
    }
    
    public static func migrate(with migrator: inout DatabaseMigrator, from version: Data.Infrastructure.Version) throws {
        // nothing for now
    }
}

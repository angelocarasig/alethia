//
//  Chapter+GRDB.swift
//  Data
//
//  Created by Angelo Carasig on 15/6/2025.
//

import Domain
import GRDB

private typealias Chapter = Domain.Models.Persistence.Chapter
private typealias Origin = Domain.Models.Persistence.Origin
private typealias Scanlator = Domain.Models.Persistence.Scanlator

// MARK: - Database Conformance
extension Chapter: @retroactive FetchableRecord {}

extension Chapter: @retroactive PersistableRecord {}

extension Chapter: @retroactive TableRecord {
    public enum Columns {
        public static let id = Column(CodingKeys.id)
        public static let originId = Column(CodingKeys.originId)
        public static let scanlatorId = Column(CodingKeys.scanlatorId)
        
        public static let title = Column(CodingKeys.title)
        public static let slug = Column(CodingKeys.slug)
        public static let number = Column(CodingKeys.number)
        public static let date = Column(CodingKeys.date)
        
        public static let progress = Column(CodingKeys.progress)
        public static let localPath = Column(CodingKeys.localPath)
    }
}

// MARK: - Database Relations
extension Chapter {
    // relates to an origin
    public static let origin = belongsTo(Domain.Models.Persistence.Origin.self)
    
    // relates to a scanlator
    public static let scanlator = belongsTo(Domain.Models.Persistence.Scanlator.self)
}

// MARK: - Database Table Definition + Migrations
extension Chapter: @retroactive Data.Infrastructure.DatabaseMigratable {
    public static func createTable(db: Database) throws {
        try db.create(table: self.databaseTableName, body: { t in
            // ids
            t.autoIncrementedPrimaryKey(Columns.id.name)
            t.column(Columns.originId.name, .integer)
                .notNull()
                .references(Domain.Models.Persistence.Origin.databaseTableName, onDelete: .cascade)
            t.column(Columns.scanlatorId.name, .integer)
                .notNull()
                .references(Domain.Models.Persistence.Scanlator.databaseTableName, onDelete: .restrict)
            
            // properties
            t.column(Columns.title.name, .text).notNull()
            t.column(Columns.slug.name, .text).notNull()
            t.column(Columns.number.name, .double).notNull()
            t.column(Columns.date.name, .datetime).notNull()
            
            // control
            t.column(Columns.progress.name, .double).notNull()
            t.column(Columns.localPath.name, .text)
        })
    }
    
    public static func migrate(with migrator: inout DatabaseMigrator, from version: Data.Infrastructure.Version) throws {
        // nothing for now
    }
}

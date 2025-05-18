//
//  Origin.swift
//  Alethia
//
//  Created by Angelo Carasig on 10/4/2025.
//

import Foundation
import GRDB

struct Origin: Codable, Identifiable {
    var id: Int64?
    
    var mangaId: Int64
    var sourceId: Int64?
    
    var slug: Slug
    var url: String
    var referer: String
    var classification: Classification
    var status: PublishStatus
    var createdAt: Date
    var priority: Int = .max
}

extension Origin {
    static let manga = belongsTo(Manga.self)
    static let source = belongsTo(Source.self)
    static let chapters = hasMany(Chapter.self)
}

extension Origin {
    var manga: QueryInterfaceRequest<Manga> {
        request(for: Origin.manga)
    }
    
    var source: QueryInterfaceRequest<Source> {
        request(for: Origin.source)
    }
    
    var chapters: QueryInterfaceRequest<Chapter> {
        request(for: Origin.chapters)
    }
}

extension Origin: TableRecord {
    enum Columns {
        static let id = Column(Origin.CodingKeys.id)
        static let sourceId = Column(Origin.CodingKeys.sourceId)
        static let mangaId = Column(Origin.CodingKeys.mangaId)
        
        static let slug = Column(Origin.CodingKeys.slug)
        static let url = Column(Origin.CodingKeys.url)
        static let referer = Column(Origin.CodingKeys.referer)
        static let classification = Column(Origin.CodingKeys.classification)
        static let status = Column(Origin.CodingKeys.status)
        static let createdAt = Column(Origin.CodingKeys.createdAt)
        static let priority = Column(Origin.CodingKeys.priority)
    }
}

extension Origin: FetchableRecord {}
extension Origin: PersistableRecord {}

extension Origin: DatabaseModel {
    static var version: Version = Version(1, 0, 0)
    
    static func createTable(db: Database) throws {
        try db.create(table: databaseTableName, body: { t in
            t.autoIncrementedPrimaryKey(Columns.id.name)
            
            t.column(Columns.slug.name, .text).notNull()
            t.column(Columns.url.name, .text).notNull()
            t.column(Columns.referer.name, .text).notNull()
            t.column(Columns.classification.name, .text).notNull()
            t.column(Columns.status.name, .text).notNull()
            t.column(Columns.createdAt.name, .date).notNull()
            t.column(Columns.priority.name, .integer).notNull()
            
            t.column(Columns.mangaId.name, .integer)
                .notNull()
                .indexed()
                .references(Manga.databaseTableName, onDelete: .cascade)
            
            t.column(Columns.sourceId.name, .integer)
                .indexed()
                .references(Source.databaseTableName, onDelete: .setNull)
        })
    }
    
    static func migrate(with migrator: inout DatabaseMigrator, from version: Version) throws {
        // Nothing for now
        
        // TODO: Create unique index (no duplicate priority values per mangaId)
    }
}

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
    
    var slug: String
    var url: String
    var referer: String
    var classification: Classification
    var status: PublishStatus
    var createdAt: Date
    var priority: Int = -1
}

extension Origin {
    static let manga = belongsTo(Manga.self)
    static let source = belongsTo(Source.self)
    static let chapters = hasMany(Chapter.self)
    
    static let originScanlator = hasMany(OriginScanlator.self)
    static let scanlators = hasMany(Scanlator.self, through: originScanlator, using: OriginScanlator.scanlator)
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
    
    var scanlators: QueryInterfaceRequest<Scanlator> {
        request(for: Origin.scanlators)
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
            
            // Ensure no duplicate priority values for the same manga
            t.uniqueKey([Columns.priority.name, Columns.mangaId.name], onConflict: .fail)
        })
        
        try db.create(index: "idx_origin_manga_priority",
                      on: Origin.databaseTableName,
                      columns: [Columns.mangaId.name, Columns.priority.name])
    }
    
    static func migrate(with migrator: inout DatabaseMigrator, from version: Version) throws {
        if version < Version(1, 0, 2) {
            migrator.registerMigration("remove_origin_source_manga_unique_v1.0.2") { db in
                try db.rename(table: "origin", to: "origin_old")
                
                try db.create(table: "origin", body: { t in
                    t.autoIncrementedPrimaryKey("id")
                    
                    t.column("slug", .text).notNull()
                    t.column("url", .text).notNull()
                    t.column("referer", .text).notNull()
                    t.column("classification", .text).notNull()
                    t.column("status", .text).notNull()
                    t.column("createdAt", .date).notNull()
                    t.column("priority", .integer).notNull()
                    
                    t.column("mangaId", .integer)
                        .notNull()
                        .references("manga", onDelete: .cascade)
                    
                    t.column("sourceId", .integer)
                        .references("source", onDelete: .setNull)
                    
                    t.uniqueKey(["priority", "mangaId"], onConflict: .fail)
                })
                
                try db.create(index: "origin_mangaId_idx",
                              on: "origin",
                              columns: ["mangaId"])
                
                try db.create(index: "origin_sourceId_idx",
                              on: "origin",
                              columns: ["sourceId"])
                
                try db.execute(sql: """
                INSERT INTO origin (id, mangaId, sourceId, slug, url, referer, 
                                  classification, status, createdAt, priority)
                SELECT id, mangaId, sourceId, slug, url, referer, 
                       classification, status, createdAt, priority
                FROM origin_old
            """)
                
                try db.drop(table: "origin_old")
            }
        }
    }
}

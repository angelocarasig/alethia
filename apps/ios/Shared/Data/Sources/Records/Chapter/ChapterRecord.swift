//
//  ChapterRecord.swift
//  Data
//
//  Created by Angelo Carasig on 28/9/2025.
//

import Foundation
import GRDB
import Tagged
import Domain

internal struct ChapterRecord: Codable, DatabaseRecord {
    typealias ID = Tagged<Self, Int64>
    private(set) var id: ID?
    
    private(set) var originId: OriginRecord.ID
    private(set) var scanlatorId: ScanlatorRecord.ID
    
    var slug: String
    var title: String
    var number: Double
    var date: Date
    var url: URL
    var language: Domain.LanguageCode
    var progress: Double
    var lastReadAt: Date?
    
    var finished: Bool {
        progress >= 1
    }
}

// MARK: - DatabaseRecord

extension ChapterRecord {
    static var databaseTableName: String {
        "chapter"
    }
    
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let originId = Column(CodingKeys.originId)
        static let scanlatorId = Column(CodingKeys.scanlatorId)
        
        static let slug = Column(CodingKeys.slug)
        static let title = Column(CodingKeys.title)
        static let number = Column(CodingKeys.number)
        static let date = Column(CodingKeys.date)
        static let url = Column(CodingKeys.url)
        static let language = Column(CodingKeys.language)
        static let progress = Column(CodingKeys.progress)
        static let lastReadAt = Column(CodingKeys.lastReadAt)
    }
    
    static func createTable(db: Database) throws {
        try db.create(table: databaseTableName, options: [.ifNotExists]) { t in
            t.autoIncrementedPrimaryKey(Columns.id.name)
            
            t.belongsTo(OriginRecord.databaseTableName, onDelete: .cascade)
            t.belongsTo(ScanlatorRecord.databaseTableName, onDelete: .restrict)
            
            t.column(Columns.slug.name, .text).notNull()
            t.column(Columns.title.name, .text).notNull()
            t.column(Columns.number.name, .real).notNull()
            t.column(Columns.date.name, .datetime).notNull()
            t.column(Columns.url.name, .text).notNull()
            t.column(Columns.language.name, .text).notNull()
            t.column(Columns.progress.name, .real).notNull()
            t.column(Columns.lastReadAt.name, .datetime)
        }
    }
    
    static func migrate(with migrator: inout GRDB.DatabaseMigrator, from version: DatabaseVersion) throws {
        switch version {
        case ..<DatabaseVersion(1, 0, 0):
            let migrationName = DatabaseVersion(1, 0, 0).createMigrationName(description: "chapter initial indexes")
            migrator.registerMigration(migrationName) { db in
                try db.create(index: "idx_chapter_originId", on: databaseTableName, columns: [Columns.originId.name])
                try db.create(index: "idx_chapter_scanlatorId", on: databaseTableName, columns: [Columns.scanlatorId.name])
                try db.create(index: "idx_chapter_slug", on: databaseTableName, columns: [Columns.slug.name])
                
                // composite index for deduplication queries
                try db.create(index: "idx_chapter_dedup", on: databaseTableName, columns: [
                    Columns.originId.name,
                    Columns.number.name
                ])
            }
        default:
            break
        }
    }
    
    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = ID(rawValue: inserted.rowID)
    }
}

// MARK: - Associations

extension ChapterRecord {
    static let origin = belongsTo(OriginRecord.self)
    
    var origin: QueryInterfaceRequest<OriginRecord> {
        request(for: ChapterRecord.origin)
    }
}

extension ChapterRecord {
    static let scanlator = belongsTo(ScanlatorRecord.self)
    
    var scanlator: QueryInterfaceRequest<ScanlatorRecord> {
        request(for: ChapterRecord.scanlator)
    }
}

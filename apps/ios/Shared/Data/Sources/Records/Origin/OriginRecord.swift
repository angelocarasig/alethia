//
//  OriginRecord.swift
//  Data
//
//  Created by Angelo Carasig on 28/9/2025.
//

import GRDB
import Tagged
import Domain

internal struct OriginRecord: Codable, DatabaseRecord {
    typealias ID = Tagged<Self, Int64>
    private(set) var id: ID?
    private(set) var mangaId: MangaRecord.ID
    private(set) var sourceId: SourceRecord.ID? // mutate only via TableRecord.delete()
    
    private(set) var slug: String
    private(set) var url: String
    var priority: Int
    var classification: Domain.Classification
    var status: Domain.Status
    
    var disconnected: Bool {
        sourceId == nil
    }
}

// MARK: - DatabaseRecord

extension OriginRecord {
    static var databaseTableName: String {
        "origin"
    }
    
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let mangaId = Column(CodingKeys.mangaId)
        static let sourceId = Column(CodingKeys.sourceId)
        
        static let slug = Column(CodingKeys.slug)
        static let url = Column(CodingKeys.url)
        static let priority = Column(CodingKeys.priority)
        static let classification = Column(CodingKeys.classification)
        static let status = Column(CodingKeys.status)
    }
    
    static func createTable(db: Database) throws {
        try db.create(table: databaseTableName, options: [.ifNotExists]) { t in
            t.autoIncrementedPrimaryKey(Columns.id.name)
            
            t.belongsTo(MangaRecord.databaseTableName, onDelete: .cascade)
            t.column(Columns.sourceId.name, .integer)
                .references(SourceRecord.databaseTableName, onDelete: .setNull)
            
            t.column(Columns.slug.name, .text).notNull().indexed()
            t.column(Columns.url.name, .text).notNull()
            t.column(Columns.priority.name, .integer).notNull().defaults(to: 0)
            t.column(Columns.classification.name, .text).notNull()
            t.column(Columns.status.name, .text).notNull()
        }
    }
    
    static func migrate(with migrator: inout GRDB.DatabaseMigrator, from version: DatabaseVersion) throws {
        switch version {
        case ..<DatabaseVersion(1, 0, 0):
            let migrationName = DatabaseVersion(1, 0, 0).createMigrationName(description: "origin initial indexes")
            migrator.registerMigration(migrationName) { db in
                // foreign key indexes
                try db.create(index: "idx_origin_mangaId", on: databaseTableName, columns: [Columns.mangaId.name])
                try db.create(index: "idx_origin_sourceId", on: databaseTableName, columns: [Columns.sourceId.name])
                
                // slug index already created inline with .indexed()
                
                // composite index for origin priority lookup
                try db.create(index: "idx_origin_priority", on: databaseTableName, columns: [
                    Columns.mangaId.name,
                    Columns.priority.name
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

extension OriginRecord {
    static let manga = belongsTo(MangaRecord.self)
    
    var manga: QueryInterfaceRequest<MangaRecord> {
        request(for: OriginRecord.manga)
    }
}

extension OriginRecord {
    static let source = belongsTo(SourceRecord.self)
    
    var source: QueryInterfaceRequest<SourceRecord> {
        request(for: OriginRecord.source)
    }
}

extension OriginRecord {
    static let chapters = hasMany(ChapterRecord.self)
    
    var chapters: QueryInterfaceRequest<ChapterRecord> {
        request(for: OriginRecord.chapters)
    }
}

extension OriginRecord {
    static let scanlatorPriorities = hasMany(OriginScanlatorPriorityRecord.self)
        .order(OriginScanlatorPriorityRecord.Columns.priority.asc)
    
    static let prioritizedScanlators = hasMany(
        ScanlatorRecord.self,
        through: scanlatorPriorities,
        using: OriginScanlatorPriorityRecord.scanlator
    )
    
    var prioritizedScanlators: QueryInterfaceRequest<ScanlatorRecord> {
        request(for: OriginRecord.prioritizedScanlators)
    }
}

//
//  SearchTagRecord.swift
//  Data
//
//  Created by Angelo Carasig on 28/9/2025.
//

import Foundation
import GRDB
import Tagged

internal struct SearchTagRecord: Codable, DatabaseRecord {
    typealias ID = Tagged<Self, Int64>
    private(set) var id: ID?
    
    private(set) var sourceId: SourceRecord.ID
    
    var slug: String
    var name: String
    var nsfw: Bool = false
    
    init(sourceId: SourceRecord.ID, slug: String, name: String, nsfw: Bool) {
        self.id = nil
        self.sourceId = sourceId
        self.slug = slug
        self.name = name
        self.nsfw = nsfw
    }
}

// MARK: - DatabaseRecord

extension SearchTagRecord {
    static var databaseTableName: String {
        "search_tag"
    }
    
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let sourceId = Column(CodingKeys.sourceId)
        static let slug = Column(CodingKeys.slug)
        static let name = Column(CodingKeys.name)
        static let nsfw = Column(CodingKeys.nsfw)
    }
    
    static func createTable(db: Database) throws {
        try db.create(table: databaseTableName, options: [.ifNotExists]) { t in
            t.autoIncrementedPrimaryKey(Columns.id.name)
            
            t.belongsTo(SourceRecord.databaseTableName, onDelete: .cascade)
            
            t.column(Columns.slug.name, .text).notNull()
            t.column(Columns.name.name, .text).notNull()
            t.column(Columns.nsfw.name, .boolean).notNull().defaults(to: false)
            
            t.uniqueKey([Columns.sourceId.name, Columns.slug.name])
        }
    }
    
    static func migrate(with migrator: inout GRDB.DatabaseMigrator, from version: DatabaseVersion) throws {
        switch version {
        case ..<DatabaseVersion(1, 0, 0):
            let migrationName = DatabaseVersion(1, 0, 0).createMigrationName(description: "search tag initial indexes")
            migrator.registerMigration(migrationName) { db in
                // foreign key index
                try db.create(index: "idx_search_tag_sourceId", on: databaseTableName, columns: [Columns.sourceId.name])
                
                // slug index for lookups
                try db.create(index: "idx_search_tag_slug", on: databaseTableName, columns: [Columns.slug.name])
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

extension SearchTagRecord {
    static let source = belongsTo(SourceRecord.self)
    
    var source: QueryInterfaceRequest<SourceRecord> {
        request(for: SearchTagRecord.source)
    }
}

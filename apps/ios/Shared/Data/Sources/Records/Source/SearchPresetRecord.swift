//
//  SearchPresetRecord.swift
//  Data
//
//  Created by Angelo Carasig on 28/9/2025.
//

import Foundation
import GRDB
import Tagged
import Domain

internal struct SearchPresetRecord: Codable, DatabaseRecord {
    typealias ID = Tagged<Self, Int64>
    private(set) var id: ID?
    
    private(set) var sourceId: SourceRecord.ID
    
    var name: String
    var description: String?
    var request: Data // JSON-Encoded PresetRequest
    
    init(sourceId: SourceRecord.ID, name: String, description: String?, request: Data) {
        self.id = nil
        self.sourceId = sourceId
        self.name = name
        self.description = description
        self.request = request
    }
}

// MARK: - DatabaseRecord

extension SearchPresetRecord {
    static var databaseTableName: String {
        "search_preset"
    }
    
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let sourceId = Column(CodingKeys.sourceId)
        static let name = Column(CodingKeys.name)
        static let description = Column(CodingKeys.description)
        static let request = Column(CodingKeys.request)
    }
    
    static func createTable(db: Database) throws {
        try db.create(table: databaseTableName, options: [.ifNotExists]) { t in
            t.autoIncrementedPrimaryKey(Columns.id.name)
            
            t.belongsTo(SourceRecord.databaseTableName, onDelete: .cascade)
            
            t.column(Columns.name.name, .text).notNull()
            t.column(Columns.description.name, .text).defaults(to: "")
            t.column(Columns.request.name, .blob).notNull()
        }
    }
    
    static func migrate(with migrator: inout GRDB.DatabaseMigrator, from version: DatabaseVersion) throws {
        switch version {
        case ..<DatabaseVersion(1, 0, 0):
            let migrationName = DatabaseVersion(1, 0, 0).createMigrationName(description: "search preset initial indexes")
            migrator.registerMigration(migrationName) { db in
                try db.create(index: "idx_search_preset_sourceId", on: databaseTableName, columns: [Columns.sourceId.name])
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

extension SearchPresetRecord {
    static let source = belongsTo(SourceRecord.self)
    
    var source: QueryInterfaceRequest<SourceRecord> {
        request(for: SearchPresetRecord.source)
    }
}

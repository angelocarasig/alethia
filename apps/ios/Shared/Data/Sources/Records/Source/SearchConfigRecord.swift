//
//  SearchConfigRecord.swift
//  Data
//
//  Created by Angelo Carasig on 28/9/2025.
//

import Foundation
import GRDB
import Tagged
import Domain

internal struct SearchConfigRecord: Codable, DatabaseRecord {
    typealias ID = Tagged<Self, Int64>
    private(set) var id: ID?
    
    private(set) var sourceId: SourceRecord.ID
    
    var supportedSorts: [Domain.Search.Options.Sort] = []
    var supportedFilters: [Domain.Search.Options.Filter] = []
    
    init(
        sourceId: SourceRecord.ID,
        supportedSorts: [Domain.Search.Options.Sort],
        supportedFilters: [Domain.Search.Options.Filter]
    ) {
        self.id = nil
        self.sourceId = sourceId
        self.supportedSorts = supportedSorts
        self.supportedFilters = supportedFilters
    }
}

// MARK: - DatabaseRecord

extension SearchConfigRecord {
    static var databaseTableName: String {
        "search_config"
    }
    
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let sourceId = Column(CodingKeys.sourceId)
        static let supportedSorts = Column(CodingKeys.supportedSorts)
        static let supportedFilters = Column(CodingKeys.supportedFilters)
    }
    
    static func createTable(db: Database) throws {
        try db.create(table: databaseTableName, options: [.ifNotExists]) { t in
            t.autoIncrementedPrimaryKey(Columns.id.name)
            
            t.belongsTo(SourceRecord.databaseTableName, onDelete: .cascade)
                .unique()
            
            t.column(Columns.supportedSorts.name, .blob).notNull()
            t.column(Columns.supportedFilters.name, .blob).notNull()
        }
    }
    
    static func migrate(with migrator: inout GRDB.DatabaseMigrator, from version: DatabaseVersion) throws {
        switch version {
        case ..<DatabaseVersion(1, 0, 0):
            let migrationName = DatabaseVersion(1, 0, 0).createMigrationName(description: "search config initial indexes")
            migrator.registerMigration(migrationName) { db in
                try db.create(index: "idx_search_config_sourceId", on: databaseTableName, columns: [Columns.sourceId.name])
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

extension SearchConfigRecord {
    static let source = belongsTo(SourceRecord.self)
    
    var source: QueryInterfaceRequest<SourceRecord> {
        request(for: SearchConfigRecord.source)
    }
}

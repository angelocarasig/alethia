//
//  CoverRecord.swift
//  Data
//
//  Created by Angelo Carasig on 28/9/2025.
//

import Foundation
import GRDB
import Tagged
import Domain

internal struct CoverRecord: Codable, DatabaseRecord {
    typealias ID = Tagged<Self, Int64>
    private(set) var id: ID?
    
    private(set) var mangaId: MangaRecord.ID
    
    var isPrimary: Bool = false
    
    var localPath: URL
    var remotePath: URL
}

// MARK: - DatabaseRecord

extension CoverRecord {
    static var databaseTableName: String {
        "cover"
    }
    
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let mangaId = Column(CodingKeys.mangaId)
        
        static let isPrimary = Column(CodingKeys.isPrimary)
        
        static let localPath = Column(CodingKeys.localPath)
        static let remotePath = Column(CodingKeys.remotePath)
    }
    
    static func createTable(db: Database) throws {
        try db.create(table: databaseTableName, options: [.ifNotExists]) { t in
            t.autoIncrementedPrimaryKey(Columns.id.name)
            
            t.belongsTo(MangaRecord.databaseTableName, onDelete: .cascade)
            
            t.column(Columns.isPrimary.name, .boolean).notNull().defaults(to: false)
            
            t.column(Columns.localPath.name, .text).notNull()
            t.column(Columns.remotePath.name, .text).notNull()
        }
    }
    
    static func migrate(with migrator: inout GRDB.DatabaseMigrator, from version: DatabaseVersion) throws {
        switch version {
        case ..<DatabaseVersion(1, 0, 0):
            let migrationName = DatabaseVersion(1, 0, 0).createMigrationName(description: "cover initial indexes")
            migrator.registerMigration(migrationName) { db in
                try db.create(index: "idx_cover_mangaId", on: databaseTableName, columns: [Columns.mangaId.name])
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

extension CoverRecord {
    static let manga = belongsTo(MangaRecord.self)
    
    var manga: QueryInterfaceRequest<MangaRecord> {
        request(for: CoverRecord.manga)
    }
}

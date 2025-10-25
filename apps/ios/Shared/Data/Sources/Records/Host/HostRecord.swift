//
//  HostRecord.swift
//  Data
//
//  Created by Angelo Carasig on 28/9/2025.
//

import Foundation
import GRDB
import Tagged
import Domain

internal struct HostRecord: Codable, DatabaseRecord {
    typealias ID = Tagged<Self, Int64>
    var id: ID?
    
    var name: String
    var author: String
    private(set) var url: URL
    private(set) var repository: URL
    
    var official: Bool
    
    init(name: String, author: String, url: URL, repository: URL, official: Bool) {
        self.id = nil
        self.name = name
        self.author = author
        self.url = url
        self.repository = repository
        self.official = official
    }
}

// MARK: - DatabaseRecord

extension HostRecord {
    static var databaseTableName: String {
        "host"
    }
    
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let name = Column(CodingKeys.name)
        static let author = Column(CodingKeys.author)
        static let url = Column(CodingKeys.url)
        static let repository = Column(CodingKeys.repository)
        static let official = Column(CodingKeys.official)
    }
    
    static func createTable(db: Database) throws {
        try db.create(table: databaseTableName, options: [.ifNotExists]) { t in
            t.autoIncrementedPrimaryKey(Columns.id.name)
            
            t.column(Columns.name.name, .text).notNull()
            t.column(Columns.author.name, .text).notNull()
            t.column(Columns.url.name, .text).notNull().unique(onConflict: .fail)
            t.column(Columns.repository.name, .text).notNull().unique(onConflict: .fail)
            
            t.column(Columns.official.name, .boolean).notNull().defaults(to: false)
        }
    }
    
    static func migrate(with migrator: inout GRDB.DatabaseMigrator, from version: DatabaseVersion) throws {
        switch version {
        case ..<DatabaseVersion(1, 0, 0):
            // initial schema v1.0.0 - no additional indexes needed for host table
            // url and repository columns already have unique indexes automatically
            break
        default:
            break
        }
    }
    
    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = ID(rawValue: inserted.rowID)
    }
}

// MARK: - Associations

extension HostRecord {
    static let sources = hasMany(SourceRecord.self)
        .order(SourceRecord.Columns.name)
    
    var sources: QueryInterfaceRequest<SourceRecord> {
        request(for: HostRecord.sources)
    }
}

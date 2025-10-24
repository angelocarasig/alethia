//
//  SourceRecord.swift
//  Data
//
//  Created by Angelo Carasig on 28/9/2025.
//

import Foundation
import GRDB
import Tagged
import Domain

internal struct SourceRecord: Codable, DatabaseRecord {
    typealias ID = Tagged<Self, Int64>
    private(set) var id: ID?
    
    private(set) var hostId: HostRecord.ID
    
    var slug: String
    var name: String
    var icon: URL
    var url: URL
    var languages: [LanguageCode]
    var pinned: Bool = false
    var disabled: Bool = false
    
    var authType: Domain.AuthType?
    
    init(
        hostId: HostRecord.ID,
        slug: String,
        name: String,
        icon: URL,
        url: URL,
        languages: [LanguageCode],
        pinned: Bool,
        disabled: Bool,
        authType: Domain.AuthType
    ) {
        self.id = nil
        self.hostId = hostId
        self.slug = slug
        self.name = name
        self.icon = icon
        self.url = url
        self.languages = languages
        self.pinned = pinned
        self.disabled = disabled
        self.authType = authType
    }
}

// MARK: - DatabaseRecord

extension SourceRecord {
    static var databaseTableName: String {
        "source"
    }
    
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let hostId = Column(CodingKeys.hostId)
        
        static let slug = Column(CodingKeys.slug)
        static let name = Column(CodingKeys.name)
        static let icon = Column(CodingKeys.icon)
        static let url = Column(CodingKeys.url)
        static let languages = Column(CodingKeys.languages)
        static let pinned = Column(CodingKeys.pinned)
        static let disabled = Column(CodingKeys.disabled)
        
        static let authType = Column(CodingKeys.authType)
    }
    
    static func createTable(db: Database) throws {
        try db.create(table: databaseTableName, options: [.ifNotExists]) { t in
            t.autoIncrementedPrimaryKey(Columns.id.name)
            
            t.belongsTo(HostRecord.databaseTableName, onDelete: .cascade)
            
            t.column(Columns.slug.name, .text).notNull()
            t.column(Columns.name.name, .text).notNull()
            t.column(Columns.icon.name, .text).notNull()
            t.column(Columns.url.name, .text).notNull()
            t.column(Columns.languages.name, .blob).notNull()
                
            t.column(Columns.pinned.name, .boolean).notNull().defaults(to: false)
            t.column(Columns.disabled.name, .boolean).notNull().defaults(to: false)
            
            t.column(Columns.authType.name, .text)
        }
    }
    
    static func migrate(with migrator: inout GRDB.DatabaseMigrator, from version: DatabaseVersion) throws {
        switch version {
        case ..<DatabaseVersion(1, 0, 0):
            let migrationName = DatabaseVersion(1, 0, 0).createMigrationName(description: "source initial indexes")
            migrator.registerMigration(migrationName) { db in
                // foreign key index
                try db.create(index: "idx_source_hostId", on: databaseTableName, columns: [Columns.hostId.name])
                
                // slug index for api lookups
                try db.create(index: "idx_source_slug", on: databaseTableName, columns: [Columns.slug.name])
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

extension SourceRecord {
    static let host = belongsTo(HostRecord.self)
    
    var host: QueryInterfaceRequest<HostRecord> {
        request(for: SourceRecord.host)
    }
}

extension SourceRecord {
    static let origins = hasMany(OriginRecord.self)
    
    var origins: QueryInterfaceRequest<OriginRecord> {
        request(for: SourceRecord.origins)
    }
}

// MARK: - Search Associations

extension SourceRecord {
    static let searchConfig = hasOne(SearchConfigRecord.self)
    static let searchTags = hasMany(SearchTagRecord.self)
    static let searchPresets = hasMany(SearchPresetRecord.self)
    
    var searchConfig: QueryInterfaceRequest<SearchConfigRecord> {
        request(for: SourceRecord.searchConfig)
    }
    
    var searchTags: QueryInterfaceRequest<SearchTagRecord> {
        request(for: SourceRecord.searchTags)
    }
    
    var searchPresets: QueryInterfaceRequest<SearchPresetRecord> {
        request(for: SourceRecord.searchPresets)
    }
}

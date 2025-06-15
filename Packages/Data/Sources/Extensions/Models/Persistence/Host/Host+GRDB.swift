//
//  Host+GRDB.swift
//  Data
//
//  Created by Angelo Carasig on 15/6/2025.
//

import Foundation
import GRDB
import Domain


private typealias Host = Domain.Models.Persistence.Host
private typealias Source = Domain.Models.Persistence.Source

// MARK: - Database Conformance
extension Host: @retroactive FetchableRecord {}

extension Host: @retroactive PersistableRecord {}

extension Host: @retroactive TableRecord {
    public enum Columns {
        public static let id = Column(CodingKeys.id)
        public static let name = Column(CodingKeys.name)
        public static let author = Column(CodingKeys.author)
        public static let repository = Column(CodingKeys.repository)
        public static let baseUrl = Column(CodingKeys.baseUrl)
    }
}

extension Host: @retroactive Data.Infrastructure.DatabaseUnique {
    /// when performing a findOrCreate, uses this to determine whether to find/create the host
    public static func uniqueFilter(for instance: Domain.Models.Persistence.Host) -> QueryInterfaceRequest<Domain.Models.Persistence.Host> {
        filter(Columns.baseUrl == instance.baseUrl)
    }
}

// MARK: - Database Relations
extension Host {
    // has many sources
    public static let sources = hasMany(Domain.Models.Persistence.Source.self)
    var sources: QueryInterfaceRequest<Domain.Models.Persistence.Source> {
        request(for: Domain.Models.Persistence.Host.sources)
    }
}

// MARK: - Database Table Definition + Migrations
extension Host: @retroactive Data.Infrastructure.DatabaseMigratable {
    public static func createTable(db: Database) throws {
        try db.create(table: databaseTableName, body: { t in
            t.autoIncrementedPrimaryKey(Columns.id.name)
            
            t.column(Columns.name.name, .text)
                .notNull()
                .indexed()
                .collate(.nocase)
                .check { length($0) > 0 }
                .check(sql: "name NOT GLOB '*[/?#@!$&''()*+,;=:]*'")
            
            t.column(Columns.author.name, .text)
                .notNull()
                .collate(.nocase)
                .check { length($0) > 0 }
                .check(sql: "author NOT GLOB '*[/?#@!$&''()*+,;=:]*'")
            
            t.column(Columns.repository.name, .text)
                .notNull()
                .collate(.nocase)
                .check { length($0) > 0 }
                .check(sql: "repository LIKE 'http%'") // must start with http
            
            t.column(Columns.baseUrl.name, .text)
                .notNull()
                .collate(.nocase)
                .unique(onConflict: .fail)
                .check { length($0) > 0 }
                .check(sql: "baseUrl LIKE 'http%'")  // must start with http
            
            t.uniqueKey([Columns.repository.name, Columns.baseUrl.name], onConflict: .fail)
        })
    }
    
    public static func migrate(with migrator: inout DatabaseMigrator, from version: Data.Infrastructure.Version) throws {
        // nothing for now
    }
}

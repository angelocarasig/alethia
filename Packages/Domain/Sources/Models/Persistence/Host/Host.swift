//
//  Host.swift
//  Domain
//
//  Created by Angelo Carasig on 14/6/2025.
//

import Foundation
import GRDB

internal typealias Host = Domain.Models.Persistence.Host

public extension Domain.Models.Persistence {
    /// represents a content host provider in the system
    struct Host: Identifiable, Codable {
        // MARK: - Properties
        
        /// unique database identifier
        public var id: Int64?
        
        /// display name of the host provider
        public var name: String
        
        /// creator/maintainer of this host
        public var author: String
        
        /// url to the source code repository
        public var repository: String
        
        /// base url for api requests
        public var baseUrl: String
        
        /// creates a new host with validation
        ///
        /// throwable init for validation with following rules:
        /// - name/author don't contain url-unsafe characters
        /// - url properties are properly formatted
        public init(
            id: Int64? = nil,
            name: String,
            author: String,
            repository: String,
            baseUrl: String
        ) throws {
            self.id = id
            self.name = name.lowercased()
            self.author = author.lowercased()
            self.repository = repository
            self.baseUrl = baseUrl
            
            try validate()
        }
    }
}

// MARK: - Database Conformance
extension Host: FetchableRecord, PersistableRecord {}

extension Host: TableRecord {
    public enum Columns {
        public static let id = Column(CodingKeys.id)
        public static let name = Column(CodingKeys.name)
        public static let author = Column(CodingKeys.author)
        public static let repository = Column(CodingKeys.repository)
        public static let baseUrl = Column(CodingKeys.baseUrl)
    }
}

extension Host: DatabaseUnique {
    /// when performing a findOrCreate, uses this to determine whether to find/create the host
    static func uniqueFilter(for instance: Domain.Models.Persistence.Host) -> GRDB.QueryInterfaceRequest<Domain.Models.Persistence.Host> {
        filter(Columns.baseUrl == instance.baseUrl)
    }
}

// MARK: - Database Relations
extension Host {
    // has many sources
    static let sources = hasMany(Domain.Models.Persistence.Source.self)
    var sources: QueryInterfaceRequest<Domain.Models.Persistence.Source> {
        request(for: Domain.Models.Persistence.Host.sources)
    }
}

// MARK: - Database Table Definition + Migrations
extension Host: DatabaseMigratable {
    static func createTable(db: GRDB.Database) throws {
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
    
    static func migrate(with migrator: inout GRDB.DatabaseMigrator, from version: Version) throws {
        // nothing for now
    }
}

// MARK: - Validators
private extension Host {
    static let invalidatingSet = CharacterSet(charactersIn: "/\\?#@!$&'()*+,;=:")
    
    func validate() throws {
        try validateName()
        try validateAuthor()
        try validateRepository()
        try validateBaseUrl()
    }
    
    func validateName() throws {
        try validateRequired(name, parameter: "name")
        try validateCharacters(name, parameter: "name") { error in
            HostError.invalidName(error)
        }
    }
    
    func validateAuthor() throws {
        try validateRequired(author, parameter: "author")
        try validateCharacters(author, parameter: "author") { error in
            HostError.invalidAuthor(error)
        }
    }
    
    func validateRepository() throws {
        try validateRequired(repository, parameter: "repository")
        
        guard let url = URL(string: repository) else {
            throw HostError.invalidRepository(URL(string: "invalid://")!, reason: "Invalid URL format")
        }
        
        guard url.scheme != nil else {
            throw HostError.invalidRepository(url, reason: "Missing URL scheme")
        }
        
        guard url.host != nil else {
            throw HostError.invalidRepository(url, reason: "Missing host domain")
        }
    }
    
    func validateBaseUrl() throws {
        try validateRequired(baseUrl, parameter: "baseUrl")
        
        guard let url = URL(string: baseUrl) else {
            throw HostError.invalidURL(URL(string: "invalid://")!, reason: "Invalid URL format")
        }
        
        guard let scheme = url.scheme, ["http", "https"].contains(scheme) else {
            throw HostError.invalidURL(url, reason: "Must use http or https")
        }
        
        guard url.host != nil else {
            throw HostError.invalidURL(url, reason: "Missing host domain")
        }
    }
    
    func validateRequired(_ value: String, parameter: String) throws {
        guard !value.isEmpty else {
            throw HostError.emptyValue("", parameter: parameter)
        }
    }
    
    func validateCharacters(_ value: String, parameter: String, errorBuilder: (String) -> HostError) throws {
        if value.rangeOfCharacter(from: Self.invalidatingSet) != nil {
            throw errorBuilder(value)
        }
    }
}

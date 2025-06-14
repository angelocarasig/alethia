//
//  Collection.swift
//  Domain
//
//  Created by Angelo Carasig on 14/6/2025.
//

import Foundation
import GRDB

internal typealias Collection = Domain.Models.Persistence.Collection

public extension Domain.Models.Persistence {
    /// acts as a way to group manga with some extra metadata (mainly visual)
    struct Collection: Identifiable, Equatable, Codable {
        // MARK: - Properties
        
        public static let minimumNameLength = 3
        public static let maximumNameLength = 20
        
        /// unique database identifier
        public var id: Int64?
        
        /// name of the collection
        public var name: String
        
        /// hex color string (e.g., "#FF0000")
        public var color: String
        
        /// sf symbol icon
        public var icon: String
        
        /// display ordering for collections
        public var ordering: Int = 0
        
        /// creates a new collection with validation
        ///
        /// throwable init for validation with following rules:
        /// - name must be within length constraints
        /// - color must be valid hex format
        /// - icon must not be empty
        public init(
            id: Int64? = nil,
            name: String,
            color: String,
            icon: String,
            ordering: Int = 0
        ) throws {
            self.id = id
            self.name = name
            self.color = color
            self.icon = icon
            self.ordering = ordering
            
            try validate()
        }
    }
}

// MARK: - Database Conformance
extension Collection: FetchableRecord, PersistableRecord {}

extension Collection: TableRecord {
    public enum Columns {
        public static let id = Column(CodingKeys.id)
        public static let name = Column(CodingKeys.name)
        public static let color = Column(CodingKeys.color)
        public static let icon = Column(CodingKeys.icon)
        public static let ordering = Column(CodingKeys.ordering)
    }
}

extension Collection: DatabaseUnique {
    /// when performing a findOrCreate, uses this to determine whether to find/create the collection
    static func uniqueFilter(for instance: Domain.Models.Persistence.Collection) -> QueryInterfaceRequest<Domain.Models.Persistence.Collection> {
        filter(Columns.name == instance.name)
    }
}

// MARK: - Database Relations
extension Collection {
    // has many manga <-> manga has many collections
    static let mangaCollections = hasMany(Domain.Models.Persistence.MangaCollection.self)
    static let manga = hasMany(Domain.Models.Persistence.Manga.self, through: mangaCollections, using: Domain.Models.Persistence.MangaCollection.manga)
}

// MARK: - Database Table Definition + Migrations
extension Collection: DatabaseMigratable {
    static func createTable(db: Database) throws {
        try db.create(table: databaseTableName, body: { t in
            // ids
            t.autoIncrementedPrimaryKey(Columns.id.name)
            
            // properties
            t.column(Columns.name.name, .text)
                .notNull()
                .unique()
                .collate(.nocase)
                .check { length($0) >= Collection.minimumNameLength && length($0) <= Collection.maximumNameLength }
            
            t.column(Columns.color.name, .text)
                .notNull()
                .defaults(to: "#007AFF") // iOS blue
                .check(sql: "color GLOB '#[0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f]'")
            
            t.column(Columns.icon.name, .text)
                .notNull()
                .defaults(to: "square.inset.filled")
                .check { length($0) > 0 }
            
            // control
            t.column(Columns.ordering.name, .integer)
                .notNull()
                .unique()
                .defaults(to: 0)
        })
    }
    
    static func migrate(with migrator: inout DatabaseMigrator, from version: Version) throws {
        // nothing for now
    }
}

// MARK: - Validators
extension Collection {
    static let hexColorPattern = "^#[0-9A-Fa-f]{6}$"
    
    func validate() throws {
        try validateName()
        try validateColor()
        try validateIcon()
    }
    
    func validateName() throws {
        try validateRequired(name, parameter: "name")
        
        guard name.count >= Self.minimumNameLength else {
            throw CollectionError.minimumLengthNotReached(name.count)
        }
        
        guard name.count <= Self.maximumNameLength else {
            throw CollectionError.maximumLengthReached(name.count)
        }
        
        // check for reserved names if needed
        let reservedNames = ["all", "default", "new", "none"]
        if reservedNames.contains(name.lowercased()) {
            throw CollectionError.badName(name)
        }
    }
    
    func validateColor() throws {
        try validateRequired(color, parameter: "color")
        
        // validate hex color format
        let colorRegex = try NSRegularExpression(pattern: Self.hexColorPattern)
        let range = NSRange(location: 0, length: color.utf16.count)
        
        guard colorRegex.firstMatch(in: color, options: [], range: range) != nil else {
            throw CollectionError.invalidColor(color, reason: "Must be hex format (#RRGGBB)")
        }
    }
    
    func validateIcon() throws {
        try validateRequired(icon, parameter: "icon")
    }
    
    func validateRequired(_ value: String, parameter: String) throws {
        guard !value.isEmpty else {
            throw CollectionError.emptyValue("", parameter: parameter)
        }
    }
}

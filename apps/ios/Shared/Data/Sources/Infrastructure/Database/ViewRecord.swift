//
//  ViewRecord.swift
//  Data
//
//  Created by Angelo Carasig on 11/10/2025.
//

import GRDB

internal protocol ViewRecord: Codable, FetchableRecord, TableRecord {
    /// The database view name
    static var databaseTableName: String { get }
    
    /// The SQL request that defines the view
    static var viewDefinition: SQLRequest<Self> { get }
    
    /// tables this view depends on - used to determine when to rebuild
    static var dependsOn: [any DatabaseRecord.Type] { get }
    
    /// version when this view was introduced
    static var introducedIn: DatabaseVersion { get }
    
    /// Creates the view in the database
    static func createView(db: Database) throws
    
    /// Rebuilds the view (drop + recreate) when dependencies change
    static func rebuild(db: Database) throws
    
    /// Migrates view definition if needed based on version
    static func migrate(with migrator: inout DatabaseMigrator, from version: DatabaseVersion) throws
}

// MARK: - Default Implementations

extension ViewRecord {
    static func createView(db: Database) throws {
        try db.create(view: databaseTableName, options: [.ifNotExists], as: viewDefinition)
    }
    
    static func rebuild(db: Database) throws {
        // drop the existing view if it exists
        if try exists(in: db) {
            try db.drop(view: databaseTableName)
        }
        // recreate with potentially updated definition
        try db.create(view: databaseTableName, as: viewDefinition)
    }
    
    static func migrate(with migrator: inout DatabaseMigrator, from version: DatabaseVersion) throws {
        // default implementation - views can override if they need version-specific migrations
        // most views will just rebuild when their dependencies change
    }
}

// MARK: - View Management Extensions

extension ViewRecord {
    /// checks if view exists in database
    static func exists(in db: Database) throws -> Bool {
        try db.tableExists(databaseTableName)
    }
    
    /// drops the view if it exists
    static func drop(db: Database) throws {
        if try exists(in: db) {
            try db.drop(view: databaseTableName)
        }
    }
    
    static func validateDependencies(in db: Database) throws -> Bool {
        try dependsOn.allSatisfy { dependency in
            try db.tableExists(dependency.databaseTableName)
        }
    }
}

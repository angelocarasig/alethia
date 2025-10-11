//
//  DatabaseRecord.swift
//  Data
//
//  Created by Angelo Carasig on 11/10/2025.
//

import GRDB
import Tagged

internal protocol DatabaseRecord: FetchableRecord, MutablePersistableRecord, TableRecord {
    associatedtype ID = Tagged<Self, Int64>
    
    /// primary key for the record
    var id: ID? { get }
    
    /// The database table name for this record
    static var databaseTableName: String { get }
    
    /// Creates the initial table schema
    static func createTable(db: Database) throws
    
    /// Applies migrations based on version
    static func migrate(with migrator: inout GRDB.DatabaseMigrator, from version: DatabaseVersion) throws
}

// MARK: - Helper Extensions

extension DatabaseRecord {
    /// checks if table exists in database
    static func exists(in db: Database) throws -> Bool {
        try db.tableExists(databaseTableName)
    }
    
    /// drops the table if it exists
    static func drop(db: Database) throws {
        if try exists(in: db) {
            try db.drop(table: databaseTableName)
        }
    }
}

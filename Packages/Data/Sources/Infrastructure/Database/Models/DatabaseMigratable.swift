//
//  DatabaseMigratable.swift
//  Data
//
//  Created by Angelo Carasig on 14/6/2025.
//

import GRDB
import Domain

public extension Data.Infrastructure {
    /// Protocol for models that can create and migrate their database schema.
    ///
    /// Separates table creation (initial schema) from migrations (schema updates).
    protocol DatabaseMigratable {
        
        /// Creates the initial table schema.
        ///
        /// Called once when the table doesn't exist yet.
        /// Define columns, indexes, and constraints here.
        static func createTable(db: Database) throws -> Void
        
        /// Applies migrations based on the current version.
        static func migrate(with migrator: inout DatabaseMigrator, from version: Version) throws -> Void
    }
}

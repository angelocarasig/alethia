//
//  DatabaseUnique.swift
//  Data
//
//  Created by Angelo Carasig on 14/6/2025.
//

import GRDB
import Domain

public extension Data.Infrastructure {
    /// Provides find-or-create pattern for unique records.
    ///
    /// Returns existing records instead of throwing unique constraint errors.
    /// Works alongside DB unique constraints - DB ensures data integrity,
    /// this handles it gracefully in code (one query vs insert-fail-query).
    protocol DatabaseUnique: PersistableRecord & FetchableRecord {
        
        /// Defines what makes this record unique (should match DB unique constraints).
        ///
        /// Example: `filter(Column("name") == instance.name)`
        static func uniqueFilter(for instance: Self) -> QueryInterfaceRequest<Self>
    }
}

public extension Data.Infrastructure.DatabaseUnique {
    /// Returns existing record if found, otherwise creates and returns new one.
    static func findOrCreate(_ db: Database, instance: Self) throws -> Self {
        if let existing = try uniqueFilter(for: instance).fetchOne(db) {
            return existing
        } else {
            return try instance.insertAndFetch(db)
        }
    }
}

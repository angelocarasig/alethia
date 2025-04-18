//
//  DatabaseUnique.swift
//  Alethia
//
//  Created by Angelo Carasig on 10/4/2025.
//

import Foundation
import GRDB

protocol DatabaseUnique: PersistableRecord & FetchableRecord {
    static func uniqueFilter(for instance: Self) -> QueryInterfaceRequest<Self>
}

extension DatabaseUnique {
    static func findOrCreate(_ db: Database, instance: Self) throws -> Self {
        if let existing = try uniqueFilter(for: instance).fetchOne(db) {
            return existing
        } else {
            return try instance.insertAndFetch(db)
        }
    }
}

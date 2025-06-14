//
//  Misc+Indexes.swift
//  Domain
//
//  Created by Angelo Carasig on 15/6/2025.
//

import GRDB

internal typealias Indexes = Domain.Models.Persistence.Misc.Indexes

public extension Domain.Models.Persistence.Misc {
    struct Indexes {}
}

extension Indexes: Domain.Models.Database.DatabaseMigratable {
    public static func createTable(db: Database) throws {
        // TODO
        // try db.create(index: )
    }
    
    public static func migrate(with migrator: inout DatabaseMigrator, from version: Domain.Models.Database.Version) throws {
        // nothing for now
    }
}

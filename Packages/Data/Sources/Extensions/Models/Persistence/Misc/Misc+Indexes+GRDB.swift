//
//  Misc+Indexes+GRDB.swift
//  Data
//
//  Created by Claude on 15/6/2025.
//

import Foundation
import GRDB
import Domain


private typealias Misc = Domain.Models.Persistence.Misc

// MARK: - Database Table Definition + Migrations
extension Misc.Indexes: @retroactive Data.Infrastructure.DatabaseMigratable {
    public static func createTable(db: Database) throws {
        // TODO
        // try db.create(index: )
    }
    
    public static func migrate(with migrator: inout DatabaseMigrator, from version: Data.Infrastructure.Version) throws {
        // nothing for now
    }
}

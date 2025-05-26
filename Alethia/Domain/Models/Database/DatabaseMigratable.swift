//
//  DatabaseMigratable.swift
//  Alethia
//
//  Created by Angelo Carasig on 9/4/2025.
//

import Foundation
import GRDB

protocol DatabaseMigratable {
    static func createTable(db: Database) throws -> Void
    static func migrate(with migrator: inout DatabaseMigrator, from version: Version) throws -> Void
}

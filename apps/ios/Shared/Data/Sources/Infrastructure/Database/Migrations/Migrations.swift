//
//  Migrations.swift
//  Data
//
//  Created by Angelo Carasig on 2/10/2025.
//

import GRDB

internal enum Migrations {}

internal protocol Migration {
    static var identifier: String { get }
    static func migrate(_ db: GRDB.Database) throws
}

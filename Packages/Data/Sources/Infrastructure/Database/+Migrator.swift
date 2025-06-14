//
//  +Migrator.swift
//  Data
//
//  Created by Angelo Carasig on 14/6/2025.
//

import Domain
import GRDB

extension DatabaseProvider {
    var migrator: DatabaseMigrator {
        do {
            var migrator = DatabaseMigrator()
            
            // defined here because not sendable inside migration closure
            let models = self.models
            
            #if DEBUG
            // migrator.eraseDatabaseOnSchemaChange = true
            #endif
            
            // MARK: - Create tables
            migrator.registerMigration(version.createMigrationName(description: "initial")) { db in
                for model in models {
                    try model.createTable(db: db)
                }
            }
            
            // MARK: - Perform Migrations
            for model in models {
                try model.migrate(with: &migrator, from: self.version)
            }
            
            return migrator
        }
        catch {
            fatalError(Database.DatabaseError.migrationFailure(error).localizedDescription)
        }
    }
}

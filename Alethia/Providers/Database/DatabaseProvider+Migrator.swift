//
//  DatabaseProvider+Migrator.swift
//  Alethia
//
//  Created by Angelo Carasig on 9/4/2025.
//

import Foundation
import GRDB

extension DatabaseProvider {
    var migrator: DatabaseMigrator {
        do {
            var migrator = DatabaseMigrator()
            
            #if DEBUG
//            migrator.eraseDatabaseOnSchemaChange = true
            #endif
            
            migrator.registerMigration("initial") { db in
                for model in self.models {
                    try model.createTable(db: db)
                }
            }
            
            for model in models {
                try model.migrate(with: &migrator, from: self.version)
            }
            
            migrator.registerMigration("create_views_v1") { db in
                try self.makeViews(db: db)
            }
            
            return migrator
        }
        catch {
            fatalError(DatabaseError.migratorSetupFailed(error).localizedDescription)
        }
    }
}

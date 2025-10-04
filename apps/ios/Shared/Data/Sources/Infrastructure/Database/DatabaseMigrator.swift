//
//  DatabaseMigrator.swift
//  Data
//
//  Created by Angelo Carasig on 28/9/2025.
//

import Foundation
import GRDB

public struct DatabaseMigrator {
    
    public init() {}
    
    public func migrate(_ writer: DatabaseWriter) throws {
        var migrator = GRDB.DatabaseMigrator()
        
        #if DEBUG
        // helps catch schema inconsistencies during development
        migrator.eraseDatabaseOnSchemaChange = true
        #endif
        
        // register all migrations in chronological order
        // format: YYYYMMDD_HHMMSS_description for clear ordering
        
        migrator.registerMigration("20240927_000000_initial_schema") { db in
            try Migrations.InitialSchema.migrate(db)
        }
        
        // future migrations would be added here
        // migrator.registerMigration("20241015_143000_add_download_support") { db in
        //     try Migrations.Migration20241015_143000_AddDownloadSupport.migrate(db)
        // }
        
        // migrator.registerMigration("20241102_090000_add_reading_history") { db in
        //     try Migrations.Migration20241102_090000_AddReadingHistory.migrate(db)
        // }
        
        // migrator.registerMigration("20241215_120000_add_sync_support") { db in
        //     try Migrations.Migration20241215_120000_AddSyncSupport.migrate(db)
        // }
        
        try migrator.migrate(writer)
    }
}

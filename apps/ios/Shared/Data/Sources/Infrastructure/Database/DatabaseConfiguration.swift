//
//  DatabaseConfiguration.swift
//  Data
//
//  Created by Angelo Carasig on 28/9/2025.
//

import Foundation
import GRDB
import Core

public final class DatabaseConfiguration: @unchecked Sendable {
    public let writer: DatabaseWriter
    public let reader: DatabaseReader
    
    // current database version
    internal static let currentVersion = DatabaseVersion(1, 0, 0)
    
    // all database records in dependency order
    internal static let allRecords: [any DatabaseRecord.Type] = [
        // independent tables
        HostRecord.self,
        AuthorRecord.self,
        TagRecord.self,
        CollectionRecord.self,
        ScanlatorRecord.self,
        
        // dependent on host
        SourceRecord.self,
        
        // dependent on source
        SearchConfigRecord.self,
        SearchPresetRecord.self,
        SearchTagRecord.self,
        
        // core manga tables
        MangaRecord.self,
        
        // dependent on manga
        AlternativeTitleRecord.self,
        CoverRecord.self,
        
        // dependent on manga and source
        OriginRecord.self,
        
        // dependent on origin and scanlator
        OriginScanlatorPriorityRecord.self,
        ChapterRecord.self,
        
        // junction tables
        MangaAuthorRecord.self,
        MangaTagRecord.self,
        MangaCollectionRecord.self
    ]
    
    // all views in dependency order
    internal static let allViews: [any ViewRecord.Type] = [
        BestChapterView.self,
        EntryView.self,
        MangaTitleFTS5.self,
        MangaAltTitleFTS5.self
    ]
    
    static var configuration: Configuration {
        var config = Configuration()
        
        config.readonly = false
        config.maximumReaderCount = 5
        config.allowsUnsafeTransactions = false
        config.publicStatementArguments = false
        config.busyMode = .timeout(3)
        config.automaticMemoryManagement = true
        config.journalMode = .wal
        config.label = "alethia.database"
        config.observesSuspensionNotifications = true
        config.foreignKeysEnabled = true
        
        #if DEBUG
        config.publicStatementArguments = true
        config.prepareDatabase { db in
            db.trace { print($0) }
        }
        #endif
        
        return config
    }
    
    public static let shared: DatabaseConfiguration = {
        do {
            return try DatabaseConfiguration()
        } catch {
            fatalError("Failed to initialize database: \(error)")
        }
    }()
    
    public static let preview: DatabaseConfiguration = {
        do {
            return try DatabaseConfiguration(inMemory: true)
        } catch {
            fatalError("Failed to initialize preview database: \(error)")
        }
    }()
    
    public init(inMemory: Bool = false) throws {
        if inMemory {
            var config = Self.configuration
            config.label = "alethia.database.preview"
            writer = try DatabaseQueue(configuration: config)
        } else {
            let url = Core.Constants.Paths.database
            
            let directory = url.deletingLastPathComponent()
            try FileManager.default.createDirectory(
                at: directory,
                withIntermediateDirectories: true
            )
            
            writer = try DatabasePool(path: url.path, configuration: Self.configuration)
        }
        
        reader = writer
        
        // build and apply migrations
        let migrator = buildMigrator()
        try migrator.migrate(writer)
    }
    
    private func buildMigrator() -> GRDB.DatabaseMigrator {
        var migrator = GRDB.DatabaseMigrator()
        
        #if DEBUG
        // helps catch schema inconsistencies during development
        migrator.eraseDatabaseOnSchemaChange = true
        #endif
        
        // capture for use in migration closures
        let records = Self.allRecords
        let views = Self.allViews
        let currentVersion = Self.currentVersion
        
        // initial schema creation
        let initialVersion = DatabaseVersion(1, 0, 0)
        let migrationName = initialVersion.createMigrationName(description: "initial schema")
        
        migrator.registerMigration(migrationName) { db in
            // create all tables in dependency order
            for record in records {
                try record.createTable(db: db)
            }
            
            // create all views introduced in v1.0.0
            for view in views where view.introducedIn <= initialVersion {
                try view.createView(db: db)
            }
        }
        
        // register migrations from each record and view
        for record in records {
            do {
                try record.migrate(with: &migrator, from: DatabaseVersion(0, 0, 0))
            } catch {
                print("Failed to migrate \(record): \(error)")
            }
        }
        
        for view in views where view.introducedIn <= currentVersion {
            do {
                try view.migrate(with: &migrator, from: DatabaseVersion(0, 0, 0))
            } catch {
                print("Failed to migrate \(view): \(error)")
            }
        }
        
        return migrator
    }
}

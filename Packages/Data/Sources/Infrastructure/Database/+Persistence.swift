//
//  DatabaseProvider+Persistence.swift
//  Data
//
//  Created by Angelo Carasig on 15/6/2025.
//

import Core
import GRDB

extension Data.Infrastructure.DatabaseProvider {
    public static let shared = makeShared()
    
    static var configuration: Configuration {
        var config = Configuration()
        
        /// Enables read-write access to the database.
        config.readonly = false
        
        /// Maximum number of concurrent reader connections allowed.
        config.maximumReaderCount = 5
        
        /// Prevents unsafe transaction modes that can cause database corruption.
        config.allowsUnsafeTransactions = false
        
        /// Hides SQL statement arguments in logs for security.
        config.publicStatementArguments = false
        
        /// Defines behavior when database is locked by another connection.
        /// - Parameter timeout: Wait up to 3 seconds before throwing a database busy error.
        /// - Note: Prevents immediate failures during concurrent access.
        config.busyMode = .timeout(3)
        
        /// Enables SQLite's automatic memory management for better performance.
        /// - Note: Allows SQLite to automatically shrink its memory usage when needed.
        config.automaticMemoryManagement = true
        
        /// Uses Write-Ahead Logging for better concurrent access performance.
        /// - Important: WAL mode allows readers to not block writers and vice versa.
        /// - Note: Creates additional `-wal` and `-shm` files alongside the database.
        config.journalMode = .wal
        
        /// Identifies this database connection in logs and debugging tools.
        /// - Note: Helps distinguish between multiple database connections in the same app.
        config.label = Core.Constants.Database.label
        
        /// Observes iOS app suspension notifications to properly handle database state.
        /// - Important: Required for proper database behavior during app backgrounding.
        /// - SeeAlso: [GRDB Issue #998](https://github.com/groue/GRDB.swift/issues/998)
        config.observesSuspensionNotifications = true
        
        /// Enforces referential integrity through foreign key constraints.
        /// - Warning: Must be enabled before any database operations to take effect.
        /// - Note: Prevents orphaned records and maintains data consistency.
        config.foreignKeysEnabled = true
        
        #if DEBUG
        config.publicStatementArguments = true
        
        config.prepareDatabase { db in
            db.trace { print($0) }
        }
        #endif
        
        return config
    }
    
    private static func makeShared() -> Data.Infrastructure.DatabaseProvider {
        do {
            let path = Core.Constants.Database.filePath
            let writer = try DatabasePool(path: path, configuration: configuration)
            let database = try Data.Infrastructure.DatabaseProvider(writer)
            
            return database
        }
        catch {
            fatalError(Data.Infrastructure.DatabaseError.initializationFailed(error).localizedDescription)
        }
    }
}


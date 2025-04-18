//
//  DatabaseProvider+Persistence.swift
//  Alethia
//
//  Created by Angelo Carasig on 10/4/2025.
//

import Foundation
import GRDB

extension DatabaseProvider {
    static let shared = makeShared()
    
    static var configuration: Configuration {
        var config = Configuration()
        
        config.maximumReaderCount = 10
        config.allowsUnsafeTransactions = false
        config.busyMode = .timeout(5)
        config.label = "com.alethia.database"
        config.prepareDatabase { db in
            try db.execute(sql: "PRAGMA foreign_keys = ON")
        }
        
        return config
    }
    
    private static func makeShared() -> DatabaseProvider {
        do {
            // MARK: Database Path
            let fileManager = FileManager()
            
            let dbFolderURL = try fileManager.url(
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            ).appendingPathComponent("Database", isDirectory: true)

            try fileManager.createDirectory(at: dbFolderURL, withIntermediateDirectories: true)

            let dbPath = dbFolderURL.appendingPathComponent("alethia.db").path
            let writer = try DatabasePool(path: dbPath, configuration: configuration)
            let database = try DatabaseProvider(writer)
            
            return database
        }
        catch {
            fatalError("Error initializing database: \(error)")
        }
    }
}

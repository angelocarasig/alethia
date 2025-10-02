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
            writer = try DatabaseQueue()
        } else {
            let url = Core.Constants.Paths.database
            
            let directory = url.deletingLastPathComponent()
            try FileManager.default.createDirectory(
                at: directory,
                withIntermediateDirectories: true
            )
            
            var config = Configuration()
            config.maximumReaderCount = 5
            
            #if DEBUG
            config.prepareDatabase { db in
                db.trace { print("SQL: \($0)") }
            }
            #endif
            
            writer = try DatabasePool(path: url.path, configuration: config)
        }
        
        reader = writer
        
        let migrator = DatabaseMigrator()
        try migrator.migrate(writer)
    }
}

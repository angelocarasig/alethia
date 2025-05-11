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
        config.label = Constants.Database.Label
        config.prepareDatabase { db in
            try db.execute(sql: "PRAGMA foreign_keys = ON")
            
            // for logs
            //  db.trace { print($0) }
        }
        
        return config
    }
    
    private static func makeShared() -> DatabaseProvider {
        do {
            let path = Constants.Database.FilePath
            let writer = try DatabasePool(path: path, configuration: configuration)
            let database = try DatabaseProvider(writer)
            
            return database
        }
        catch {
            fatalError("Error initializing database: \(error)")
        }
    }
}

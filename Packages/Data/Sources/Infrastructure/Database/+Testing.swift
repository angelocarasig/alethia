//
//  DatabaseProvider+Testing.swift
//  Data
//
//  Created by Angelo Carasig on 15/6/2025.
//

import GRDB

#if canImport(Testing)
import Testing

extension Data.Infrastructure.DatabaseProvider {
    /// Creates a test-specific database provider with in-memory storage.
    ///
    /// This provider is isolated from the main app database and uses
    /// in-memory storage for isolated tests.
    public static func makeTest() -> Data.Infrastructure.DatabaseProvider {
        do {
            // use in-memory database for tests
            let writer = try DatabaseQueue()
            
            // create provider with test configuration
            let provider = try Data.Infrastructure.DatabaseProvider(writer)
            
            return provider
        } catch {
            fatalError("Failed to create test database: \(error)")
        }
    }
}
#endif

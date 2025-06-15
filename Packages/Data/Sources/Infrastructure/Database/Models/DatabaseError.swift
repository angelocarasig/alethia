//
//  DatabaseError.swift
//  Data
//
//  Created by Angelo Carasig on 14/6/2025.
//

import Foundation
import Domain

public extension Data.Infrastructure {
    enum DatabaseError: LocalizedError {
        case migrationFailure(Error)
        case initializationFailed(Error)
        
        public var errorDescription: String? {
            switch self {
            case .migrationFailure(let error):
                return "Failed performing database migration: \(error.localizedDescription)"
            case .initializationFailed(let error):
                return "Failed initializing database: \(error.localizedDescription)"
            }
        }
    }
}

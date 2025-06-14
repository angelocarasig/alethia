//
//  DatabaseError.swift
//  Domain
//
//  Created by Angelo Carasig on 14/6/2025.
//

import Foundation

public extension Domain.Models.Database {
    enum DatabaseError: LocalizedError {
        case migrationFailure(Error)
        
        public var errorDescription: String? {
            switch self {
            case .migrationFailure(let error):
                return "Failed performing database migration: \(error.localizedDescription)"
            }
        }
    }
}

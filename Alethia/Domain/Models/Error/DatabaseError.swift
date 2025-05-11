//
//  DatabaseError.swift
//  Alethia
//
//  Created by Angelo Carasig on 11/5/2025.
//

import Foundation

enum DatabaseError: LocalizedError {
    case internalError(String)
    case migratorSetupFailed(Error)
    case initializationFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .internalError(let message):
            return message
        case .migratorSetupFailed(let error):
            return "Failed to setup migrator: \(error.localizedDescription)"
        case .initializationFailed(let error):
            return "Failed to initialize database: \(error.localizedDescription)"
        }
    }
}

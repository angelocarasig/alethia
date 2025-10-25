//
//  StorageError.swift
//  Data
//
//  Created by Angelo Carasig on 18/10/2025.
//

import Foundation
import Domain
import GRDB

/// Internal storage-specific errors that are mapped to DataAccessError at repository boundaries
internal enum StorageError: LocalizedError {
    case databaseLocked
    case databaseCorrupted(details: String)
    case diskFull
    case permissionDenied(path: String)
    case migrationFailed(version: String, error: Error)
    case transactionFailed(reason: String)
    case constraintViolation(constraint: String)
    case queryFailed(sql: String, error: Error)
    case recordNotFound(table: String, id: String)
    case invalidState(description: String)
    case invalidCast(expected: String, actual: String)
    
    var errorDescription: String? {
        switch self {
        case .databaseLocked:
            return "Database is locked by another process"
            
        case .databaseCorrupted(let details):
            return "Database is corrupted: \(details)"
            
        case .diskFull:
            return "Insufficient storage space"
            
        case .permissionDenied(let path):
            return "Permission denied for path: \(path)"
            
        case .migrationFailed(let version, let error):
            return "Database migration to version \(version) failed: \(error.localizedDescription)"
            
        case .transactionFailed(let reason):
            return "Database transaction failed: \(reason)"
            
        case .constraintViolation(let constraint):
            return "Database constraint violated: \(constraint)"
            
        case .queryFailed(_, let error):
            return "Database query failed: \(error.localizedDescription)"
            
        case .recordNotFound(let table, let id):
            return "Record not found in \(table) with id: \(id)"
            
        case .invalidState(let description):
            return "Invalid state: \(description)"
            
        case .invalidCast(let expected, let actual):
            return "Type casting failed: expected \(expected), got \(actual)"
        }
    }
    
    /// Maps internal storage error to public domain error
    func toDomainError() -> DataAccessError {
        switch self {
        case .databaseLocked:
            return .storageFailure(reason: "Database is temporarily locked", underlying: self)
            
        case .databaseCorrupted(let details):
            return .dataCorruption(details: details)
            
        case .diskFull:
            return .storageFailure(reason: "Insufficient storage space", underlying: self)
            
        case .permissionDenied(let path):
            return .storageFailure(reason: "Permission denied: \(path)", underlying: self)
            
        case .migrationFailed(let version, let error):
            return .storageFailure(reason: "Migration to version \(version) failed", underlying: error)
            
        case .transactionFailed(let reason):
            return .storageFailure(reason: "Transaction failed: \(reason)", underlying: self)
            
        case .constraintViolation(let constraint):
            return .storageFailure(reason: "Constraint violation: \(constraint)", underlying: self)
            
        case .queryFailed(_, let error):
            return .storageFailure(reason: "Query failed", underlying: error)
            
        case .recordNotFound(let table, let id):
            return .storageFailure(reason: "Record not found in \(table): \(id)", underlying: self)
            
        case .invalidState(let description):
            return .storageFailure(reason: description, underlying: self)
            
        case .invalidCast(let expected, let actual):
            return .storageFailure(reason: "Type mismatch: expected \(expected), got \(actual)", underlying: self)
        }
    }
    
    /// Creates storage error from GRDB error
    static func from(grdbError error: Error, context: String? = nil) -> StorageError {
        if let dbError = error as? DatabaseError {
            switch dbError.resultCode {
            case .SQLITE_CONSTRAINT:
                return .constraintViolation(constraint: dbError.message ?? "unknown")
            case .SQLITE_LOCKED, .SQLITE_BUSY:
                return .databaseLocked
            case .SQLITE_CORRUPT, .SQLITE_NOTADB:
                return .databaseCorrupted(details: dbError.message ?? "unknown")
            case .SQLITE_FULL:
                return .diskFull
            case .SQLITE_PERM, .SQLITE_READONLY:
                return .permissionDenied(path: context ?? "unknown")
            default:
                return .queryFailed(sql: context ?? "unknown", error: error)
            }
        }
        
        return .queryFailed(sql: context ?? "unknown", error: error)
    }
}

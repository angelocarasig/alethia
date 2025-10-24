//
//  DomainError.swift
//  Domain
//
//  Created by Angelo Carasig on 18/10/2025.
//

import Foundation

/// base protocol for all domain-level errors
/// errors conforming to this are safe to expose to the presentation layer
public protocol DomainError: LocalizedError {
    /// indicates if the operation can be retried
    var isRecoverable: Bool { get }
    
    /// categorizes the error for logging and analytics
    var category: ErrorCategory { get }
    
    /// developer-facing debug information
    var debugDescription: String { get }
}

public enum ErrorCategory: String, Sendable {
    case business   // violates business rules, user action needed
    case network    // connectivity or api issues
    case storage    // database or filesystem issues
    case system     // unexpected state, likely a code bug
}

// MARK: - Default Implementations

extension DomainError {
    public var debugDescription: String {
        errorDescription ?? "Unknown error"
    }
    
    /// default recovery suggestion based on category
    public var recoverySuggestion: String? {
        switch category {
        case .business:
            return nil // specific errors should provide their own
        case .network:
            return "An error occurred while connecting to the server. Try again later."
        case .storage:
            return "Something went wrong while storing data. Please try again."
        case .system:
            return "An unexpected error occurred in the system. Please try again later."
        }
    }
}

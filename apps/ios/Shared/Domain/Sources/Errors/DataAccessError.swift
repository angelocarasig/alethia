//
//  DataAccessError.swift
//  Domain
//
//  Created by Angelo Carasig on 18/10/2025.
//

import Foundation

/// errors related to data access operations (network, storage, etc.)
/// these represent infrastructure failures rather than business rule violations
public enum DataAccessError: DomainError {
    case networkFailure(reason: String, underlying: Error?)
    case storageFailure(reason: String, underlying: Error?)
    case dataCorruption(details: String)
    case unavailable(service: String)
    case timeout(operation: String)
    case invalidResponse(statusCode: Int?)
    case cancelled  // add explicit cancellation case
    
    // MARK: - DomainError Conformance
    
    public var isRecoverable: Bool {
        switch self {
        case .networkFailure, .unavailable, .timeout, .invalidResponse, .cancelled:
            return true // transient failures, retry may succeed
        case .storageFailure, .dataCorruption:
            return false // likely requires intervention
        }
    }
    
    public var category: ErrorCategory {
        switch self {
        case .networkFailure, .unavailable, .timeout, .invalidResponse, .cancelled:
            return .network
        case .storageFailure, .dataCorruption:
            return .storage
        }
    }
    
    public var debugDescription: String {
        switch self {
        case .networkFailure(let reason, let error):
            if let error = error {
                return "Network failure: \(reason) - \(error.localizedDescription)"
            }
            return "Network failure: \(reason)"
        case .storageFailure(let reason, let error):
            if let error = error {
                return "Storage failure: \(reason) - \(error.localizedDescription)"
            }
            return "Storage failure: \(reason)"
        case .dataCorruption(let details):
            return "Data corruption: \(details)"
        case .unavailable(let service):
            return "Service unavailable: \(service)"
        case .timeout(let operation):
            return "Operation timed out: \(operation)"
        case .invalidResponse(let statusCode):
            if let statusCode = statusCode {
                return "Invalid server response: HTTP \(statusCode)"
            }
            return "Invalid server response"
        case .cancelled:
            return "Operation was cancelled"
        }
    }
    
    // MARK: - LocalizedError Conformance
    
    public var errorDescription: String? {
        switch self {
        case .networkFailure(let reason, _):
            return "Network error: \(reason)"
        case .storageFailure(let reason, _):
            return "Storage error: \(reason)"
        case .dataCorruption:
            return "The data appears to be corrupted and cannot be read."
        case .unavailable(let service):
            return "\(service) is currently unavailable."
        case .timeout:
            return "The operation took too long and was cancelled."
        case .invalidResponse(let statusCode):
            if let statusCode = statusCode {
                return "The server returned an invalid response (HTTP \(statusCode))."
            }
            return "The server returned an invalid response."
        case .cancelled:
            return nil  // no error message for cancellation
        }
    }
    
    public var recoverySuggestion: String? {
        switch self {
        case .networkFailure:
            return "Check your internet connection and try again."
        case .storageFailure:
            return "Try restarting the app. If the problem persists, you may need to reinstall."
        case .dataCorruption:
            return "The app data may need to be reset. Contact support for assistance."
        case .unavailable:
            return "The service may be temporarily down. Please try again later."
        case .timeout:
            return "Check your internet connection and try again."
        case .invalidResponse:
            return "The server may be experiencing issues. Please try again later."
        case .cancelled:
            return nil // no suggestion needed for cancellation
        }
    }
    
    public var failureReason: String? {
        switch self {
        case .networkFailure(_, let error), .storageFailure(_, let error):
            return error?.localizedDescription
        default:
            return nil
        }
    }
    
    /// helper to check if this is a cancellation error
    public var isCancellation: Bool {
        switch self {
        case .cancelled:
            return true
        default:
            return false
        }
    }
}

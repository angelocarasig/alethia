//
//  SystemError.swift
//  Domain
//
//  Created by Angelo Carasig on 18/10/2025.
//

import Foundation

/// errors indicating unexpected system state or programming errors
/// these typically represent bugs that need to be fixed in the code
public enum SystemError: DomainError {
    case mappingFailed(reason: String)
    case invalidState(description: String)
    case missingDependency(component: String)
    case unexpectedNil(context: String)
    case notImplemented(feature: String)
    
    // MARK: - DomainError Conformance
    
    public var isRecoverable: Bool {
        false // system errors indicate bugs that need code fixes
    }
    
    public var category: ErrorCategory {
        .system
    }
    
    public var debugDescription: String {
        switch self {
        case .mappingFailed(let reason):
            return "Data mapping failed: \(reason)"
        case .invalidState(let description):
            return "Invalid system state: \(description)"
        case .missingDependency(let component):
            return "Missing required dependency: \(component)"
        case .unexpectedNil(let context):
            return "Unexpected nil value in context: \(context)"
        case .notImplemented(let feature):
            return "Feature not yet implemented: \(feature)"
        }
    }
    
    // MARK: - LocalizedError Conformance
    
    public var errorDescription: String? {
        switch self {
        case .mappingFailed:
            return "An error occurred while processing data."
        case .invalidState:
            return "The application is in an unexpected state."
        case .missingDependency:
            return "A required component is missing."
        case .unexpectedNil:
            return "An unexpected error occurred."
        case .notImplemented:
            return "This feature is not yet available."
        }
    }
    
    public var recoverySuggestion: String? {
        "Please restart the app. If the problem persists, contact support with details about what you were doing."
    }
    
    public var failureReason: String? {
        switch self {
        case .mappingFailed(let reason):
            return "Data mapping failed: \(reason)"
        case .invalidState(let description):
            return description
        case .missingDependency(let component):
            return "The \(component) component is not available"
        case .unexpectedNil(let context):
            return "Required data was missing: \(context)"
        case .notImplemented(let feature):
            return "\(feature) has not been implemented yet"
        }
    }
}

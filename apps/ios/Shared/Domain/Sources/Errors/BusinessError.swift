//
//  BusinessError.swift
//  Domain
//
//  Created by Angelo Carasig on 18/10/2025.
//

import Foundation

/// errors representing business rule violations or expected failure conditions
/// these errors are user-facing and should be handled gracefully by the ui
public enum BusinessError: DomainError {
    case hostAlreadyExists(repository: URL)
    case invalidHostConfiguration(reason: String)
    case noSourcesInHost
    case resourceNotFound(type: String, identifier: String)
    case authenticationRequired(source: String)
    case invalidURLFormat(url: String)
    case operationNotPermitted(reason: String)
    case invalidInput(reason: String)
    
    // MARK: - DomainError Conformance
    
    public var isRecoverable: Bool {
        switch self {
        case .hostAlreadyExists, .invalidHostConfiguration, .noSourcesInHost, .invalidURLFormat, .invalidInput:
            return false // user needs to provide different input
        case .resourceNotFound, .authenticationRequired, .operationNotPermitted:
            return true // might work with different context
        }
    }
    
    public var category: ErrorCategory {
        .business
    }
    
    public var debugDescription: String {
        switch self {
        case .hostAlreadyExists(let url):
            return "Host already exists: \(url.absoluteString)"
        case .invalidHostConfiguration(let reason):
            return "Invalid host configuration: \(reason)"
        case .noSourcesInHost:
            return "Host configuration contains no sources"
        case .resourceNotFound(let type, let id):
            return "\(type) not found with identifier: \(id)"
        case .authenticationRequired(let source):
            return "Authentication required for: \(source)"
        case .invalidURLFormat(let url):
            return "Invalid URL format: \(url)"
        case .operationNotPermitted(let reason):
            return "Operation not permitted: \(reason)"
        case .invalidInput(let reason):
            return "Invalid input: \(reason)"
        }
    }
    
    // MARK: - LocalizedError Conformance
    
    public var errorDescription: String? {
        switch self {
        case .hostAlreadyExists(let url):
            return "A host with repository '\(url.absoluteString)' already exists."
        case .invalidHostConfiguration(let reason):
            return "The host configuration is invalid: \(reason)"
        case .noSourcesInHost:
            return "The host must contain at least one source."
        case .resourceNotFound(let type, _):
            return "\(type) could not be found."
        case .authenticationRequired(let source):
            return "Authentication is required to access \(source)."
        case .invalidURLFormat:
            return "The URL format is invalid. Please check and try again."
        case .operationNotPermitted(let reason):
            return "This operation is not permitted: \(reason)"
        case .invalidInput(let reason):
            return "Invalid input: \(reason)"
        }
    }
    
    public var recoverySuggestion: String? {
        switch self {
        case .hostAlreadyExists:
            return "Use a different host URL or remove the existing host first."
        case .invalidHostConfiguration:
            return "Verify the host URL is correct and the configuration follows the required format."
        case .noSourcesInHost:
            return "Contact the host author to add sources to their configuration."
        case .resourceNotFound:
            return "Verify the resource exists and try again."
        case .authenticationRequired:
            return "Configure authentication in the source settings."
        case .invalidURLFormat:
            return "Ensure the URL starts with http:// or https:// and is properly formatted."
        case .operationNotPermitted:
            return nil
        case .invalidInput:
            return "Please check your input and try again."
        }
    }
}

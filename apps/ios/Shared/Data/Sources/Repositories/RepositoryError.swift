//
//  RepositoryError.swift
//  Data
//
//  Created by Angelo Carasig on 4/10/2025.
//

import Foundation
import Domain

/// consolidated repository error type
/// wraps specific error types and maps them to domain errors at repository boundaries
internal enum RepositoryError: LocalizedError {
    // network-related
    case network(NetworkError)
    
    // storage-related
    case storage(StorageError)
    
    // business logic (these map directly to BusinessError)
    case hostAlreadyExists(id: HostRecord.ID, url: URL)
    case hostNotFound
    case sourceNotFound
    case mangaNotFound
    case invalidConfiguration(reason: String)
    
    // system/mapping errors (these map to SystemError)
    case mappingFailed(reason: String)
    case invalidState(description: String)
    
    var errorDescription: String? {
        switch self {
        case .network(let error):
            return error.errorDescription
            
        case .storage(let error):
            return error.errorDescription
            
        case .hostAlreadyExists(_, let url):
            return "Host with repository '\(url.absoluteString)' already exists"
            
        case .hostNotFound:
            return "Host not found"
            
        case .sourceNotFound:
            return "Source not found"
            
        case .mangaNotFound:
            return "Manga not found"
            
        case .invalidConfiguration(let reason):
            return "Invalid configuration: \(reason)"
            
        case .mappingFailed(let reason):
            return "Data mapping failed: \(reason)"
            
        case .invalidState(let description):
            return "Invalid state: \(description)"
        }
    }
    
    /// maps repository error to appropriate domain error
    func toDomainError() -> DomainError {
        switch self {
        // network errors
        case .network(let error):
            return error.toDomainError()
            
        // storage errors
        case .storage(let error):
            return error.toDomainError()
            
        // business errors
        case .hostAlreadyExists(_, let url):
            return BusinessError.hostAlreadyExists(repository: url)
            
        case .hostNotFound:
            return BusinessError.resourceNotFound(type: "Host", identifier: "unknown")
            
        case .sourceNotFound:
            return BusinessError.resourceNotFound(type: "Source", identifier: "unknown")
            
        case .mangaNotFound:
            return BusinessError.resourceNotFound(type: "Manga", identifier: "unknown")
            
        case .invalidConfiguration(let reason):
            return BusinessError.invalidHostConfiguration(reason: reason)
            
        // system errors
        case .mappingFailed(let reason):
            return SystemError.mappingFailed(reason: reason)
            
        case .invalidState(let description):
            return SystemError.invalidState(description: description)
        }
    }
}

// MARK: - Convenience Constructors

extension RepositoryError {
    static func fromNetwork(_ error: NetworkError) -> RepositoryError {
        .network(error)
    }
    
    static func fromStorage(_ error: StorageError) -> RepositoryError {
        .storage(error)
    }
    
    static func fromGRDB(_ error: Error, context: String? = nil) -> RepositoryError {
        .storage(StorageError.from(grdbError: error, context: context))
    }
}

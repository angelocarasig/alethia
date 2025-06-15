//
//  CollectionError.swift
//  Domain
//
//  Created by Angelo Carasig on 14/6/2025.
//

import Foundation

public extension Domain.Models.Persistence {
    enum CollectionError: LocalizedError, Sendable {
        case emptyValue(String, parameter: String)
        case minimumLengthNotReached(Int)
        case maximumLengthReached(Int)
        case badName(String)
        case invalidColor(String, reason: String)
        case notFound(Int64?)
        
        public var errorDescription: String? {
            switch self {
            case .emptyValue(let value, let parameter):
                return "An empty value '\(value)' was passed into parameter '\(parameter)'."
                
            case .minimumLengthNotReached(let length):
                return "The collection name must be at least \(Collection.minimumNameLength) characters long but got \(length)."
                
            case .maximumLengthReached(let length):
                return "The collection name cannot exceed \(Collection.maximumNameLength) characters but got \(length)."
                
            case .badName(let name):
                return "The collection name '\(name)' is reserved and cannot be used."
                
            case .invalidColor(let color, let reason):
                return "The collection color '\(color)' is invalid: \(reason)"
            case .notFound(let id):
                return "Collection with id \(String(describing: id)) not found."
            }
        }
    }
}

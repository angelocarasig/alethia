//
//  HostError.swift
//  Domain
//
//  Created by Angelo Carasig on 14/6/2025.
//

import Foundation

typealias HostError = Domain.Models.Persistence.HostError

public extension Domain.Models.Persistence {
    enum HostError: LocalizedError {
        case emptyValue(String, parameter: String)
        case invalidName(String)
        case invalidAuthor(String)
        case invalidRepository(URL, reason: String)
        case invalidURL(URL, reason: String)
        
        public var errorDescription: String? {
            switch self {
            case .emptyValue(let value, let parameter):
                return "An empty value '\(value)' was passed into parameter '\(parameter)'."
            case .invalidName(let name):
                return "The host name '\(name)' contains invalid characters."
            case .invalidAuthor(let author):
                return "The host author '\(author)' contains invalid characters."
            case .invalidRepository(let repository, let reason):
                return "The host repository '\(repository)' is invalid: \(reason)"
            case .invalidURL(let url, let reason):
                return "The host url '\(url)' is invalid: \(reason)"
            }
        }
    }
}

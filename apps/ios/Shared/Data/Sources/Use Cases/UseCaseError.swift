//
//  UseCaseError.swift
//  Data
//
//  Created by Angelo Carasig on 4/10/2025.
//

import Foundation

enum UseCaseError: LocalizedError {
    case invalidURLScheme
    case noSourcesInManifest
    case invalidManifest(reason: String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURLScheme:
            return "URL must start with either http:// or https://"
        case .noSourcesInManifest:
            return "Manifest must contain at least one source."
        case .invalidManifest(let reason):
            return "Invalid: \(reason)"
        }
    }
}

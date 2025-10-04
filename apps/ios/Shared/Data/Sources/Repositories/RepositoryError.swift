//
//  RepositoryError.swift
//  Data
//
//  Created by Angelo Carasig on 4/10/2025.
//

import Foundation

enum RepositoryError: LocalizedError {
    case invalidManifest(reason: String)
    case mappingError(reason: String)
    case hostAlreadyExists(id: HostRecord.ID, url: URL)
    
    var errorDescription: String? {
        switch self {
        case .invalidManifest(let reason):
            return "Invalid manifest: \(reason)"
        case .mappingError(let reason):
            return "Mapping error: \(reason)"
        case .hostAlreadyExists(_, let url):
            return "Host with url '\(url.absoluteString)' already exists."
        }
    }
}

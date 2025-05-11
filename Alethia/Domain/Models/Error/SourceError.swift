//
//  SourceError.swift
//  Alethia
//
//  Created by Angelo Carasig on 12/4/2025.
//

import Foundation

enum SourceError: LocalizedError {
    case notFound
    case routeNotFound(id: Int64)
    
    var errorDescription: String? {
        switch self {
        case .notFound:
            return "Source could not be found."
        case .routeNotFound(let id):
            return "Source Route ID \(id) could not be found."
        }
    }
}

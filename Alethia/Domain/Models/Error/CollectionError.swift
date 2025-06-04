//
//  CollectionError.swift
//  Alethia
//
//  Created by Angelo Carasig on 4/6/2025.
//

import Foundation

enum CollectionError: LocalizedError {
    case notFound(Int64?)
    case badName(String?)
    
    // need this
    var errorDescription: String? {
        return localizedDescription
    }
    
    var localizedDescription: String {
        switch self {
        case .notFound(let id):
            if let id = id {
                return "The collection with ID \(id) could not be found in your library. It may have been deleted or moved."
            } else {
                return "The requested collection could not be found in your library."
            }
        case .badName(let name):
            if let name = name {
                return "The collection name '\(name)' is reserved and cannot be used."
            }
            else {
                return "The collection name provided is invalid."
            }
        }
    }
}
